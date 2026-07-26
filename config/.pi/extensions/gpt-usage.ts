import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { createInterface } from "node:readline";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

interface RateLimitWindow {
	usedPercent: number;
	windowDurationMins: number;
	resetsAt: number;
}

interface RateLimitSnapshot {
	limitId: string;
	limitName: string | null;
	primary: RateLimitWindow | null;
	secondary: RateLimitWindow | null;
	credits: {
		hasCredits: boolean;
		unlimited: boolean;
		balance: string | null;
	} | null;
	planType: string | null;
}

interface RateLimitsResponse {
	rateLimits: RateLimitSnapshot | null;
	rateLimitsByLimitId: Record<string, RateLimitSnapshot>;
}

const REFRESH_INTERVAL_MS = 5 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 10_000;

function windowName(minutes: number): string {
	if (minutes % 10_080 === 0) return `${minutes / 10_080}w`;
	if (minutes % 1_440 === 0) return `${minutes / 1_440}d`;
	if (minutes % 60 === 0) return `${minutes / 60}h`;
	return `${minutes}m`;
}

function formatReset(timestamp: number): string {
	return new Date(timestamp * 1000).toLocaleString([], {
		month: "short",
		day: "numeric",
		hour: "numeric",
		minute: "2-digit",
	});
}

function windows(snapshot: RateLimitSnapshot): RateLimitWindow[] {
	return [snapshot.primary, snapshot.secondary].filter(
		(window): window is RateLimitWindow => window !== null,
	);
}

function formatStatus(snapshot: RateLimitSnapshot, ctx: ExtensionContext): string {
	const theme = ctx.ui.theme;
	const plan = snapshot.planType
		? ` ${snapshot.planType[0]?.toUpperCase()}${snapshot.planType.slice(1)}`
		: "";
	const parts = windows(snapshot).map((window) => {
		const text = `${windowName(window.windowDurationMins)} ${Math.round(window.usedPercent)}%`;
		const color = window.usedPercent >= 90 ? "error" : window.usedPercent >= 75 ? "warning" : "dim";
		return theme.fg(color, text);
	});
	return `${theme.fg("accent", `GPT${plan}`)} ${parts.join(theme.fg("dim", " · "))}`;
}

function formatTokens(count: number): string {
	if (count < 1_000) return `${count}`;
	if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
	if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
	if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
	return `${Math.round(count / 1_000_000)}M`;
}

function formatDetails(response: RateLimitsResponse): string {
	const snapshots = Object.values(response.rateLimitsByLimitId);
	if (snapshots.length === 0 && response.rateLimits) snapshots.push(response.rateLimits);
	if (snapshots.length === 0) return "No GPT subscription limits were returned.";

	return snapshots
		.map((snapshot) => {
			const label = snapshot.limitName ?? snapshot.limitId;
			const plan = snapshot.planType ? ` (${snapshot.planType})` : "";
			const limits = windows(snapshot).map(
				(window) =>
					`${windowName(window.windowDurationMins)}: ${Math.round(window.usedPercent)}% used, resets ${formatReset(window.resetsAt)}`,
			);
			return `${label}${plan}: ${limits.join("; ")}`;
		})
		.join("\n");
}

function readRateLimits(onProcess: (process: ChildProcessWithoutNullStreams | undefined) => void): Promise<RateLimitsResponse> {
	return new Promise((resolve, reject) => {
		const child = spawn("codex", ["app-server", "--stdio"], { stdio: "pipe" });
		onProcess(child);
		const lines = createInterface({ input: child.stdout });
		let settled = false;
		let stderr = "";

		const finish = (error?: Error, result?: RateLimitsResponse) => {
			if (settled) return;
			settled = true;
			clearTimeout(timeout);
			lines.close();
			child.kill();
			onProcess(undefined);
			if (error) reject(error);
			else resolve(result!);
		};

		const send = (message: unknown) => {
			child.stdin.write(`${JSON.stringify(message)}\n`);
		};

		const timeout = setTimeout(
			() => finish(new Error(`Codex usage request timed out after ${REQUEST_TIMEOUT_MS / 1000}s`)),
			REQUEST_TIMEOUT_MS,
		);

		child.stderr.on("data", (chunk: Buffer) => {
			if (stderr.length < 2_000) stderr += chunk.toString();
		});
		child.on("error", (error) => finish(error));
		child.on("exit", (code) => {
			if (!settled) finish(new Error(stderr.trim() || `Codex app server exited with code ${code}`));
		});
		lines.on("line", (line) => {
			try {
				const message = JSON.parse(line) as {
					id?: number;
					result?: RateLimitsResponse;
					error?: { message?: string };
				};
				if (message.id === 1) {
					if (message.error) {
						finish(new Error(message.error.message ?? "Codex app server initialization failed"));
						return;
					}
					send({ method: "initialized", params: {} });
					send({ method: "account/rateLimits/read", id: 2, params: {} });
				} else if (message.id === 2) {
					if (message.error || !message.result) {
						finish(new Error(message.error?.message ?? "Codex returned no usage data"));
						return;
					}
					finish(undefined, message.result);
				}
			} catch {
				// App-server notifications and non-JSON diagnostics are unrelated to this request.
			}
		});

		send({
			method: "initialize",
			id: 1,
			params: {
				clientInfo: { name: "pi-gpt-usage", title: "Pi GPT Usage", version: "1.0.0" },
				capabilities: {},
			},
		});
	});
}

export default function (pi: ExtensionAPI) {
	let activeProcess: ChildProcessWithoutNullStreams | undefined;
	let currentContext: ExtensionContext | undefined;
	let latest: RateLimitsResponse | undefined;
	let refreshPromise: Promise<RateLimitsResponse> | undefined;
	let interval: ReturnType<typeof setInterval> | undefined;
	let requestFooterRender: (() => void) | undefined;
	let stopped = false;

	const installFooter = (ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setFooter((tui, theme, footerData) => {
			requestFooterRender = () => tui.requestRender();
			const unsubscribe = footerData.onBranchChange(requestFooterRender);

			return {
				dispose: unsubscribe,
				invalidate() {},
				render(width: number): string[] {
					let totalInput = 0;
					let totalOutput = 0;
					let totalCacheRead = 0;
					let totalCacheWrite = 0;
					let totalCost = 0;
					let latestCacheHitRate: number | undefined;

					for (const entry of ctx.sessionManager.getEntries()) {
						if (entry.type !== "message" || entry.message.role !== "assistant") continue;
						const message = entry.message as AssistantMessage;
						totalInput += message.usage.input;
						totalOutput += message.usage.output;
						totalCacheRead += message.usage.cacheRead;
						totalCacheWrite += message.usage.cacheWrite;
						totalCost += message.usage.cost.total;
						const promptTokens = message.usage.input + message.usage.cacheRead + message.usage.cacheWrite;
						latestCacheHitRate = promptTokens > 0 ? (message.usage.cacheRead / promptTokens) * 100 : undefined;
					}

					const parts: string[] = [];
					if (totalInput) parts.push(theme.fg("dim", `↑${formatTokens(totalInput)}`));
					if (totalOutput) parts.push(theme.fg("dim", `↓${formatTokens(totalOutput)}`));
					if (totalCacheRead) parts.push(theme.fg("dim", `R${formatTokens(totalCacheRead)}`));
					if (totalCacheWrite) parts.push(theme.fg("dim", `W${formatTokens(totalCacheWrite)}`));
					if ((totalCacheRead || totalCacheWrite) && latestCacheHitRate !== undefined) {
						parts.push(theme.fg("dim", `CH${latestCacheHitRate.toFixed(1)}%`));
					}

					const usingSubscription = ctx.model ? ctx.modelRegistry.isUsingOAuth(ctx.model) : false;
					if (totalCost || usingSubscription) {
						parts.push(theme.fg("dim", `$${totalCost.toFixed(3)}${usingSubscription ? " (sub)" : ""}`));
					}

					const contextUsage = ctx.getContextUsage();
					const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
					const contextText = contextUsage?.percent === null
						? `?/${formatTokens(contextWindow)} (auto)`
						: `${(contextUsage?.percent ?? 0).toFixed(1)}%/${formatTokens(contextWindow)} (auto)`;
					const contextColor = (contextUsage?.percent ?? 0) > 90
						? "error"
						: (contextUsage?.percent ?? 0) > 70
							? "warning"
							: "dim";
					parts.push(theme.fg(contextColor, contextText));

					const snapshot = latest?.rateLimits ?? Object.values(latest?.rateLimitsByLimitId ?? {})[0];
					if (snapshot) parts.push(formatStatus(snapshot, ctx));

					let left = parts.join(" ");
					if (visibleWidth(left) > width) left = truncateToWidth(left, width, "...");

					const providerCount = new Set(ctx.modelRegistry.getAvailable().map((model) => model.provider)).size;
					const model = ctx.model?.id ?? "no-model";
					const thinking = ctx.model?.reasoning ? ` • ${pi.getThinkingLevel()}` : "";
					let right = `${model}${thinking}`;
					if (providerCount > 1 && ctx.model) {
						const withProvider = `(${ctx.model.provider}) ${right}`;
						if (visibleWidth(left) + 2 + visibleWidth(withProvider) <= width) right = withProvider;
					}

					const available = width - visibleWidth(left) - 2;
					if (available <= 0) right = "";
					else right = truncateToWidth(right, available, "");
					const padding = " ".repeat(Math.max(0, width - visibleWidth(left) - visibleWidth(right)));
					const statsLine = left + theme.fg("dim", padding + right);

					let cwd = ctx.cwd;
					const home = process.env.HOME;
					if (home && (cwd === home || cwd.startsWith(`${home}/`))) cwd = `~${cwd.slice(home.length)}`;
					const branch = footerData.getGitBranch();
					if (branch) cwd += ` (${branch})`;
					const sessionName = ctx.sessionManager.getSessionName();
					if (sessionName) cwd += ` • ${sessionName}`;

					const lines = [
						truncateToWidth(theme.fg("dim", cwd), width, theme.fg("dim", "...")),
						statsLine,
					];
					const statuses = Array.from(footerData.getExtensionStatuses().values());
					if (statuses.length > 0) lines.push(truncateToWidth(statuses.join(" "), width));
					return lines;
				},
			};
		});
	};

	const refresh = async (ctx: ExtensionContext): Promise<RateLimitsResponse> => {
		if (refreshPromise) return refreshPromise;
		refreshPromise = readRateLimits((process) => {
			activeProcess = process;
		});
		try {
			const response = await refreshPromise;
			latest = response;
			if (!stopped) requestFooterRender?.();
			return response;
		} finally {
			refreshPromise = undefined;
		}
	};

	pi.on("session_start", async (_event, ctx) => {
		stopped = false;
		currentContext = ctx;
		installFooter(ctx);
		void refresh(ctx).catch(() => {});
		interval = setInterval(() => {
			if (currentContext) void refresh(currentContext).catch(() => {});
		}, REFRESH_INTERVAL_MS);
	});

	pi.on("agent_settled", async (_event, ctx) => {
		void refresh(ctx).catch(() => {});
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		stopped = true;
		currentContext = undefined;
		if (interval) clearInterval(interval);
		interval = undefined;
		activeProcess?.kill();
		activeProcess = undefined;
		requestFooterRender = undefined;
		if (ctx.mode === "tui") ctx.ui.setFooter(undefined);
	});

	pi.registerCommand("gpt-usage", {
		description: "Refresh and show ChatGPT subscription usage",
		handler: async (_args, ctx) => {
			try {
				const response = await refresh(ctx);
				ctx.ui.notify(formatDetails(response), "info");
			} catch (error) {
				const fallback = latest ? `\nLast result:\n${formatDetails(latest)}` : "";
				ctx.ui.notify(`Could not read GPT usage: ${error instanceof Error ? error.message : String(error)}${fallback}`, "error");
			}
		},
	});
}

import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function findClaudeSkills(startDirectory: string): string | undefined {
	let directory = startDirectory;

	while (true) {
		const skills = join(directory, ".claude", "skills");
		if (existsSync(skills)) return skills;
		if (existsSync(join(directory, ".git"))) return undefined;

		const parent = dirname(directory);
		if (parent === directory) return undefined;
		directory = parent;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("resources_discover", (event) => {
		const skills = findClaudeSkills(event.cwd);
		return skills ? { skillPaths: [skills] } : undefined;
	});
}

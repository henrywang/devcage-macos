# Agent workflow

One always-open inbox. You type a request, Pi routes it, and anything that needs
real work gets its own herdr workspace with its own panes.

The workflow uses the released [`herdr-workflow`](https://github.com/henrywang/herdr-workflow)
package rather than a locally maintained Bash script:

- `wq` is installed with `uv tool install herdr-workflow`
- `config/wq/config.toml` → `~/.config/wq/config.toml` holds local configuration
- `config/.pi/prompts/go.md` → `~/.pi/agent/prompts/go.md` is the router prompt

The rest of the tracked Pi setup is shared by every pane:

- `config/.pi/extensions/gpt-usage.ts` — ChatGPT usage in the Pi footer
- `config/.pi/extensions/claude-project-skills.ts` — exposes repo Claude skills to Pi
- `config/.pi/skills/browser/` — Playwright CLI browser automation

`setup.sh` installs and links everything. `~/.pi/agent/settings.json` is deliberately
left alone because Pi rewrites it on upgrade.

## Layout

```
herdr session: main
├── workspace "inbox"        ← always open
│   ├── tab "router" → Pi router <- you type here
│   ├── tab "chat"   → reusable conversation
│   └── tab "ask-*"  → disposable repo questions
├── workspace "bs-<slug>"    ← interactive brainstorm
├── workspace "plan-<slug>"  ← plan ↔ review loop
└── workspace "<slug>"       ← worktree, code ↔ review loop
```

## Starting

Open Ghostty and run:

```bash
work
```

The `work` function in `config/zsh/.zshrc` starts herdr if necessary, runs the
idempotent `wq up`, and attaches. Then send requests from the router:

```
/go what's the weather today?
/go add dark mode to Berthly
/go why is login returning 500?
```

The router only classifies and dispatches. It does not answer directly, so its
context stays small. `chat` reuses a conversation; each `ask` gets a disposable
tab; autonomous work gets dedicated panes.

Herdr integrations are required so agent sessions survive server restarts:

```bash
herdr integration install pi
herdr integration install claude
```

`setup.sh` runs both commands when herdr is available.

## Commands

```bash
wq up                             # ensure inbox + router (idempotent)
wq chat       "<message>"         # reuse the inbox chat tab
wq ask        "<question>"        # fresh tab, scoped to the current directory
wq tidy                           # close completed ask tabs
wq brainstorm <slug> "<idea>"     # interactive pane and Obsidian note
wq plan       <slug> "<request>"  # bounded plan ↔ review loop
wq build      <slug> [repo]       # worktree and bounded code ↔ review loop
wq revise     <slug> "<comment>"  # one additional code + review round
wq ship       <slug>              # run wq go in an inbox shell tab
wq go         <slug>              # push, PR, CI, merge, and cleanup
wq list                           # active workspaces
wq clean      <slug>              # remove a workspace and scratch directory
wq doctor                         # check dependencies and configuration
```

The normal path is:

```
plan → inspect plan.md → build → inspect diff.patch → revise as needed → ship
```

A different model reviews the writer. Both automatic loops are capped at three
rounds. Content moves between panes by file path rather than being pasted into
prompts. `build` stops before anything is pushed; `ship` performs the irreversible
work in a plain shell tab, never in an agent pane.

Scratch artifacts live under `~/Workspace/.wq/<slug>`. Brainstorm notes go to the
Obsidian vault configured in `config/wq/config.toml`.

## Configuration

Configuration is loaded in this order, with later layers winning:

1. built-in defaults
2. `~/.config/wq/config.toml`
3. a project's `.wq.toml`
4. `WQ_*` environment variables

The tracked config contains only this machine's Obsidian note sink. Agent roles,
round limits, scratch paths, and herdr settings can also be configured in TOML:

```toml
[agents]
plan = "claude:opus:high"
code = "claude:sonnet:high"
review = "pi:openai-codex/gpt-5.6-sol:high"

[loops]
plan_rounds = 3
code_rounds = 3

[paths]
root = "~/Workspace/.wq"
notes = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian"

[herdr]
socket = "auto"
```

One-off environment overrides still work, for example:

```bash
WQ_AGENT_CODE=claude:opus:high wq build <slug> <repo>
```

Run `wq doctor` after installation or when the workflow cannot start. See the
[upstream README](https://github.com/henrywang/herdr-workflow#readme) and
[`docs/behaviors.md`](https://github.com/henrywang/herdr-workflow/blob/main/docs/behaviors.md)
for architecture, failure modes, and implementation details.

# Agent workflow

One always-open inbox. You type a request, Pi routes it, and anything that needs
real work gets its own herdr workspace with its own panes.

Two files do the whole thing:

- `config/herdr/wq` → `~/bin/wq` — all herdr orchestration, in bash
- `config/.pi/prompts/go.md` → `~/.pi/agent/prompts/go.md` — the router prompt

The rest of the Pi setup is tracked alongside them, not required by the routing
itself but shared by every pane it spawns:

- `config/.pi/extensions/gpt-usage.ts` — ChatGPT subscription usage and token
  totals in the Pi footer, refreshed every 5 minutes via `codex app-server`
- `config/.pi/extensions/claude-project-skills.ts` — makes a repo's
  `.claude/skills` visible to Pi, so skills written for Claude Code work unchanged
- `config/.pi/skills/browser/` — Playwright CLI browser automation

All of them are symlinked out of this repo by `setup.sh`. `~/.pi/agent/settings.json`
is deliberately left alone — Pi rewrites it on upgrade, so tracking it would produce
spurious diffs.

## Layout

```
herdr session: main
├── workspace "inbox"        ← always open, never closed
│   ├── tab "router" → pi router (gpt-5.6-sol, medium)  ← you type here
│   ├── tab "chat"   → one long-lived conversation
│   └── tab "ask-*"  → one per repo question, disposable
├── workspace "bs-<slug>"    ← brainstorm, interactive
├── workspace "plan-<slug>"  ← plan ↔ review loop
└── workspace "<slug>"       ← build: worktree, code ↔ review loop
```

## Starting

Open Ghostty and run:

```bash
work
```

That is the whole thing. The `work` function in `.zshrc` ensures the herdr server
is up, ensures the `inbox` workspace has a `router` tab with Pi running in it,
and attaches. Every step checks before it acts, so on a warm machine it just
reattaches to what was already there.

Then talk to the router: `/go what's the weather today?`,
`/go add dark mode to Berthly`, `/go why is login returning 500?`

**You almost never pay the setup cost.** Herdr sessions persist to
`~/.config/herdr/session.json`, and with the Pi and Claude integrations installed
(`herdr integration install pi`, `... claude`) `resume_agents_on_restore` brings
agent panes back into their own conversation sessions. Verified: stopping the
server outright and starting it again left the inbox workspace, the router tab,
and the running Pi agent intact — `wq up` reported "router already running".

`wq up` on its own is the same bootstrap without attaching, safe to run any time.
You need it only on a genuinely cold machine, or after closing the inbox by hand.

Pi's defaults in `~/.pi/agent/settings.json` are already `openai-codex/gpt-5.6-sol`
at `medium` thinking, which is what the router wants. Nothing to configure.

### Integrations

The herdr agent integrations are not optional for this setup:

```bash
herdr integration install pi
herdr integration install claude
```

Without them herdr infers agent state by watching terminal output, which is what
`wq`'s prompt-and-wait depends on. With them, Pi and Claude report their own
state, and panes resume across server restarts. The Claude one adds a
`SessionStart` hook to `~/.claude/settings.json` — that file is symlinked out of
this repo, so the hook is tracked here. It runs for every Claude Code session on
this machine, not only for `wq` panes. `herdr integration uninstall claude`
reverses it.

## The five classes

| Class | Mode | What happens |
| --- | --- | --- |
| `chat` | tab, instant | Reuses the inbox `chat` tab |
| `ask` | tab, instant | New inbox tab scoped to a directory, disposable |
| `brainstorm` | **interactive** | One Claude opus pane → Obsidian note |
| `plan` | autonomous | plan ↔ review loop → `plan.md` |
| `build` | autonomous | worktree → code ↔ review loop → commit |

**The router never answers anything.** It classifies and dispatches, and that is
the whole point: its context stays flat no matter how many questions you ask.
Answering inline looks cheaper per request but is not — the answer, and every
file read behind it, stays in the router's context and is re-sent with every
later routing decision. A tab pays a fixed cold start once and then throws the
context away.

`chat` reuses one long-lived tab, because follow-ups only make sense with the
previous turn still in context. `ask` gets a fresh tab per question, because the
file reads behind an answer are exactly what you want to discard. `wq tidy`
closes the finished `ask-*` tabs and leaves `chat` alone.

Interactive vs autonomous is the other split. `chat`, `ask`, and `brainstorm`
return immediately and focus the tab — you read the answer as it arrives.
`plan` and `build` block for minutes, then notify.

## Commands

```bash
wq up                             # ensure inbox + router (idempotent)
wq chat       "<message>"         # reuse the inbox chat tab
wq ask        "<question>"        # new inbox tab, scoped to $PWD
wq tidy                           # close finished ask tabs
wq brainstorm <slug> "<idea>"     # interactive pane, note in Obsidian
wq plan       <slug> "<request>"  # → ~/Workspace/.wq/<slug>/plan.md
wq build      <slug> [repo]       # → worktree + committed diff
wq go         <slug>              # push, PR, wait for CI, merge, clean up
wq list                           # what is running
wq clean      <slug>              # drop the workspace and scratch dir
```

`wq ask` scopes the tab to the current directory. Override with
`WQ_ASK_CWD=~/Workspace/Berthly wq ask "where is auth handled?"`.

Both need a workspace labelled `inbox` to exist, or they exit with instructions
to create one.

### brainstorm

Creates one Claude opus pane and focuses it. You stay and talk. The note lands at:

```
~/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian/inbox/YYYY-MM-DD-<slug>.md
```

with `tags: [brainstorm]` frontmatter so it joins the graph instead of sitting as
an orphan. No reviewer pane — a critic during ideation kills the divergence you
came for. Sharpen it afterwards with `wq plan` if it turns into something.

If Obsidian has the note open while the agent writes, iCloud can produce a sync
conflict. Close the note, or let the agent finish before you open it.

### plan

Two panes: `plan` and `review`, each configurable — see Roles. By default the
planner is Claude opus and the reviewer is Pi `gpt-5.6-sol` at high thinking.

1. Planner writes `plan.md`
2. Reviewer reads `plan.md`, writes `review.md`, ends with a verdict line
3. If `VERDICT: CHANGES`, planner revises — up to 3 rounds
4. Notification; you review `plan.md`

A different model reviews than writes. A second pass of the same model agrees
with itself far too readily.

### build

```
worktree wq/<slug> off origin/main
  → code pane (Claude sonnet) implements plan.md, runs tests, commits
  → review pane reviews `git diff origin/main...HEAD`, up to 3 rounds
  → stops. You review the diff.
```

Then `wq go <slug>` pushes, opens the PR, watches CI, squash-merges, refreshes
local `main` (`git fetch origin main && git rebase origin/main`), and deletes the
branch and worktree.

The gate between `build` and `go` is deliberate: `build` is bounded and
reversible, `go` pushes and merges. If you want it unattended, run `wq go`
straight after `wq build` — but look at the diff first.

If the reviewer still has blocking findings after 3 rounds, `build` exits 2 and
stops. It does not hand a disputed diff to `go`.

## Why it is shaped this way

**State lives where it already is.** Git is the state for `build`. Files on disk
are the state for `plan` and `brainstorm`. `herdr api snapshot` is the state for
what is running. There is no index to reconcile, so there is nothing to drift.

**Bash orchestrates, models do the work.** Every `workspace create` / `pane split`
/ `agent start` decision made by model reasoning costs tokens and fails
differently each time. In `wq` those are fixed lines of shell.

**Paths between panes, never content.** The reviewer gets `plan.md` or
`diff.patch` as a path. Pasting a plan or a diff from one pane into another
prompt is the largest avoidable cost in a review loop.

**Convergence is a grep.** Reviewers end their file with `VERDICT: APPROVED` or
`VERDICT: CHANGES`. "Until the reviewer has no more updates" is unbounded — two
agents will nitpick each other indefinitely. Three rounds, then it stops.

**CI waiting is pure shell.** `gh pr checks --watch` blocks for free. An agent
polling `gh pr checks` is the most expensive possible way to wait.

## Tuning

Environment variables, all optional:

| Variable | Default |
| --- | --- |
| `WQ_ROOT` | `~/Workspace/.wq` |
| `WQ_VAULT` | the iCloud Obsidian vault |
| `WQ_INBOX_LABEL` | `inbox` |
| `WQ_ASK_CWD` | `$PWD` |
| `WQ_PLAN_ROUNDS` | `3` |
| `WQ_CODE_ROUNDS` | `3` |
| `WQ_TURN_TIMEOUT_MS` | `1800000` (30 min per agent turn) |

## Roles

Each role is a `kind:model:level` spec, so either side of a loop can be either
agent. `claude` takes `--model` and `--effort`; `pi` takes `--model` and
`--thinking`.

| Variable | Default |
| --- | --- |
| `WQ_AGENT_PLAN` | `claude:opus:high` |
| `WQ_AGENT_CODE` | `claude:sonnet:high` |
| `WQ_AGENT_REVIEW` | `pi:openai-codex/gpt-5.6-sol:high` |
| `WQ_AGENT_IDEA` | `claude:opus:high` |
| `WQ_AGENT_ASK` | `pi:openai-codex/gpt-5.6-sol:medium` |
| `WQ_AGENT_ROUTER` | `pi:openai-codex/gpt-5.6-sol:medium` |

`WQ_AGENT_ROUTER` is the odd one out: it is not half of a loop, it is the agent
`wq up` starts in the inbox `router` tab. It only classifies and dispatches, so
`medium` thinking is enough — the same model the reviewer runs at `high`.

The rule that matters is that **the reviewer is not the model that wrote**. Which
way round you assign them is a free choice. To have opus review a plan written by
GPT:

```bash
WQ_AGENT_PLAN=pi:openai-codex/gpt-5.6-sol:high \
WQ_AGENT_REVIEW=claude:opus:high \
  wq plan <slug> "<request>"
```

Opus for a gnarly implementation: `WQ_AGENT_CODE=claude:opus:high wq build <slug>`.

Two things to weigh before flipping `plan` or `build`:

- The writer explores the repo and edits files. Claude Code is built for that,
  and Pi's tooling is lighter. The reviewer mostly reads a plan or a diff, so it
  is the easier seat to move.
- A Claude reviewer is a second pane running with permissions bypassed. A Pi
  reviewer needs no such flag, so the current default keeps exactly one
  unattended-permission pane per loop instead of two.

`brainstorm` has no reviewer, so `WQ_AGENT_IDEA` is a plain single-agent choice.

## Permissions

Autonomous panes cannot stop to ask. Claude Code prompts for permission on its
first tool use, which parks the pane in `blocked` and stalls the loop, so `wq`
starts Claude panes with `--permission-mode auto`:

```bash
WQ_CLAUDE_PERMISSION_MODE=acceptEdits wq plan ...   # stricter, will stall on bash
```

Those panes are unattended agents acting without confirmation. What keeps that
reasonable is where they run: `plan` works in `~/Workspace/.wq/<slug>`, and
`build` works in a throwaway worktree on its own branch. Neither touches your
main checkout, and `wq go` — the only step that pushes or merges — is never run
by an agent. Point them somewhere that matters and that reasoning stops holding.

Pi does not gate tools this way, so reviewer panes need no equivalent flag.

If an agent does block, `wq` prints the last 25 lines of the pane and exits
rather than reporting a confusingly empty output file. Attach with
`herdr agent attach <pane>` to see what it is asking.

## Starting the server cleanly

`wq` needs a running herdr server. Start it the normal way — `herdr` in a fresh
terminal.

Do not start it from inside a Claude Code session. Panes inherit the server's
environment, so an inherited `CLAUDECODE=1` brings nested Claude panes up in
manual mode with prompts disabled, and every `wq` turn stalls. If that happens,
`herdr server stop` and restart from a clean shell.

## herdr notes

Behaviour confirmed against herdr 0.7.5, worth knowing if you extend `wq`:

- Every CLI call emits JSON on stdout. `--json` exists only on `worktree`
  subcommands; elsewhere it is rejected as an unknown option.
- `workspace create` returns the root pane too, so a simple workspace needs no
  `tab create`.
- **Agent turns settle on `done`, not `idle`.** `--until idle` times out even
  though the reply landed. `wq` waits on `done` and `blocked`.
- Target agents by `pane_id`, not by name. Names are not unique across concurrent
  workspaces; pane IDs are.
- Valid `agent read --source` values: `visible`, `recent`, `recent_unwrapped`,
  `detection`. Not `screen`.
- Agent status enum: `idle`, `working`, `blocked`, `done`, `unknown`.

Terminal state is a heuristic, so `wq` confirms every turn that should produce
output by checking the file's mtime actually changed. If an agent stalls, you get
a clear error instead of a silently empty plan.

Watch for `set -o pipefail` with `grep -q` if you extend this: `grep -q` exits on
first match, herdr takes SIGPIPE, and the pipeline reports failure for a command
that succeeded. `wq` captures output and matches with `case` instead.

## Status

Run end to end against herdr 0.7.5: `wq up` (both cold and warm, idempotent),
`wq chat` (including tab reuse across turns), `wq ask` (fresh tab, correct answer
from a real file read), and `wq tidy` (closes `ask-*`, leaves `chat`). Session
persistence confirmed across a full server stop and restart.

Verified individually: workspace/tab/pane/agent creation, tab rename,
prompt-and-wait, pane reads, workspace and tab close, and every JSON shape `wq`
parses.

Not yet run end to end: the `plan` review loop, `build`, and `go`. Give `plan` a
small throwaway request first and watch the panes before trusting it with
anything real — and read a `build` diff carefully the first few times, since
`go` is the step that pushes and merges.

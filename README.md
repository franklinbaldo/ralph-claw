# ralph-claw

> *"I'm not gonna be ignored."* — Ralph Wiggum

**ralph-claw** is the simplest possible persistent AI agent: a Docker container running your AI CLI of choice in a loop. No proprietary platform. No subscriptions. No magic.

Named after [Ralph Wiggum](https://ghuntley.com/ralph/) — the AI development methodology that keeps trying until it works — and [OpenClaw](https://openclaw.io) — the platform it replaces.

---

## The Idea

Modern AI CLIs (Claude Code, Gemini CLI, Codex, Qwen, Kilo Code) are already powerful agents. The only thing missing is:

1. **Persistence** — they forget everything between sessions
2. **A loop** — someone to restart them when they're done with a task
3. **A harness** — somewhere to keep the memory they accumulate

ralph-claw provides exactly those three things. Nothing more.

```
while true; do
  claude --dangerously-skip-permissions -p "$(cat tasks.md | head -1)"
  git add -A && git commit -m "chore: checkpoint"
done
```

That's it. The rest is just ergonomics.

---

## Why Not OpenClaw / [other platform]?

| | ralph-claw | OpenClaw / Platform |
|---|---|---|
| Setup | `docker compose up` | Account, config, API keys, webhooks... |
| Cost | Free tier friendly | Subscription |
| Portability | Any Docker host | Platform-specific |
| Agent | Claude Code, Gemini CLI, anything | Platform agent |
| Memory | Git + markdown files | Platform database |
| Vendor lock-in | None | High |
| Debuggability | `docker logs`, git history | Platform dashboard |

---

## Quickstart

### Prerequisites
- Docker + Docker Compose
- API key for your AI CLI of choice

### 1. Clone and configure

```bash
git clone https://github.com/franklinbaldo/ralph-claw
cd ralph-claw
cp .env.example .env
# Edit .env with your API key
```

### 2. Write your tasks

Edit `tasks.md`:

```markdown
- [ ] Build a CLI tool that converts CSV to JSON
- [ ] Add tests
- [ ] Write README
```

### 3. Run

```bash
docker compose up
```

Ralph wakes up, reads the task list, works on the first unchecked task, commits, and goes back to sleep. On the next loop it picks up where it left off.

---

## How It Works

```
┌─────────────────────────────────────┐
│           Docker Container           │
│                                     │
│  ┌─────────┐    ┌─────────────────┐ │
│  │ loop.sh │───▶│  AI CLI (agent) │ │
│  └────┬────┘    └────────┬────────┘ │
│       │                  │          │
│       │◀─────────────────┘          │
│       │   commit + restart          │
│                                     │
│  ┌────▼────────────────────────┐    │
│  │    /workspace (volume)      │    │
│  │  tasks.md  AGENT.md  *.md   │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

1. **`loop.sh`** — outer shell loop. Starts the AI, waits for it to exit, commits work, repeats.
2. **AI CLI** — reads `AGENT.md` (instructions) + `tasks.md` (what to do), does one task, exits.
3. **`/workspace` volume** — mounted from host. Git repo. Memory persists here.
4. **`AGENT.md`** — your standing orders to the agent. Updated by the agent as it learns.
5. **`tasks.md`** — the task list. Checked items = done. Agent marks them off.

---

## File Structure

```
ralph-claw/
├── docker-compose.yml     # The harness
├── loop.sh                # The Ralph Wiggum loop
├── AGENT.md               # Standing orders for the agent
├── tasks.md               # What to build (edit this)
├── .env.example           # Environment variables template
└── examples/
    ├── claude-code/       # Claude Code setup
    └── gemini-cli/        # Gemini CLI setup
```

---

## Providers

ralph-claw works with any AI CLI that can read files and run in a terminal:

| Provider | CLI | Free Tier |
|---|---|---|
| Anthropic | `claude` (Claude Code) | Yes (limited) |
| Google | `gemini` (Gemini CLI) | Yes (generous) |
| OpenAI | `codex` | Yes (limited) |
| Alibaba | `qwen` | Yes |

See `examples/` for provider-specific configs.

---

## Agent Teams Mode (Experimental)

ralph-claw now supports [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams) for parallel task execution. Instead of working through tasks one-by-one, a team lead spawns multiple teammates that work on independent tasks simultaneously.

### When to use teams

- You have many independent tasks that don't touch the same files
- Research across multiple areas simultaneously
- Cross-cutting changes (frontend + backend + tests)
- Debugging with competing hypotheses

### Quick start with teams

**Option A — Use the team profile:**

```bash
docker compose --profile team up ralph-team
```

**Option B — Switch the default service to team mode:**

Set `AGENT_MODE=team` in your `.env`:

```bash
AGENT_MODE=team
TEAM_SIZE=3
```

Then run as usual:

```bash
docker compose up
```

### How it works

```
┌─────────────────────────────────────────────┐
│           Docker Container                   │
│                                             │
│  ┌─────────┐    ┌──────────────────────┐    │
│  │ loop.sh │───▶│  Claude (Team Lead)  │    │
│  └────┬────┘    └──────────┬───────────┘    │
│       │                    │                │
│       │         ┌──────────┼──────────┐     │
│       │         ▼          ▼          ▼     │
│       │    Teammate 1  Teammate 2  Teammate 3│
│       │    (task A)    (task B)    (task C)  │
│       │         │          │          │     │
│       │         └──────────┼──────────┘     │
│       │◀───────────────────┘                │
│       │   commit + restart                  │
│                                             │
│  ┌────▼────────────────────────────────┐    │
│  │    /workspace (volume)              │    │
│  │  tasks.md  AGENT.md  CLAUDE.md      │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Configuration

| Variable | Default | Description |
|---|---|---|
| `AGENT_MODE` | `single` | `single` = one agent per loop, `team` = parallel teammates |
| `TEAM_SIZE` | `3` | Number of teammates to spawn in team mode |

> **Note:** Agent Teams require Claude Code and an Anthropic API key. Gemini CLI does not support this feature.

---

## The Ralph Wiggum Principle

The [Ralph Wiggum Loop](https://ghuntley.com/ralph/) (by Geoff Huntley) is the insight that:

- LLMs work best with **fresh context** on each task
- **One task per iteration** maximizes the "smart zone" of context utilization
- **Commit after each task** — git is your external memory
- **Assume failure** — design the loop to recover, not to avoid errors

ralph-claw is an opinionated Docker implementation of this principle.

---

## Memory Architecture

The agent accumulates knowledge across sessions via plain files:

- **`AGENT.md`** — standing instructions (the agent updates this when it learns something)
- **`tasks.md`** — current task list
- **`memory/`** — free-form notes, research, decisions
- **Git history** — immutable record of everything

No database. No platform. Just files and git.

---

## Terms of Service Compliance

> **IMPORTANT: Read before using ralph-claw with Anthropic Claude Code**

ralph-claw runs AI CLIs in an **automated loop**. This has implications for Terms of Service compliance depending on your authentication method:

| Auth Method | TOS Compliance | Notes |
|---|---|---|
| **API Key** (Commercial) | **OK** | API keys are designed for programmatic use. You pay per token. |
| **Consumer subscription** (Free/Pro/Max) | **NOT OK** | Violates Anthropic's Consumer TOS (automated access + non-ordinary usage) |

**If you use Claude Code with ralph-claw, use an API key from the [Anthropic Console](https://console.anthropic.com/), NOT a consumer subscription (Free, Pro, or Max).**

Anthropic's Consumer Terms of Service explicitly prohibit:
- Accessing services "through automated or non-human means, whether through a bot, script, or otherwise"
- Usage patterns that exceed "ordinary, individual usage" assumed by subscription plans

As of February 2026, Anthropic is actively enforcing these restrictions and has banned accounts and third-party tools that facilitate subscription arbitrage.

For a detailed analysis, see [TOS-ANALYSIS.md](TOS-ANALYSIS.md).

> **This also applies to other providers.** Check the terms of service for Gemini, Codex, Qwen, or any other CLI before running them in an automated loop.

---

## Contributing

Issues and PRs welcome. Keep it simple.

---

## License

MIT

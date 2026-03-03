# ralph-claw

ralph-claw is a persistent AI agent orchestration system. It runs AI CLIs (Claude Code, Gemini CLI, etc.) in an automated Docker loop using the "Ralph Wiggum Loop" methodology.

## Project Structure

- `loop.sh` — Main orchestration script (the Ralph Wiggum loop)
- `AGENT.md` — Standing instructions for the AI agent
- `tasks.md` — Task list with checkbox format (`- [ ]` pending, `- [x]` done)
- `docker-compose.yml` — Docker service definitions
- `.env.example` — Environment variables template
- `memory/` — Persistent notes and learnings across sessions

## How It Works

1. `loop.sh` starts the AI CLI, which reads `AGENT.md` and `tasks.md`
2. The agent completes one task per iteration and marks it done
3. The loop commits changes via git and restarts
4. Memory persists in the `memory/` directory and git history

## Agent Teams Mode

This project supports Claude Code Agent Teams for parallel task execution. When enabled:

- A team lead coordinates work and spawns teammates
- Each teammate works on independent tasks in parallel
- Teammates communicate via shared task list and messaging
- The lead synthesizes results and coordinates merges

### When to use teams

- Tasks in `tasks.md` that are independent and can run in parallel
- Research across multiple areas simultaneously
- Cross-cutting changes (e.g., frontend + backend + tests)

### When NOT to use teams

- Sequential tasks with dependencies
- Tasks that modify the same files
- Simple, single-file changes

## Conventions

- One task per agent iteration (in single-agent mode)
- Git is the external memory — commit after each task
- Keep `memory/learnings.md` updated with discoveries
- Mark tasks done with `[x]` in `tasks.md`

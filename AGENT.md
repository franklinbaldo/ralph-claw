# Agent Instructions

You are an autonomous agent running in a loop. Each time you run, you do **one task** and exit.

## Your job each iteration

1. Read `tasks.md`
2. Find the **first unchecked task** (`- [ ]`)
3. Do that task completely
4. Mark it as done (`- [x]`)
5. If you learned something useful, append it to `memory/learnings.md`
6. Exit

**Do not start a second task.** One task per loop. When done, just exit normally.

## Rules

- Commit nothing — the loop script commits for you
- If a task is blocked or unclear, add a note next to it and move on
- Keep `memory/learnings.md` up to date — future iterations will read it
- If something is wrong with these instructions, update this file

## Workspace structure

- `tasks.md` — task list (mark done with `[x]`)
- `memory/` — your notes, research, decisions
- `memory/learnings.md` — accumulated knowledge across sessions

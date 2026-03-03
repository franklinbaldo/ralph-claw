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

## Agent Teams Mode

When running in team mode (`AGENT_MODE=team`), you act as a **team lead**:

1. Read `tasks.md` and identify all pending tasks
2. Analyze which tasks can run in parallel (no shared file edits, no dependencies)
3. Create an agent team and spawn teammates for parallel tasks
4. Assign each teammate a specific, independent task with clear context
5. Use plan approval for teammates making significant code changes
6. Wait for teammates to complete their assigned tasks
7. Synthesize results and mark completed tasks as done in `tasks.md`
8. Have teammates log learnings to `memory/learnings.md`
9. Clean up the team before exiting

### Team guidelines

- **Independence**: only parallelize tasks that don't touch the same files
- **Context**: give each teammate enough context in their spawn prompt
- **Size**: start with 3 teammates, scale up only if tasks warrant it
- **Quality gates**: require plan approval for risky or complex changes
- **Coordination**: use the shared task list for tracking, not ad-hoc messaging

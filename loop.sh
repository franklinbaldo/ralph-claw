#!/usr/bin/env bash
# ralph-claw loop.sh — The Ralph Wiggum Loop
#
# Runs the AI agent in a tight loop:
#   1. Start the agent (reads AGENT.md + tasks.md)
#   2. Agent does one task and exits
#   3. Commit whatever changed
#   4. Check if all tasks done
#   5. Sleep briefly, repeat
#
# Modes:
#   AGENT_MODE=single  — one agent, one task per loop (default)
#   AGENT_MODE=team    — Claude Code Agent Teams, parallel task execution

set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
SLEEP_BETWEEN_LOOPS="${SLEEP_BETWEEN_LOOPS:-5}"
MAX_LOOPS="${MAX_LOOPS:-0}"  # 0 = infinite
PROVIDER="${PROVIDER:-claude}"
AGENT_MODE="${AGENT_MODE:-single}"
TEAM_SIZE="${TEAM_SIZE:-3}"

cd "$WORKSPACE"

# Ensure git is configured
git config --global user.email "ralph@ralph-claw.local" 2>/dev/null || true
git config --global user.name "Ralph" 2>/dev/null || true

loop_count=0

echo "🔄 ralph-claw starting. Provider: $PROVIDER | Mode: $AGENT_MODE"
echo "   Workspace: $WORKSPACE"
echo "   Max loops: ${MAX_LOOPS:-∞}"
if [[ "$AGENT_MODE" == "team" ]]; then
    echo "   Team size: $TEAM_SIZE"
fi
echo ""

# Build the prompt for team mode
build_team_prompt() {
    local pending_tasks
    pending_tasks=$(grep '^\- \[ \]' "$WORKSPACE/tasks.md" 2>/dev/null || true)
    local task_count
    task_count=$(echo "$pending_tasks" | grep -c '.' 2>/dev/null || echo "0")

    cat <<PROMPT
$(cat "$WORKSPACE/AGENT.md")

## Agent Teams Mode

You have $task_count pending tasks. Create an agent team to work on them in parallel.

### Current pending tasks:
$pending_tasks

### Instructions:
1. Analyze the pending tasks and identify which can run in parallel
2. Create an agent team with up to $TEAM_SIZE teammates
3. Assign independent tasks to different teammates
4. For tasks with dependencies, ensure proper ordering
5. Coordinate the team to complete as many tasks as possible
6. Mark each completed task as done in tasks.md (\`- [x]\`)
7. Have teammates write learnings to memory/learnings.md
8. Clean up the team when done

Use plan approval for teammates making significant changes.
PROMPT
}

while true; do
    loop_count=$((loop_count + 1))
    echo "━━━ Loop #$loop_count ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"

    # Check if there are any pending tasks
    if [[ -f "$WORKSPACE/tasks.md" ]]; then
        pending=$(grep -c '^\- \[ \]' "$WORKSPACE/tasks.md" 2>/dev/null || echo "0")
        if [[ "$pending" == "0" ]]; then
            echo "✅ All tasks complete. Stopping."
            exit 0
        fi
        echo "📋 $pending task(s) pending"
    fi

    # Run the agent
    echo "🤖 Starting $PROVIDER (mode: $AGENT_MODE)..."
    case "$PROVIDER" in
        claude)
            if [[ "$AGENT_MODE" == "team" ]]; then
                claude \
                    --dangerously-skip-permissions \
                    --print \
                    "$(build_team_prompt)" \
                    || true
            else
                claude \
                    --dangerously-skip-permissions \
                    --print \
                    "$(cat "$WORKSPACE/AGENT.md")" \
                    || true
            fi
            ;;
        gemini)
            gemini \
                --yolo \
                "$(cat "$WORKSPACE/AGENT.md")" \
                || true
            ;;
        *)
            echo "❌ Unknown provider: $PROVIDER"
            exit 1
            ;;
    esac

    # Commit whatever the agent changed
    echo "💾 Committing work..."
    if ! git diff --quiet HEAD 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
        git add -A
        git commit -m "chore(ralph): loop #$loop_count checkpoint" \
            --allow-empty-message 2>/dev/null || \
        git commit -m "chore(ralph): loop #$loop_count checkpoint"
        echo "   Committed."
    else
        echo "   No changes."
    fi

    # Check max loops
    if [[ "$MAX_LOOPS" -gt 0 && "$loop_count" -ge "$MAX_LOOPS" ]]; then
        echo "🛑 Reached max loops ($MAX_LOOPS). Stopping."
        exit 0
    fi

    echo "😴 Sleeping ${SLEEP_BETWEEN_LOOPS}s..."
    sleep "$SLEEP_BETWEEN_LOOPS"
    echo ""
done

#!/usr/bin/env bash
# ralph-claw loop.sh — The Ralph Wiggum Loop
#
# Runs the AI agent in a tight loop:
#   1. Start the agent (reads AGENT.md + tasks.md)
#   2. Agent does one task and exits
#   3. Commit whatever changed
#   4. Check if all tasks done
#   5. Sleep briefly, repeat

set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
SLEEP_BETWEEN_LOOPS="${SLEEP_BETWEEN_LOOPS:-5}"
MAX_LOOPS="${MAX_LOOPS:-0}"  # 0 = infinite
PROVIDER="${PROVIDER:-claude}"

cd "$WORKSPACE"

# Ensure git is configured
git config --global user.email "ralph@ralph-claw.local" 2>/dev/null || true
git config --global user.name "Ralph" 2>/dev/null || true

loop_count=0

echo "🔄 ralph-claw starting. Provider: $PROVIDER"
echo "   Workspace: $WORKSPACE"
echo "   Max loops: ${MAX_LOOPS:-∞}"
echo ""

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
    echo "🤖 Starting $PROVIDER..."
    case "$PROVIDER" in
        claude)
            claude \
                --dangerously-skip-permissions \
                --print \
                "$(cat "$WORKSPACE/AGENT.md")" \
                || true
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

#!/usr/bin/env bash
# sessionStart: when PM loop is enabled, inject the current backlog task as context.
# No-op (exit 0) unless .cursor/pm/enabled exists, so it is safe for normal sessions.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ENABLED_FILE=".cursor/pm/enabled"
BACKLOG=".cursor/pm/backlog.json"
STATE=".cursor/pm/state.json"

[[ -f "$ENABLED_FILE" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

task_index=0
title="(unknown)"
task_id=""
done_when=""

[[ -f "$STATE" ]] && task_index=$(jq -r '.task_index // 0' "$STATE")

if [[ -f "$BACKLOG" ]]; then
  title=$(jq -r --argjson i "$task_index" '.tasks[$i].title // "done"' "$BACKLOG")
  task_id=$(jq -r --argjson i "$task_index" '.tasks[$i].id // ""' "$BACKLOG")
  done_when=$(jq -r --argjson i "$task_index" '.tasks[$i].done_when // empty' "$BACKLOG")
fi

done_block=""
if [[ -n "$done_when" ]]; then
  done_block=$'\n\n**Done when (objective gate):** '"${done_when}"$'\nLaunch **loop-verifier** before ship. Ship only on PASS.'
fi

context="## Autonomous PM — AUTONOMOUS MODE

\`.cursor/pm/enabled\` is ON. Apply skill **autonomous-pm-loop**, and capture reusable insights via **cross-repo-learnings**.

**Current task index ${task_index}:** \`${task_id}\` — ${title}${done_block}

Ship every task in the same turn without asking the user, following this repo's ship workflow (run checks, commit, push, deploy or open a PR). Never end with \"Want me to commit?\" or \"Should I deploy?\".

When this turn ends, the stop hook queues the next backlog task.

Disable: \`rm .cursor/pm/enabled\`"

jq -n --arg context "$context" '{additional_context: $context}'
exit 0

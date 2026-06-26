#!/usr/bin/env bash
# stop: when PM loop is enabled and the turn completed, auto-queue the next backlog
# task (ship — no user prompt). No-op unless .cursor/pm/enabled exists.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

ENABLED_FILE=".cursor/pm/enabled"
BACKLOG=".cursor/pm/backlog.json"
STATE=".cursor/pm/state.json"
MAX_LOOPS=48
# ADAPT per repo: set backlog.json .git_footer to this repo's ship flow.
GIT_FOOTER=$'## Git (required)\nFollow this repo\'s ship workflow (see AGENTS.md / .cursor/rules): run checks, commit, push, and deploy or open a PR. Capture reusable insight via cross-repo-learnings. Do NOT ask the user to continue.'

[[ -f "$ENABLED_FILE" ]] || exit 0

if ! command -v jq >/dev/null 2>&1; then
  echo '{"followup_message":"[PM AUTO] Install jq (brew install jq), then re-enable PM."}'
  exit 0
fi

input=$(cat)
status=$(echo "$input" | jq -r '.status // "completed"')
loop_count=$(echo "$input" | jq -r '.loop_count // 0')

[[ "$status" == "completed" ]] || exit 0

if [[ "$loop_count" -ge "$MAX_LOOPS" ]]; then
  echo "{\"followup_message\":\"[PM AUTO] Safety cap ($MAX_LOOPS) reached. rm $ENABLED_FILE to stop.\"}"
  exit 0
fi

[[ -f "$BACKLOG" && -f "$STATE" ]] || exit 0

footer=$(jq -r '.git_footer // empty' "$BACKLOG")
task_index=$(jq -r '.task_index // 0' "$STATE")
task_count=$(jq '.tasks | length' "$BACKLOG")
next_index=$((task_index + 1))

[[ "$next_index" -lt "$task_count" ]] || exit 0

prompt=$(jq -r --argjson i "$next_index" '.tasks[$i].prompt' "$BACKLOG")
title=$(jq -r --argjson i "$next_index" '.tasks[$i].title' "$BACKLOG")
task_id=$(jq -r --argjson i "$next_index" '.tasks[$i].id' "$BACKLOG")
done_when=$(jq -r --argjson i "$next_index" '.tasks[$i].done_when // empty' "$BACKLOG")
finished_id=$(jq -r --argjson i "$task_index" '.tasks[$i].id // empty' "$BACKLOG")

now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
tmp="${STATE}.tmp"
jq --arg now "$now" --argjson next "$next_index" --arg fid "$finished_id" '
  .task_index = $next |
  .updated_at = $now |
  .completed_task_ids = (
    if $fid == "" then .completed_task_ids // []
    else ((.completed_task_ids // []) + [$fid] | unique)
    end
  )
' "$STATE" > "$tmp" && mv "$tmp" "$STATE"

extra="${footer:-$GIT_FOOTER}"

done_block=""
if [[ -n "$done_when" ]]; then
  done_block=$'\n\n**Done when:** '"${done_when}"$'\nLaunch loop-verifier before ship. Ship only on PASS.'
fi

followup=$(jq -n \
  --arg title "$title" \
  --arg id "$task_id" \
  --arg prompt "$prompt" \
  --arg extra "$extra" \
  --arg done "$done_block" \
  --argjson next "$next_index" \
  --argjson total "$task_count" \
  '{followup_message: ("[PM AUTO — do not wait for user] Task " + (($next + 1)|tostring) + "/" + ($total|tostring) + ": " + $title + " (`" + $id + "`)\n\n" + $prompt + $done + "\n\n" + $extra)}')

printf '%s\n' "$followup"
exit 0

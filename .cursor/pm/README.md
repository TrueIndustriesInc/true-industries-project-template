# Autonomous PM loop

Hooks-driven backlog runner. **Disabled by default** — the hooks no-op unless `.cursor/pm/enabled` exists.

## Files

| File | Role |
|------|------|
| `backlog.json` | Ordered tasks (`id`/`title`/`prompt`/`done_when`) + shared `git_footer`. |
| `state.json` | Progress cursor (`task_index`, `completed_task_ids`). |
| `enabled` | Presence = loop ON. Not committed. |
| `../agents/loop-verifier.md` | Read-only subagent for objective `done_when` checks before ship. |
| `../hooks.json` + `../hooks/pm-*.sh` | sessionStart injects current task; stop queues the next (cap: 48 loops). |

## Use

```bash
touch .cursor/pm/enabled   # start: next session/turn runs the backlog and ships each task
rm .cursor/pm/enabled      # stop
```

Requires `jq`. Reset progress: set `task_index` to 0 in `state.json`.

Before enabling: run the 4-condition test and per-task checks in skill **autonomous-pm-loop**.

## Rollout

1. Manual run once → 2. skill/AGENTS.md → 3. backlog with `done_when` → 4. enable.

See skill `.cursor/skills/autonomous-pm-loop/`.

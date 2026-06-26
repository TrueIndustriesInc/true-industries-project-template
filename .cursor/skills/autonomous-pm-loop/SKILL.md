---
name: autonomous-pm-loop
description: Run a backlog of tasks unattended via Cursor hooks, shipping each in the same turn. Use when the user enables the PM loop (.cursor/pm/enabled) or asks to run the backlog autonomously / overnight.
---

# Autonomous PM Loop

Hooks-driven runner that works a `backlog.json` one task per turn and ships each without asking the user. Portable across repos (adapt `git_footer` to each repo's ship flow).

## How it works

1. `.cursor/hooks.json` registers `sessionStart` → `pm-session.sh` and `stop` → `pm-stop.sh`.
2. Both hooks **no-op unless `.cursor/pm/enabled` exists** — safe for normal sessions.
3. `sessionStart` injects the current task (`state.json.task_index` → `backlog.json.tasks[i]`) as context.
4. When a turn completes, `stop` advances `task_index`, records the finished id, and emits the next task as a `followup_message`. Safety cap: `MAX_LOOPS=48`.

## Before you enable the loop

Run the **4-condition test** on the backlog. Miss one and keep tasks manual.

| # | Condition | Fail signal |
|---|-----------|-------------|
| 1 | Tasks repeat or amortize setup (weekly+) | One-off work — a good prompt is cheaper |
| 2 | Automated verification exists (`check-build`, tests, lint) | You read every diff — the loop didn't buy anything |
| 3 | Token budget can absorb retries | Metered plan + heavy verify loops → bill before value |
| 4 | Agent can run/repro the code it changes | Blind iteration without a dev env |

**30-second task check** (per queued task):

1. Happens at least weekly (or backlog is intentionally one sprint).
2. A test, type check, build, or linter can reject bad output.
3. Agent can run the changed code.
4. Hard stop exists (`MAX_LOOPS`, iteration cap, or time limit).
5. Human reviews before merge/deploy/dependency changes.

**Good first loops:** lint-and-fix, dependency bumps with tests, CI triage drafts, small bug fixes with strong coverage.

**Bad first loops:** architecture rewrites, auth/payments, production deploys, vague product work, anything where "done" is a judgment call.

## Rollout order

1. Do the task **manually once**, reliably.
2. Encode repeatable context in a **skill** (or `AGENTS.md` section).
3. Queue it in **`backlog.json`** with `done_when`.
4. **`touch .cursor/pm/enabled`** only after steps 1–3 pass.

## Operating under the loop (your job each turn)

- Do the current task fully.
- **Verify before ship** — see Verifier gate below.
- **Ship in the same turn**: follow this repo's ship workflow (`AGENTS.md` / `.cursor/rules`: run checks, commit, push, deploy or open a PR). Never ask "want me to commit?".
- Capture reusable insights via the `cross-repo-learnings` skill.
- Append a wrap line to `docs/OPS_STATUS.md` if it exists.
- Do not touch unrelated working-tree changes; stage only task files.

## Verifier gate (maker ≠ checker)

The agent that wrote the code must not be the only judge of "done."

After implementation, before commit:

1. Read the task's `done_when` (if set).
2. Launch the **loop-verifier** subagent (`.cursor/agents/loop-verifier.md`) with the criteria and your changes. Read-only — no file writes.
3. Run objective checks yourself too: `npm run check-build` (or repo equivalent), plus any `done_when` commands.
4. **Ship only on PASS.** If verifier or checks fail, fix or stop with a Human Action — do not loop on failure.

A second agent asked to "review" without tests/build output is a **Ralph Wiggum loop** — two optimists agreeing. The gate must be objective: exit code, test pass, linter zero, measurable threshold.

## Controls

```bash
touch .cursor/pm/enabled   # start
rm .cursor/pm/enabled      # stop
```

Requires `jq`. Reset: set `task_index` to 0 in `.cursor/pm/state.json`.

## Authoring a backlog

`backlog.json` tasks are small and independently shippable:

```json
{
  "id": "fix-flaky-auth",
  "title": "Fix flaky auth test",
  "prompt": "Reproduce and fix the flaky sign-in test in tests/auth.",
  "done_when": "npm run test -- auth exits 0; no new files outside src/ or tests/"
}
```

- **`done_when`** (optional but recommended): measurable pass criteria — commands, exit codes, file boundaries. Not "looks good."
- Shared **`git_footer`**: appended to every queued prompt; per-repo, edit to match that repo's deploy command.

## Costs to watch

Loops get better at shipping; these risks get worse:

| Cost | What it is | Mitigation |
|------|------------|------------|
| Verification debt | More output than review bandwidth | Small tasks; read diffs; spot-check gates |
| Comprehension rot | Repo grows faster than team understanding | Block architecture/auth from backlog |
| Cognitive surrender | Accepting loop output without judgment | Verifier gate; human merge review |
| Token blowout | Retries + context re-reads | `MAX_LOOPS`; skip non-repeating work |

**Metric:** cost per **accepted** change. If <50% of loop PRs merge without major rework, tighten `done_when` or shrink task scope.

## Guardrails

- Keep the loop **disabled by default** in committed state (never commit `enabled`).
- Big/risky refactors: split into small tasks; never queue a single task that rewrites many files unreviewed.
- If a task can't ship cleanly (build fails, missing creds, verifier FAIL), stop and flag a Human Action — do not loop on failure.
- Do not auto-install community skills into unattended loops; audit skill sources (injection risk).
- Re-audit write permissions on connectors/MCP every 30 days if loops run unattended.

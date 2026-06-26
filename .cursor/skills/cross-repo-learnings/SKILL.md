---
name: cross-repo-learnings
description: Capture reusable learnings in every project and propagate adopted ones across all our repos. Use at the end of any task that revealed a reusable insight (a better pattern, a footgun, a convention, a tooling win), or when starting work and you want prior learnings.
---

# Cross-Repo Learnings Loop

Goal: **always be learning in every project, and apply our learnings across every repo we own.**
This skill is portable — drop it into any repo's `.cursor/skills/` unchanged.

## When to capture (trigger)

Capture a learning whenever a task surfaced something reusable beyond this one task:

- A pattern that worked well and should be the default elsewhere.
- A footgun / mistake and how to avoid it (root cause, not symptom).
- A convention or tooling choice worth standardizing (lint, CI, deploy, structure).
- A cross-repo inconsistency you noticed.

If it only matters for this single file/task, do **not** capture it. Keep the ledger high-signal.

## Where it lives

- **Canonical store (hub):** `true-industries-playbook` repo (`learnings.json` + derived `.cursor/rules` / `.cursor/skills`). When the hub does not exist yet, the **local ledger is canonical** and gets promoted later.
- **Local ledger (every repo):** `agents/projectManager/learnings.json` (or `docs/learnings.json` in repos without that path). New entries land here first.

## Entry format

Append to the local `learnings.json` `entries` array:

```json
{
  "id": "L-YYYY-MM-DD-short-slug",
  "date": "YYYY-MM-DD",
  "source_repo": "<repo this came from>",
  "domain": "agent-system | conventions | tooling | deploy | architecture | integration | ...",
  "problem": "1 line: what was suboptimal / what we hit",
  "learning": "1-2 lines: the reusable insight",
  "action": "concrete change: a rule, skill, script, or convention to adopt",
  "applies_to": ["all"] | ["repo-a", "repo-b"],
  "status": "proposed | adopted | rejected"
}
```

Rules:
- `id` is unique and date-prefixed. Never rewrite history — supersede with a new entry and set the old one to `rejected` if reversed.
- Default `status` is `proposed`. Only the human or the PM agent moves it to `adopted`.
- `applies_to: ["all"]` means it belongs in the hub and every repo.

## Propagation (apply across repos)

1. **Promote**: PM agent reviews `proposed` entries → marks `adopted` → copies the entry to the hub `learnings.json`.
2. **Materialize**: turn each `adopted` entry's `action` into a concrete artifact in the hub:
   - convention/policy → `.cursor/rules/*.mdc`
   - repeatable procedure → `.cursor/skills/*`
   - automation → `scripts/*`
3. **Sync down**: each target repo in `applies_to` pulls the hub artifact (copy or submodule) and records it as `adopted` locally.
4. **Verify**: confirm the artifact is wired (rule applies / skill discoverable / script referenced).

## Cadence

- **End of task**: capture if the trigger fired (this is the default; don't skip).
- **PM weekly review**: promote/reject `proposed`, run propagation for `adopted`, report what shipped to which repos.

## Done means

A learning is not "done" when written — it's done when it's `adopted` and present in **every** repo listed in `applies_to`.

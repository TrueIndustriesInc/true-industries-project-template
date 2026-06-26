# Agent instructions — True Industries web project

Vercel prebuilt deploy via self-hosted Windows runner. See README.md and `.cursor/skills/deploy-vercel-prebuilt/`.

## Verify gate

Before ship: `npm run check-build` must pass.

## Cross-repo learnings (hub)

1. Read [true-industries-playbook/learnings.json](https://github.com/TrueIndustriesInc/true-industries-playbook/blob/main/learnings.json) for adopted org learnings.
2. Capture new insights locally in `docs/learnings.json` (`proposed`) via the `cross-repo-learnings` skill.
3. PM loop: skill **autonomous-pm-loop** — disabled unless `.cursor/pm/enabled` exists.
4. Append joint session time per `.cursor/rules/joint-time-log.mdc`.

## Git workflow

- Branch `feat/…` or `fix/…`; PR into `main`.
- Production deploy via GitHub Actions + `true-build-windows` runner only.

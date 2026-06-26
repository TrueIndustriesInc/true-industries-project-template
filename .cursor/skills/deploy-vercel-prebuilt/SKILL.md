---
name: deploy-vercel-prebuilt
description: Trigger a prebuilt Vercel production deploy via the True Industries Windows self-hosted runner. Use when the user asks to deploy, ship, build, release, or push to Vercel for an existing repo.
---

# Deploy Vercel Prebuilt (remote)

Trigger GitHub Actions → `true-build-windows` runner → `vercel build --prod` → `vercel deploy --prebuilt --prod --archive=tgz`.

## Preflight

```bash
gh secret list --repo {Repo} | rg VERCEL_PROJECT_ID
gh api orgs/TrueIndustriesInc/actions/runners --jq '.runners[] | select([.labels[].name] | index("true-build-windows")) | {name, status}'
```

If `VERCEL_PROJECT_ID` missing → run `.\scripts\bootstrap-vercel-project.ps1` once on Windows.

## Deploy

**One trigger per ship** — do not manual-dispatch if a push to `main` will also run the workflow.

```bash
gh workflow run "Build on True Runner and Deploy Prebuilt to Vercel" --repo {Repo}
gh run watch --repo {Repo} --exit-status
```

Or: `.\scripts\first-deploy.ps1 -Repo {Repo}`

## Vercel config

- `vercel.json`: `"installCommand": "npm ci"` and `"git": { "deploymentEnabled": false }`
- Dashboard **Install Command** must match (`npm ci`) or the config-mismatch warning persists until the next aligned prod deploy

## Vercel logs (success)

```
Using prebuilt build artifacts from .vercel/output
Deploying outputs...
```

That is a prebuilt upload, not a cloud compile.

## Do not

- Deploy from cloud without preflight
- Commit `.vercel/` or secrets
- Patch `vercel.json` in CI
- Enable Vercel Git auto-builds

## On failure

| Symptom | Fix |
|---------|-----|
| Symlink deploy error | `--archive=tgz` on deploy step |
| Config mismatch warning | Align dashboard Install Command with `vercel.json` |
| Duplicate deploys | Avoid push + manual trigger together |

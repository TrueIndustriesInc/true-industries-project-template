# True Industries Project Template

Reusable starter for new web projects that deploy to Vercel using a self-hosted Windows build machine and GitHub Actions prebuilt deploys.

## Deployment model

GitHub Actions controls all production deploys. Builds run on the self-hosted runner labeled `true-build-windows`, then deploy prebuilt artifacts to Vercel:

```bash
vercel build --prod
vercel deploy --prebuilt --prod
```

**Do not rely on Vercel Git auto-builds.** When linking a project in Vercel, disable or avoid Git-triggered deployments so this workflow remains the deployment controller.

## Secrets

### GitHub organization secrets (already configured)

| Secret | Scope |
|--------|-------|
| `VERCEL_TOKEN` | Organization |
| `VERCEL_ORG_ID` | Organization |

### Repo-specific secret (created by bootstrap script)

| Secret | Scope |
|--------|-------|
| `VERCEL_PROJECT_ID` | Repository |

The bootstrap script reads this from `.vercel/project.json` after `vercel link` and sets it via `gh secret set`. Never commit `.vercel/`.

## Runner

Workflows require a self-hosted runner with the label:

```
true-build-windows
```

## Setup for a new project

1. **Create repo from this template** on GitHub.
2. **Clone** the new repo locally.
3. **Install dependencies:**
   ```powershell
   npm install
   ```
4. **Bootstrap, verify runner, and trigger first deploy (one command):**
   ```powershell
   .\scripts\new-vercel-project.ps1
   ```
   Or step-by-step: `bootstrap-vercel-project.ps1` → `verify-runner.ps1` → `first-deploy.ps1`

## Manual workflow trigger

You can also run the workflow from the GitHub Actions UI: **Build on True Runner and Deploy Prebuilt to Vercel**.

## Files of note

| Path | Purpose |
|------|---------|
| `.github/workflows/deploy-vercel-prebuilt.yml` | CI/CD workflow |
| `.cursor/rules/deployment.md` | Cursor agent deployment standard |
| `scripts/new-vercel-project.ps1` | Full setup: bootstrap → verify runner → first deploy |
| `scripts/bootstrap-vercel-project.ps1` | Link Vercel project, set `VERCEL_PROJECT_ID` |
| `scripts/verify-runner.ps1` | Check `true-build-windows` runner availability |
| `scripts/first-deploy.ps1` | Trigger first workflow run |
| `.cursor/skills/new-vercel-project/SKILL.md` | Cursor agent skill — say "create a new project" |

---
name: new-vercel-project
description: Create a new True Industries web project from the Vercel prebuilt template. Use when the user asks to create, scaffold, or bootstrap a new project/repo with Vercel deploy on the true-build-windows runner.
---

# New Vercel Project

Spin up a repo from this template and wire Vercel + GitHub Actions with minimal exploration.

## Inputs (ask only if missing)

| Input | Default |
|-------|---------|
| `Org` | `TrueIndustriesInc` |
| `RepoName` | *(required)* |
| `ProjectName` | same as `RepoName` |
| `Visibility` | `private` |

Full repo slug: `{Org}/{RepoName}`

## Do not

- Re-read or re-explain template files — they are canonical.
- Commit `.vercel/`, `.env*`, or secrets.
- Enable Vercel Git auto-builds.
- Run `vercel link` manually unless bootstrap fails.

## Flow

### 1. Create repo from template

```powershell
gh repo create {Org}/{RepoName} --template {Org}/true-industries-project-template --{Visibility} --clone
cd {RepoName}
```

### 2. Install + bootstrap (Windows / PowerShell)

Requires `gh` auth and `vercel login` on this machine.

```powershell
npm install
.\scripts\bootstrap-vercel-project.ps1 -Repo {Org}/{RepoName} -TriggerDeploy
```

Or full setup with runner check:

```powershell
.\scripts\new-vercel-project.ps1 -Repo {Org}/{RepoName} -ProjectName {ProjectName}
```

Or step-by-step:

```powershell
.\scripts\bootstrap-vercel-project.ps1 -Repo {Org}/{RepoName} -ProjectName {ProjectName}
.\scripts\verify-runner.ps1 -Repo {Org}/{RepoName}
.\scripts\first-deploy.ps1 -Repo {Org}/{RepoName}
```

### 3. Verify

- Repo secret `VERCEL_PROJECT_ID` exists: `gh secret list --repo {Org}/{RepoName}`
- Workflow run started: `gh run list --repo {Org}/{RepoName} --limit 3`
- In Vercel: disable Git-triggered deployments for this project

### 4. Done means

- Repo exists with template contents
- `VERCEL_PROJECT_ID` secret set
- `true-build-windows` runner available
- First workflow run triggered

## References (read only on failure)

| Artifact | Path |
|----------|------|
| Deploy workflow | `.github/workflows/deploy-vercel-prebuilt.yml` |
| Deployment rule | `.cursor/rules/deployment.md` |
| Bootstrap | `scripts/bootstrap-vercel-project.ps1` |

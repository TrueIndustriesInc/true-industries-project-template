# True Industries Deployment Standard
When creating a new deployable web project:
1. Use the True Industries Vercel prebuilt deployment workflow.
2. Add `.github/workflows/deploy-vercel-prebuilt.yml`.
3. Target the self-hosted runner label `true-build-windows`.
4. Do not rely on Vercel Git auto-builds.
5. Use `vercel build --prod` followed by `vercel deploy --prebuilt --prod --archive=tgz`.
6. Commit `vercel.json` with `"installCommand": "npm ci"` and `"git": { "deploymentEnabled": false }` — do not patch installCommand in CI.
7. Add workflow `concurrency` (`cancel-in-progress: true`) so overlapping push + manual runs collapse to one deploy.
8. Use organization-level secrets for `VERCEL_TOKEN` and `VERCEL_ORG_ID`.
9. Set the repo-level `VERCEL_PROJECT_ID` from `.vercel/project.json`.
10. Never commit `.env`, `.env.local`, `.vercel`, or build output.
11. After setup, trigger the workflow once and verify deployment.

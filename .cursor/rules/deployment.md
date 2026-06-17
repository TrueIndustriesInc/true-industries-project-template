# True Industries Deployment Standard
When creating a new deployable web project:
1. Use the True Industries Vercel prebuilt deployment workflow.
2. Add `.github/workflows/deploy-vercel-prebuilt.yml`.
3. Target the self-hosted runner label `true-build-windows`.
4. Do not rely on Vercel Git auto-builds.
5. Use `vercel build --prod` followed by `vercel deploy --prebuilt --prod`.
6. Use organization-level secrets for `VERCEL_TOKEN` and `VERCEL_ORG_ID`.
7. Set the repo-level `VERCEL_PROJECT_ID` from `.vercel/project.json`.
8. Never commit `.env`, `.env.local`, `.vercel`, or build output.
9. After setup, trigger the workflow once and verify deployment.

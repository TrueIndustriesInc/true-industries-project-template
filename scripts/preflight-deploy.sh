#!/usr/bin/env bash
# Preflight checks for remote prebuilt deploy (no trigger).
# Usage: ./scripts/preflight-deploy.sh [owner/repo]
set -euo pipefail

REPO="${1:-TrueIndustriesInc/true-industries-web}"
WORKFLOW="Build on True Runner and Deploy Prebuilt to Vercel"
OK=0

echo "Repo: ${REPO}"
echo ""

if gh secret list --repo "$REPO" | grep -q 'VERCEL_PROJECT_ID'; then
  echo "OK  VERCEL_PROJECT_ID (repo secret)"
else
  echo "MISSING  VERCEL_PROJECT_ID — bootstrap required on Windows"
  OK=1
fi

if gh api "repos/${REPO}/contents/.github/workflows/deploy-vercel-prebuilt.yml" --jq .name >/dev/null 2>&1; then
  echo "OK  deploy-vercel-prebuilt.yml"
else
  echo "MISSING  .github/workflows/deploy-vercel-prebuilt.yml"
  OK=1
fi

RUNNER=$(gh api orgs/TrueIndustriesInc/actions/runners --jq '.runners[] | select([.labels[].name] | index("true-build-windows")) | "\(.name) \(.status)"' 2>/dev/null | head -1)
if [[ -n "$RUNNER" ]]; then
  echo "OK  runner: ${RUNNER}"
else
  echo "MISSING  true-build-windows runner"
  OK=1
fi

echo ""
if [[ $OK -eq 0 ]]; then
  echo "Ready for remote deploy: gh workflow run \"${WORKFLOW}\" --repo ${REPO}"
else
  echo "Not ready — fix items above before remote deploy."
  exit 1
fi

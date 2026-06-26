#!/usr/bin/env bash
# Trigger prebuilt Vercel deploy workflow and show status.
# Usage: ./scripts/trigger-deploy.sh [owner/repo]
set -euo pipefail

REPO="${1:-TrueIndustriesInc/true-industries-web}"
WORKFLOW="Build on True Runner and Deploy Prebuilt to Vercel"

echo "==> Preflight: ${REPO}"

if ! gh secret list --repo "$REPO" | grep -q 'VERCEL_PROJECT_ID'; then
  echo "ERROR: VERCEL_PROJECT_ID not set on ${REPO}."
  echo "Run on Windows once: .\\scripts\\bootstrap-vercel-web.ps1  (or bootstrap-vercel-project.ps1 for template repos)"
  exit 1
fi

RUNNER=$(gh api orgs/TrueIndustriesInc/actions/runners --jq '.runners[] | select([.labels[].name] | index("true-build-windows")) | .status' 2>/dev/null | head -1)
if [[ "$RUNNER" != "online" ]]; then
  echo "WARNING: true-build-windows runner status: ${RUNNER:-not found}"
fi

echo "==> Triggering: ${WORKFLOW}"
gh workflow run "$WORKFLOW" --repo "$REPO"

sleep 3
echo "==> Recent runs"
gh run list --repo "$REPO" --workflow "$WORKFLOW" --limit 3

echo ""
echo "Watch: gh run watch --repo ${REPO}"

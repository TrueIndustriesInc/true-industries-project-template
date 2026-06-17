param(
  [string]$Repo
)

$ErrorActionPreference = "Stop"

function Require-Command {
  param([string]$Name, [string]$Hint)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    Write-Error "$Name is required. $Hint"
  }
}

Require-Command -Name "gh" -Hint "Install GitHub CLI: https://cli.github.com/"

if ([string]::IsNullOrWhiteSpace($Repo)) {
  if (Test-Path ".git") {
    Write-Host "Inferring GitHub repo from gh..."
    $Repo = gh repo view --json nameWithOwner -q .nameWithOwner
  }
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = Read-Host "Enter GitHub repo (owner/repo)"
  }
}

$workflowName = "Build on True Runner and Deploy Prebuilt to Vercel"

Write-Host "Triggering workflow '$workflowName' on $Repo..."
gh workflow run $workflowName --repo $Repo
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to trigger workflow. Confirm the workflow file exists on the default branch."
}

Write-Host ""
Write-Host "Recent workflow runs:"
Write-Host ("-" * 72)
gh run list --repo $Repo --limit 5
if ($LASTEXITCODE -ne 0) {
  Write-Warning "Could not list recent runs."
  exit 1
}

Write-Host ""
Write-Host "Watch a run:"
Write-Host "  gh run watch --repo $Repo"

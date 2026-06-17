param(
  [string]$Repo,
  [string]$ProjectName
)

$ErrorActionPreference = "Stop"

function Require-Command {
  param([string]$Name, [string]$Hint)
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    Write-Error "$Name is required. $Hint"
  }
}

Require-Command -Name "gh" -Hint "Install GitHub CLI: https://cli.github.com/"
Require-Command -Name "git" -Hint "Install Git: https://git-scm.com/"

Write-Host "Checking Vercel CLI via npx..."
$vercelVersion = npx vercel --version 2>&1
if ($LASTEXITCODE -ne 0) {
  Write-Error "Vercel CLI is not available through npx. Run 'npm install' first."
}
Write-Host "Vercel CLI: $vercelVersion"

if (-not (Test-Path ".git")) {
  Write-Error "Current folder is not a git repository. Clone your repo first."
}

if ([string]::IsNullOrWhiteSpace($Repo)) {
  Write-Host "Inferring GitHub repo from gh..."
  $Repo = gh repo view --json nameWithOwner -q .nameWithOwner
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Repo)) {
    $Repo = Read-Host "Enter GitHub repo (owner/repo)"
  }
}

Write-Host "Using repo: $Repo"

Write-Host "Linking Vercel project..."
if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
  npx vercel link --yes --project $ProjectName
} else {
  npx vercel link
}
if ($LASTEXITCODE -ne 0) {
  Write-Error "vercel link failed."
}

$projectJsonPath = Join-Path ".vercel" "project.json"
if (-not (Test-Path $projectJsonPath)) {
  Write-Error "Expected $projectJsonPath after vercel link."
}

$project = Get-Content $projectJsonPath -Raw | ConvertFrom-Json
$projectId = $project.projectId

if ([string]::IsNullOrWhiteSpace($projectId)) {
  Write-Error "projectId not found in $projectJsonPath"
}

Write-Host "Setting GitHub secret VERCEL_PROJECT_ID for $Repo..."
gh secret set VERCEL_PROJECT_ID --repo $Repo --body $projectId
if ($LASTEXITCODE -ne 0) {
  Write-Error "Failed to set VERCEL_PROJECT_ID secret."
}

Write-Host ""
Write-Host "Success."
Write-Host "  Repo:       $Repo"
Write-Host "  Project ID: $projectId"
Write-Host ""
Write-Host "VERCEL_PROJECT_ID has been set as a repository secret."
Write-Host ".vercel/ is gitignored — do not commit it."

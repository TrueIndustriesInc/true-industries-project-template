param(
    [string]$Repo,
    [string]$ProjectName,
    [switch]$SkipVercelLink,
    [switch]$TriggerDeploy
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Require-Command {
    param(
        [string]$Command,
        [string]$InstallHint
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Command is not installed or not available in PATH. $InstallHint"
    }
}

Write-Step "Checking required tools"

Require-Command "git" "Install Git for Windows: winget install Git.Git"
Require-Command "gh" "Install GitHub CLI: winget install GitHub.cli"
Require-Command "node" "Install Node LTS: winget install OpenJS.NodeJS.LTS"
Require-Command "npm" "Install Node LTS: winget install OpenJS.NodeJS.LTS"

Write-Success "Required tools found"

Write-Step "Checking GitHub CLI authentication"

$ghAuthStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
}

Write-Success "GitHub CLI authenticated"

Write-Step "Checking current git repo"

$insideGitRepo = git rev-parse --is-inside-work-tree 2>$null
if ($insideGitRepo -ne "true") {
    throw "This folder is not a git repo. Run this from the root of your project repo."
}

Write-Success "Current folder is a git repo"

if ([string]::IsNullOrWhiteSpace($Repo)) {
    Write-Step "Inferring GitHub repo"

    $repoJson = gh repo view --json nameWithOwner 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoJson)) {
        throw "Could not infer GitHub repo. Pass it manually, for example: -Repo TrueIndustriesInc/my-project"
    }

    $Repo = ($repoJson | ConvertFrom-Json).nameWithOwner
}

Write-Success "Using GitHub repo: $Repo"

Write-Step "Checking Vercel CLI"

npx vercel --version | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Vercel CLI could not run through npx. Try: npm install -D vercel"
}

Write-Success "Vercel CLI available through npx"

if (-not $SkipVercelLink) {
    Write-Step "Linking project to Vercel"

    if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
        Write-Host "Project name provided: $ProjectName"
        Write-Host "Vercel may still prompt you to confirm project/team settings."
    }

    npx vercel link --yes

    if ($LASTEXITCODE -ne 0) {
        throw "Vercel link failed."
    }

    Write-Success "Vercel project linked"
} else {
    Write-WarningMessage "Skipping Vercel link because -SkipVercelLink was provided"
}

Write-Step "Reading Vercel project metadata"

$projectJsonPath = ".vercel/project.json"

if (-not (Test-Path $projectJsonPath)) {
    throw "Could not find .vercel/project.json. Run: npx vercel link"
}

$project = Get-Content $projectJsonPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($project.projectId)) {
    throw "projectId was not found in .vercel/project.json"
}

if ([string]::IsNullOrWhiteSpace($project.orgId)) {
    throw "orgId was not found in .vercel/project.json"
}

Write-Success "Found Vercel project ID: $($project.projectId)"
Write-Success "Found Vercel org ID: $($project.orgId)"

Write-Step "Setting GitHub repo secret: VERCEL_PROJECT_ID"

$project.projectId | gh secret set VERCEL_PROJECT_ID --repo $Repo

if ($LASTEXITCODE -ne 0) {
    throw "Failed to set GitHub repo secret VERCEL_PROJECT_ID"
}

Write-Success "GitHub repo secret VERCEL_PROJECT_ID set for $Repo"

Write-Step "Checking .gitignore protects local Vercel files"

$gitignorePath = ".gitignore"

if (-not (Test-Path $gitignorePath)) {
    New-Item -ItemType File -Path $gitignorePath | Out-Null
}

$gitignoreContent = Get-Content $gitignorePath -Raw

$requiredIgnores = @(
    ".vercel",
    ".env",
    ".env.*",
    "node_modules",
    ".next",
    "dist",
    "build",
    "out"
)

$updatedGitignore = $false

foreach ($entry in $requiredIgnores) {
    if ($gitignoreContent -notmatch [regex]::Escape($entry)) {
        Add-Content -Path $gitignorePath -Value $entry
        $updatedGitignore = $true
    }
}

if ($updatedGitignore) {
    Write-Success ".gitignore updated"
} else {
    Write-Success ".gitignore already contains required entries"
}

Write-Step "Checking whether .vercel is tracked by git"

$trackedVercel = git ls-files .vercel

if (-not [string]::IsNullOrWhiteSpace($trackedVercel)) {
    Write-WarningMessage ".vercel appears to be tracked by git. Removing it from git index."

    git rm -r --cached .vercel

    Write-WarningMessage "You should commit the removal of .vercel from git tracking."
} else {
    Write-Success ".vercel is not tracked by git"
}

Write-Step "Checking workflow file"

$workflowPath = ".github/workflows/deploy-vercel-prebuilt.yml"

if (-not (Test-Path $workflowPath)) {
    Write-WarningMessage "Workflow file not found at $workflowPath"
    Write-WarningMessage "Add the workflow before expecting deployments to run."
} else {
    Write-Success "Workflow file exists"
}

if ($TriggerDeploy) {
    Write-Step "Triggering first deployment workflow"

    gh workflow run "Build on True Runner and Deploy Prebuilt to Vercel" --repo $Repo

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to trigger workflow"
    }

    Write-Success "Workflow triggered"

    Write-Step "Recent workflow runs"

    gh run list --repo $Repo --limit 5
}

Write-Step "Bootstrap complete"

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Commit any generated workflow or .gitignore changes:"
Write-Host "   git add .github .gitignore scripts"
Write-Host "   git commit -m `"Add True Industries Vercel prebuilt deployment`""
Write-Host "   git push"
Write-Host ""
Write-Host "2. Trigger the first deploy:"
Write-Host "   gh workflow run `"Build on True Runner and Deploy Prebuilt to Vercel`" --repo $Repo"
Write-Host ""
Write-Host "3. Watch runs:"
Write-Host "   gh run list --repo $Repo --limit 5"
Write-Host ""
Write-Host "Important: Do not commit .vercel, .env, or .env.local."

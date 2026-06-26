param(
    [string]$Repo,
    [string]$ProjectName,
    [string]$RepoRoot,
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
    Write-Host "[OK] $Message" -ForegroundColor Green
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

function Resolve-VercelProjectMetadata {
    param(
        [string]$ProjectName,
        [string]$VercelDirectory = "."
    )

    $candidateFiles = @(
        ".vercel/project.json",
        "../.vercel/project.json",
        ".vercel/repo.json",
        "../.vercel/repo.json"
    )

    foreach ($file in $candidateFiles) {
        if (-not (Test-Path $file)) {
            continue
        }

        Write-Host "Checking $file"
        $json = Get-Content $file -Raw | ConvertFrom-Json

        if ($file -like "*project.json") {
            if (-not [string]::IsNullOrWhiteSpace($json.projectId)) {
                return [PSCustomObject]@{
                    projectId = $json.projectId
                    orgId     = $json.orgId
                    source    = $file
                }
            }
            continue
        }

        if ($null -ne $json.projects) {
            $matches = @()

            foreach ($entry in $json.projects) {
                $entryId = $entry.projectId
                if ([string]::IsNullOrWhiteSpace($entryId) -and $entry.id) {
                    $entryId = $entry.id
                }
                if ([string]::IsNullOrWhiteSpace($entryId)) {
                    continue
                }

                $entryOrgId = $entry.orgId
                if ([string]::IsNullOrWhiteSpace($entryOrgId)) {
                    $entryOrgId = $json.orgId
                }

                $matches += [PSCustomObject]@{
                    projectId = $entryId
                    orgId     = $entryOrgId
                    name      = $entry.name
                    directory = $entry.directory
                    source    = $file
                }
            }

            if ($matches.Count -eq 1) {
                return $matches[0]
            }

            if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
                $byName = $matches | Where-Object { $_.name -eq $ProjectName }
                if ($byName.Count -ge 1) {
                    return $byName[0]
                }
            }

            $byDirectory = $matches | Where-Object { $_.directory -eq $VercelDirectory -or $_.directory -eq "web" }
            if ($byDirectory.Count -ge 1) {
                return $byDirectory[0]
            }

            if ($matches.Count -gt 0) {
                return $matches[0]
            }
        }
    }

    return $null
}

function Get-VercelProjectIdFromCli {
    param([string]$ProjectName)

    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        $ProjectName = "true-industries-web"
    }

    Write-Step "Falling back to vercel project inspect $ProjectName"
    $inspect = npx vercel project inspect $ProjectName 2>&1 | Out-String

    if ($inspect -match '(prj_[a-zA-Z0-9]+)') {
        return [PSCustomObject]@{
            projectId = $matches[1]
            orgId     = $null
            source    = "vercel project inspect"
        }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
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
        npx vercel link --yes --project $ProjectName
    } else {
        npx vercel link --yes
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Vercel link failed."
    }

    Write-Success "Vercel project linked"

    Write-Step "Pulling Vercel project settings (creates project.json with IDs)"
    npx vercel pull --yes --environment=production
    if ($LASTEXITCODE -ne 0) {
        throw "vercel pull failed after link."
    }
} else {
    Write-WarningMessage "Skipping Vercel link because -SkipVercelLink was provided"
}

Write-Step "Reading Vercel project metadata"

$project = Resolve-VercelProjectMetadata -ProjectName $ProjectName -VercelDirectory "web"

if ($null -eq $project) {
    $project = Get-VercelProjectIdFromCli -ProjectName $ProjectName
}

if ($null -eq $project) {
    throw "Could not find Vercel projectId. Checked .vercel/project.json, .vercel/repo.json, and vercel project inspect."
}

if ([string]::IsNullOrWhiteSpace($project.orgId)) {
    Write-WarningMessage "orgId not found in metadata; continuing with projectId only."
}

Write-Success "Found metadata in $($project.source)"
Write-Success "Found Vercel project ID: $($project.projectId)"
if ($project.orgId) {
    Write-Success "Found Vercel org ID: $($project.orgId)"
}

Write-Step "Setting GitHub repo secret: VERCEL_PROJECT_ID"

$project.projectId | gh secret set VERCEL_PROJECT_ID --repo $Repo

if ($LASTEXITCODE -ne 0) {
    throw "Failed to set GitHub repo secret VERCEL_PROJECT_ID"
}

Write-Success "GitHub repo secret VERCEL_PROJECT_ID set for $Repo"

Write-Step "Checking .gitignore protects local Vercel files"

$gitignorePath = Join-Path $RepoRoot ".gitignore"

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

Push-Location $RepoRoot
try {
    $trackedVercel = git ls-files .vercel web/.vercel
} finally {
    Pop-Location
}

if (-not [string]::IsNullOrWhiteSpace($trackedVercel)) {
    Write-WarningMessage ".vercel appears to be tracked by git. Removing it from git index."

    git rm -r --cached .vercel

    Write-WarningMessage "You should commit the removal of .vercel from git tracking."
} else {
    Write-Success ".vercel is not tracked by git"
}

Write-Step "Checking workflow file"

$workflowPath = Join-Path $RepoRoot ".github/workflows/deploy-vercel-prebuilt.yml"

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
Write-Host "Vercel project settings:" -ForegroundColor Cyan
Write-Host "  In the Vercel dashboard (Settings -> Build and Deployment), set Install Command to: npm ci"
Write-Host "  This must match vercel.json so production deploys do not show a config-mismatch warning."
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host '1. Commit any generated workflow or .gitignore changes:'
Write-Host '   git add .github .gitignore scripts'
Write-Host '   git commit -m "Add True Industries Vercel prebuilt deployment"'
Write-Host '   git push'
Write-Host ""
Write-Host '2. Trigger the first deploy:'
Write-Host "   gh workflow run ""Build on True Runner and Deploy Prebuilt to Vercel"" --repo $Repo"
Write-Host ""
Write-Host '3. Watch runs:'
Write-Host "   gh run list --repo $Repo --limit 5"
Write-Host ""
Write-Host 'Important: Do not commit .vercel, .env, or .env.local.'

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

Write-Host "Checking runners for repo: $Repo"
Write-Host ""
Write-Host "Expected self-hosted runner label: true-build-windows"
Write-Host ""
Write-Host "To verify manually:"
Write-Host "  1. GitHub repo -> Settings -> Actions -> Runners"
Write-Host "  2. Confirm a self-hosted runner is online with label 'true-build-windows'"
Write-Host ""

try {
  $response = gh api "repos/$Repo/actions/runners" 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not list runners (check repo access and permissions):"
    Write-Warning $response
    exit 1
  }

  $data = $response | ConvertFrom-Json
  $runners = @($data.runners)

  if ($runners.Count -eq 0) {
    Write-Warning "No runners found for $Repo."
    Write-Warning "Register a self-hosted runner with label 'true-build-windows'."
    exit 1
  }

  Write-Host "Runners:"
  Write-Host ("-" * 72)

  $foundLabel = $false

  foreach ($runner in $runners) {
    $labels = ($runner.labels | ForEach-Object { $_.name }) -join ", "
    $os = if ($runner.os) { $runner.os } else { "unknown" }
    $status = if ($runner.status) { $runner.status } else { "unknown" }

    Write-Host "  Name:   $($runner.name)"
    Write-Host "  OS:     $os"
    Write-Host "  Status: $status"
    Write-Host "  Labels: $labels"
    Write-Host ""

    if ($labels -match "true-build-windows") {
      $foundLabel = $true
    }
  }

  if ($foundLabel) {
    Write-Host "OK: Found runner with label 'true-build-windows'."
  } else {
    Write-Warning "No runner with label 'true-build-windows' found."
    Write-Warning "Deploy workflow will not run until this label is available."
    exit 1
  }
} catch {
  Write-Warning "Failed to query runners: $_"
  exit 1
}

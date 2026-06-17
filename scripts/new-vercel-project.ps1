param(
  [string]$Repo,
  [string]$ProjectName,
  [switch]$SkipDeploy,
  [switch]$SkipVercelLink
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== True Industries: New Vercel Project ==="
Write-Host ""

$bootstrapParams = @{
  Repo         = $Repo
  ProjectName  = $ProjectName
}
if ($SkipVercelLink) { $bootstrapParams.SkipVercelLink = $true }

& "$scriptDir\bootstrap-vercel-project.ps1" @bootstrapParams
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
& "$scriptDir\verify-runner.ps1" -Repo $Repo
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($SkipDeploy) {
  Write-Host ""
  Write-Host "Skipping first deploy (-SkipDeploy)."
  exit 0
}

Write-Host ""
& "$scriptDir\first-deploy.ps1" -Repo $Repo
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "=== Setup complete ==="

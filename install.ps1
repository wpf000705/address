$ErrorActionPreference = "Stop"

$requiredMajor = 20

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Error "Node.js is required. Please install Node.js $requiredMajor or newer."
}

$nodeVersion = node -p "process.versions.node"
$nodeMajor = [int]($nodeVersion.Split(".")[0])
if ($nodeMajor -lt $requiredMajor) {
  Write-Error "Node.js $requiredMajor+ is required. Current version: v$nodeVersion"
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Error "npm is required. Please reinstall Node.js with npm."
}

npm ci

Write-Host ""
Write-Host "Install complete."
Write-Host "Run .\start.ps1 to start the app."

$ErrorActionPreference = "Stop"

if (-not (Test-Path "node_modules")) {
  Write-Host "Dependencies are missing. Installing first..."
  & .\install.ps1
}

npm start

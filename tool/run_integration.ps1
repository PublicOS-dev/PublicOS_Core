# run_integration.ps1 — one-shot driver for the consent-flow integration
# test. Spins a fresh Hardhat node, deploys the full system,
# runs the Dart integration test, tears the node down.
#
# Usage (from anywhere):
#   <repo>\tool\run_integration.ps1 [-ContractsRepo <path>]
#
# Requires: ContactOS_Contracts checked out alongside PublicOS_Core
# (or passed with -ContractsRepo). node + npm + flutter on PATH.

param(
    [string]$ContractsRepo = (Join-Path $PSScriptRoot '..\..\ContactOS_Contracts')
)

$ErrorActionPreference = 'Stop'

$CORE_DIR = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$CONTRACTS_DIR = (Resolve-Path $ContractsRepo).Path

# Kill anything already listening on 8545 — safer than failing on EADDRINUSE.
Write-Host '[1/4] Clearing port 8545...' -ForegroundColor Cyan
$conns = netstat -ano | Select-String -Pattern ':8545\s+0\.0\.0\.0:0\s+LISTENING'
foreach ($line in $conns) {
    $pidNum = ($line.ToString() -split '\s+')[-1]
    if ($pidNum -match '^\d+$') {
        Write-Host "  killing pid $pidNum"
        taskkill /F /PID $pidNum 2>$null | Out-Null
    }
}
Start-Sleep -Seconds 2

# Start Hardhat node detached.
Write-Host '[2/4] Starting Hardhat node (chainId 4489)...' -ForegroundColor Cyan
$nodeLog = Join-Path $env:TEMP 'hh_node.log'
$nodeProc = Start-Process -FilePath 'cmd.exe' `
    -ArgumentList '/c', 'npx', 'hardhat', 'node', '--port', '8545' `
    -WorkingDirectory $CONTRACTS_DIR `
    -RedirectStandardOutput $nodeLog `
    -RedirectStandardError "$nodeLog.err" `
    -NoNewWindow -PassThru

# Wait for node to accept RPCs.
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    try {
        $r = Invoke-RestMethod -Uri 'http://127.0.0.1:8545' -Method Post `
            -Body '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' `
            -ContentType 'application/json' -TimeoutSec 2 -ErrorAction Stop
        if ($r.result -eq '0x1189') { $ready = $true; break }
    } catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ready) {
    Write-Host 'Node did not come up. Last log lines:' -ForegroundColor Red
    Get-Content $nodeLog -Tail 20
    if ($nodeProc -and -not $nodeProc.HasExited) { Stop-Process -Id $nodeProc.Id -Force }
    exit 1
}
Write-Host '  node ready (chainId 0x1189)' -ForegroundColor Green

try {
    # Deploy.
    Write-Host '[3/4] Deploying contracts + bootstrapping sponsor citizen...' -ForegroundColor Cyan
    Push-Location $CONTRACTS_DIR
    & npx hardhat run scripts/deploy-local.ts --network local
    if ($LASTEXITCODE -ne 0) { throw "deploy-local.ts failed with exit $LASTEXITCODE" }
    Pop-Location

    # Test.
    Write-Host '[4/4] Running Dart integration test...' -ForegroundColor Cyan
    Push-Location $CORE_DIR
    & flutter test test/integration/consent_flow_test.dart
    $testExit = $LASTEXITCODE
    Pop-Location

    if ($testExit -eq 0) {
        Write-Host '' -ForegroundColor Green
        Write-Host '✓ Integration tests passed.' -ForegroundColor Green
    } else {
        Write-Host '' -ForegroundColor Red
        Write-Host '✗ Integration tests failed.' -ForegroundColor Red
        exit $testExit
    }
} finally {
    # Always tear the node down.
    if ($nodeProc -and -not $nodeProc.HasExited) {
        Write-Host 'Stopping Hardhat node...' -ForegroundColor Cyan
        Stop-Process -Id $nodeProc.Id -Force
    }
}

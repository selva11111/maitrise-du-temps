$ErrorActionPreference = 'SilentlyContinue'
. "$PSScriptRoot\common-env.ps1"

$runtimeDir = Join-Path $ProjectRoot '.runtime'
$pidFile = Join-Path $runtimeDir 'web-server.pid'
$portFile = Join-Path $runtimeDir 'web-server.port'

if (Test-Path $pidFile) {
    $pidValue = Get-Content -LiteralPath $pidFile
    if ($pidValue) {
        Stop-Process -Id ([int]$pidValue) -Force
    }
    Remove-Item -LiteralPath $pidFile -Force
}

Remove-Item -LiteralPath $portFile -Force -ErrorAction SilentlyContinue
Write-Host 'Serveur web arrete.'

param(
    [int]$PreferredPort = 5237
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-env.ps1"
Initialize-ChronoEnvironment

$runtimeDir = Join-Path $ProjectRoot '.runtime'
if (-not (Test-Path $runtimeDir)) {
    New-Item -ItemType Directory -Path $runtimeDir | Out-Null
}

$pidFile = Join-Path $runtimeDir 'web-server.pid'
$portFile = Join-Path $runtimeDir 'web-server.port'
$outLog = Join-Path $runtimeDir 'web-server.out.log'
$errLog = Join-Path $runtimeDir 'web-server.err.log'

if (Test-Path $pidFile) {
    $oldPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue
    if ($oldPid) {
        try {
            Stop-Process -Id ([int]$oldPid) -Force -ErrorAction Stop
        } catch {}
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

$port = Get-ChronoFreePort -StartPort $PreferredPort
$process = Start-Process `
    -FilePath "$FlutterRoot\bin\flutter.bat" `
    -ArgumentList @('run', '-d', 'web-server', '--web-hostname', '127.0.0.1', '--web-port', "$port") `
    -WorkingDirectory $ProjectRoot `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -WindowStyle Hidden `
    -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id
Set-Content -LiteralPath $portFile -Value $port

$url = "http://127.0.0.1:$port"
$deadline = (Get-Date).AddSeconds(45)
$started = $false

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 800
    try {
        $response = Invoke-WebRequest -UseBasicParsing "$url/" -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $started = $true
            break
        }
    } catch {}
}

if (-not $started) {
    Write-Host "Le serveur web n'a pas demarre correctement."
    if (Test-Path $errLog) {
        Get-Content -LiteralPath $errLog -Tail 50
    }
    exit 1
}

Write-Host ''
Write-Host "Application web disponible ici :" -ForegroundColor Green
Write-Host $url -ForegroundColor Cyan
Write-Host ''
Write-Host "Logs :" -ForegroundColor Green
Write-Host $outLog
Write-Host $errLog

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common-env.ps1"
Initialize-ChronoEnvironment

flutter build apk --debug

$apk = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
if (Test-Path $apk) {
    Write-Host ''
    Write-Host 'APK genere :' -ForegroundColor Green
    Write-Host $apk -ForegroundColor Cyan
}

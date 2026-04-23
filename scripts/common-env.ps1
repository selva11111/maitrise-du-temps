$ProjectRoot = Split-Path -Parent $PSScriptRoot
$AndroidSdk = 'C:\Users\cyberselva\tools\android-sdk'
$FlutterRoot = 'C:\Users\cyberselva\tools\flutter'
$GitRoot = 'C:\Users\cyberselva\tools\mingit'
$JdkRoot = 'C:\Users\cyberselva\Desktop\codex app\tools\jdk-21'

function Initialize-ChronoEnvironment {
    $env:Path = "$FlutterRoot\bin;$GitRoot\cmd;$JdkRoot\bin;$AndroidSdk\platform-tools;$AndroidSdk\cmdline-tools\latest\bin;$env:Path"
    $env:JAVA_HOME = $JdkRoot
    $env:ANDROID_HOME = $AndroidSdk
    $env:ANDROID_SDK_ROOT = $AndroidSdk
    Set-Location -LiteralPath $ProjectRoot
}

function Get-ChronoFreePort {
    param(
        [int]$StartPort = 5237,
        [int]$EndPort = 5255
    )

    foreach ($port in $StartPort..$EndPort) {
        $listener = $null
        try {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
            $listener.Start()
            $listener.Stop()
            return $port
        } catch {
            if ($listener) {
                try { $listener.Stop() } catch {}
            }
        }
    }

    throw "Aucun port libre n'a ete trouve entre $StartPort et $EndPort."
}

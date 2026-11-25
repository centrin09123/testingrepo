#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installer otomatis Agent Scarbyce / MeshCentral untuk Windows Server.
#>

$ErrorActionPreference = "Stop"

# ==============================================================================
# KONFIGURASI DEPLOYMENT
# ==============================================================================
# Gunakan URL raw.githubusercontent.com agar mengunduh binary, bukan halaman HTML GitHub
$DownloadUrl   = "https://raw.githubusercontent.com/centrin09123/testingrepo/eb3a372a5a3035fc7110a33d26be0610d995ed0f/testing.exe"
$InstallerPath = Join-Path $env:TEMP "ServiceInstaller.exe"
$InstallArgs   = "-fullinstall"

# Opsional: Isi SHA256 hash jika ingin memvalidasi integritas file sebelum eksekusi (kosongkan "" untuk skip)
$ExpectedHash  = ""

# ==============================================================================
# PROSES INSTALASI
# ==============================================================================
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Memulai Deployment Agent pada: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Pastikan TLS 1.2 aktif (wajib untuk Windows Server lama seperti 2012 R2 / 2016)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    Write-Host "[1/4] Mengunduh installer dari repository..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing

    # Validasi 2 byte pertama file harus 'MZ' (0x4D 0x5A) untuk memastikan file adalah PE executable valid
    $headerBytes = [System.IO.File]::ReadAllBytes($InstallerPath)[0..1]
    if ($headerBytes[0] -ne 0x4D -or $headerBytes[1] -ne 0x5A) {
        throw "File yang terunduh bukan executable Windows yang valid (kemungkinan URL mengembalikan HTML)."
    }

    # Validasi SHA256 jika didefinisikan
    if (-not [string]::IsNullOrWhiteSpace($ExpectedHash)) {
        Write-Host "[2/4] Memverifikasi checksum SHA256..."
        $actualHash = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash
        if ($actualHash -ne $ExpectedHash.ToUpper()) {
            throw "Checksum tidak cocok! Expected: $ExpectedHash | Actual: $actualHash"
        }
    } else {
        Write-Host "[2/4] Melewati verifikasi checksum (ExpectedHash kosong)..."
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

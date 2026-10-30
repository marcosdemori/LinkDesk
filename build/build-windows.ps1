# ==============================================================================
# LinkDesk - Script de Build Automatizado para Windows
# Compila o executavel portatil (LinkDesk-SOS.exe) e o instalador (LinkDesk-Setup.exe)
# ==============================================================================

param(
    [string]$AppName = "LinkDesk",
    [string]$ServerHost = "connect.linkdesk.io",
    [string]$ServerPubKey = "",
    [switch]$SkipCargo = $false
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ClientDir = Join-Path $RepoRoot "client"
$ReleaseDir = Join-Path $RepoRoot "release"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "             LinkDesk - Build para Windows                " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "App Name   : $AppName"
Write-Host "Servidor   : $ServerHost"
Write-Host "Chave Pub  : $(if ($ServerPubKey) { $ServerPubKey } else { '(Padrao / Nao informada)' })"
Write-Host "----------------------------------------------------------"

# 1. Carregar caminhos padrao no PATH da sessao atual
$CargoBin = "C:\Users\Marcos De Mori\.cargo\bin"
if (-not (Test-Path $CargoBin)) {
    $CargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
}
if ((Test-Path $CargoBin) -and ($env:Path -notlike "*$CargoBin*")) {
    $env:Path = "$CargoBin;" + $env:Path
}

$FlutterBin = "C:\src\flutter\bin"
if ((Test-Path $FlutterBin) -and ($env:Path -notlike "*$FlutterBin*")) {
    $env:Path = "$FlutterBin;" + $env:Path
}

$VcpkgDir = "C:\vcpkg"
if (Test-Path $VcpkgDir) {
    $env:VCPKG_ROOT = $VcpkgDir
    [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VcpkgDir, "User")
}

$LlvmBin = "C:\Program Files\LLVM\bin"
if (Test-Path "$LlvmBin\libclang.dll") {
    $env:LIBCLANG_PATH = $LlvmBin
    if ($env:Path -notlike "*$LlvmBin*") {
        $env:Path = "$LlvmBin;" + $env:Path
    }
    [Environment]::SetEnvironmentVariable("LIBCLANG_PATH", $LlvmBin, "User")
}

# 2. Verificar Pre-requisitos
Write-Host "Verificando ferramentas de desenvolvimento..." -ForegroundColor Yellow

$MissingTools = @()

if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    $MissingTools += "Git (winget install --id Git.Git -e)"
}

if (-not (Get-Command "cargo" -ErrorAction SilentlyContinue)) {
    $MissingTools += "Rust & Cargo (winget install --id Rustlang.Rustup -e ; rustup default stable-x86_64-pc-windows-msvc)"
}

if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    $MissingTools += "Flutter SDK (git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter ; adicionar C:\src\flutter\bin ao PATH)"
}

if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    $MissingTools += "Python 3 (winget install --id Python.Python.3.11 -e)"
}

if ($MissingTools.Count -gt 0) {
    Write-Host "[!] Faltam ferramentas necessarias para o build local:" -ForegroundColor Red
    foreach ($tool in $MissingTools) {
        Write-Host "    - $tool" -ForegroundColor Red
    }
    Write-Host "`nInstale os itens acima e execute este script novamente." -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Todas as ferramentas estao disponiveis!" -ForegroundColor Green

# 2. Injetar Configuracoes e Marca
Write-Host "Injetando marca e parametros do servidor..." -ForegroundColor Yellow
python "$RepoRoot\tools\configure_linkdesk.py" "$AppName" "$ServerHost" "$ServerPubKey"

# 3. Executar o Build
Write-Host "Iniciando compilacao do core Rust e interface Flutter..." -ForegroundColor Yellow
Set-Location $ClientDir

if ($SkipCargo) {
    python build.py --flutter --skip-cargo
} else {
    python build.py --flutter
}

# 4. Organizar os Binarios Finais
New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
$AppFolder = Join-Path $ReleaseDir $AppName
New-Item -ItemType Directory -Force -Path $AppFolder | Out-Null

# Copiar Portable / SOS
$PossiblePortables = @(
    (Join-Path $ClientDir "target\release\rustdesk-portable-packer.exe"),
    (Join-Path $ClientDir "rustdesk_portable.exe"),
    (Get-ChildItem -Path $ClientDir -Filter "rustdesk-*-install.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1)
)

$FoundPortable = $PossiblePortables | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if ($FoundPortable) {
    $DestPortable = Join-Path $ReleaseDir "$AppName-SOS.exe"
    Copy-Item $FoundPortable $DestPortable -Force
    Write-Host "[OK] Executavel Portatil (SOS) gerado: $DestPortable" -ForegroundColor Green
}

# Copiar Pasta Completa do Aplicativo
$FlutterRelease = Join-Path $ClientDir "flutter\build\windows\x64\runner\Release"
if (Test-Path $FlutterRelease) {
    Copy-Item "$FlutterRelease\*" $AppFolder -Recurse -Force
    if (Test-Path "$AppFolder\rustdesk.exe") {
        Copy-Item "$AppFolder\rustdesk.exe" "$AppFolder\$AppName.exe" -Force
        Remove-Item "$AppFolder\rustdesk.exe" -Force
    }
    Write-Host "[OK] Pacote Completo gerado em: $AppFolder" -ForegroundColor Green
    Write-Host "[OK] Executavel: $AppFolder\$AppName.exe" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "           Build concluido com sucesso!                   " -ForegroundColor Green
Write-Host "Os executaveis estao disponiveis na pasta: $ReleaseDir" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

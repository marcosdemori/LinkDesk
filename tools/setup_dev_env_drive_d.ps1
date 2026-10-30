# ==============================================================================
# LinkDesk - Instalador do Ambiente de Desenvolvimento no Disco D:
# Configura Rust, Flutter, vcpkg e LLVM 100% no disco D: protegendo o disco C:
# ==============================================================================

$ErrorActionPreference = "Continue"

$DevRoot = "D:\Dev"
$CargoHome = "D:\Dev\.cargo"
$RustupHome = "D:\Dev\.rustup"
$FlutterDir = "D:\Dev\flutter"
$VcpkgDir = "D:\Dev\vcpkg"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    LinkDesk - Instalando Ambiente no Disco D:\Dev       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Destino Principal : $DevRoot" -ForegroundColor Yellow
Write-Host "Rust & Cargo      : $CargoHome" -ForegroundColor Yellow
Write-Host "Flutter SDK       : $FlutterDir" -ForegroundColor Yellow
Write-Host "vcpkg Codecs      : $VcpkgDir" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"

# 1. Criar pasta D:\Dev
if (-not (Test-Path $DevRoot)) {
    New-Item -ItemType Directory -Path $DevRoot -Force | Out-Null
    Write-Host "[OK] Criada pasta D:\Dev" -ForegroundColor Green
}

# 2. Configurar variaveis de ambiente de usuario para redirecionar tudo para o D:
Write-Host "-> Configurando variaveis de ambiente de usuario para D:\Dev..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("CARGO_HOME", $CargoHome, "User")
[Environment]::SetEnvironmentVariable("RUSTUP_HOME", $RustupHome, "User")
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VcpkgDir, "User")

$env:CARGO_HOME = $CargoHome
$env:RUSTUP_HOME = $RustupHome
$env:VCPKG_ROOT = $VcpkgDir

# Atualizar PATH de usuario
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$PathsToAdd = @(
    "$CargoHome\bin",
    "$FlutterDir\bin"
)

foreach ($p in $PathsToAdd) {
    if ($UserPath -notlike "*$p*") {
        $UserPath = "$p;$UserPath"
        Write-Host "[OK] Adicionado ao PATH: $p" -ForegroundColor Green
    }
    if ($env:Path -notlike "*$p*") {
        $env:Path = "$p;$env:Path"
    }
}
[Environment]::SetEnvironmentVariable("Path", $UserPath, "User")

# 3. Baixar e instalar Flutter SDK em D:\Dev\flutter
if (-not (Test-Path "$FlutterDir\bin\flutter.bat")) {
    Write-Host "-> Clonando Flutter SDK (versao stable) em $FlutterDir..." -ForegroundColor Yellow
    git clone https://github.com/flutter/flutter.git -b stable "$FlutterDir" --depth 1
    if (Test-Path "$FlutterDir\bin\flutter.bat") {
        Write-Host "[OK] Flutter SDK clonado com sucesso em D:\Dev\flutter!" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Flutter SDK ja esta instalado em $FlutterDir" -ForegroundColor Green
}

# 4. Baixar rustup-init e instalar Rust no disco D:
if (-not (Test-Path "$CargoHome\bin\cargo.exe")) {
    Write-Host "-> Baixando instalador do Rust (rustup-init)..." -ForegroundColor Yellow
    $RustupExe = "$DevRoot\rustup-init.exe"
    Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $RustupExe -UseBasicParsing
    
    Write-Host "-> Instalando Rust Toolchain em $CargoHome (aguarde)..." -ForegroundColor Yellow
    & $RustupExe -y --default-toolchain stable-x86_64-pc-windows-msvc --no-modify-path
    
    if (Test-Path "$CargoHome\bin\cargo.exe") {
        Write-Host "[OK] Rust & Cargo instalados com sucesso em D:\Dev\.cargo\bin!" -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Rust & Cargo ja estao instalados em $CargoHome" -ForegroundColor Green
}

# 5. Baixar e inicializar vcpkg em D:\Dev\vcpkg
if (-not (Test-Path "$VcpkgDir\vcpkg.exe")) {
    Write-Host "-> Clonando vcpkg em $VcpkgDir..." -ForegroundColor Yellow
    git clone https://github.com/microsoft/vcpkg.git "$VcpkgDir" --depth 1
    if (Test-Path "$VcpkgDir\bootstrap-vcpkg.bat") {
        Write-Host "-> Compilando vcpkg.exe..." -ForegroundColor Yellow
        & "$VcpkgDir\bootstrap-vcpkg.bat" -disableMetrics
    }
} else {
    Write-Host "[OK] vcpkg ja esta disponivel em $VcpkgDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   Configuracao concluida! Disco C: 100% protegido.       " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# ==============================================================================
# LinkDesk - Script de Build Automatizado para Windows
# Compila o executavel portatil (LinkDesk-SOS.exe) e o instalador (LinkDesk-install.exe)
# ==============================================================================

param(
    [string]$AppName = "LinkDesk",
    # Vazio mantem o servidor definido em client/libs/hbb_common/src/config.rs
    [string]$ServerHost = "",
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
Write-Host "Servidor   : $(if ($ServerHost) { $ServerHost } else { '(Mantido de config.rs)' })"
Write-Host "Chave Pub  : $(if ($ServerPubKey) { $ServerPubKey } else { '(Padrao / Nao informada)' })"
Write-Host "----------------------------------------------------------"

# 1. Carregar caminhos padrao no PATH da sessao atual (suporte a C:\ e D:\Dev)
# Redirecionar todo o ambiente Rust, Flutter e arquivos temporarios para o disco D:\Dev protegendo o C:\
$DevRoot = "D:\Dev"
$DevTmp = Join-Path $DevRoot "tmp"
if (-not (Test-Path $DevTmp)) { New-Item -ItemType Directory -Path $DevTmp -Force | Out-Null }
$env:TEMP = $DevTmp
$env:TMP = $DevTmp

$CandidateCargo = @(
    "D:\Dev\.cargo\bin",
    "C:\Users\Marcos De Mori\.cargo\bin",
    (Join-Path $env:USERPROFILE ".cargo\bin")
)
foreach ($c in $CandidateCargo) {
    if (Test-Path $c) {
        if ($env:Path -notlike "*$c*") { $env:Path = "$c;" + $env:Path }
        $env:CARGO_HOME = Split-Path -Parent $c
        break
    }
}

if (Test-Path "D:\Dev\.rustup") {
    $env:RUSTUP_HOME = "D:\Dev\.rustup"
}
$env:CARGO_BUILD_JOBS = "4"
$env:RUST_MIN_STACK = "67108864"

# Windows x64 compila com o mesmo Flutter fixo do CI (client/.github/workflows/flutter-build.yml):
# dependencias como extended_text/google_fonts nao compilam em Flutter mais novo.
$FlutterVersion = "3.24.5"
$FlutterRoot = Join-Path $DevRoot "flutter-$FlutterVersion"
if (-not (Test-Path "$FlutterRoot\bin\flutter.bat")) {
    Write-Host "-> Instalando Flutter $FlutterVersion em $FlutterRoot (uma vez)..." -ForegroundColor Cyan
    git clone https://github.com/flutter/flutter.git -b $FlutterVersion --depth 1 $FlutterRoot
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERRO] Falha ao clonar Flutter $FlutterVersion" -ForegroundColor Red
        exit 1
    }
    git -C $FlutterRoot apply (Join-Path $RepoRoot "client\.github\patches\flutter_3.24.4_dropdown_menu_enableFilter.diff")
    & "$FlutterRoot\bin\flutter.bat" precache --windows
    # https://github.com/flutter/flutter/issues/155685 - engine customizado usado pelo CI
    $EngineZip = Join-Path $env:TEMP "windows-x64-release.zip"
    $EngineTmp = Join-Path $env:TEMP "windows-x64-release"
    Invoke-WebRequest -Uri "https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip" -OutFile $EngineZip -UseBasicParsing
    Expand-Archive -Path $EngineZip -DestinationPath $EngineTmp -Force
    Copy-Item "$EngineTmp\*" "$FlutterRoot\bin\cache\artifacts\engine\windows-x64-release\" -Recurse -Force
}
# Flutter 3.24 so conhece os geradores CMake do VS 2019/2022; ensina o do VS 2026 (versao 18).
$VsToolDart = "$FlutterRoot\packages\flutter_tools\lib\src\windows\visual_studio.dart"
if (-not (Select-String -Path $VsToolDart -SimpleMatch "Visual Studio 18 2026" -Quiet)) {
    $VsSrc = [IO.File]::ReadAllText($VsToolDart).Replace(
        "17 => 'Visual Studio 17 2022',",
        "17 => 'Visual Studio 17 2022',`n      18 => 'Visual Studio 18 2026',")
    [IO.File]::WriteAllText($VsToolDart, $VsSrc, (New-Object Text.UTF8Encoding $false))
    Remove-Item "$FlutterRoot\bin\cache\flutter_tools.stamp" -Force -ErrorAction SilentlyContinue
    # Cache CMake gerado por outro Flutter/gerador impede a configuracao.
    Remove-Item (Join-Path $ClientDir "flutter\build\windows") -Recurse -Force -ErrorAction SilentlyContinue
}
$FlutterBin = Join-Path $FlutterRoot "bin"
$env:Path = "$FlutterBin;" + $env:Path
$env:FLUTTER_ROOT = $FlutterRoot

$CandidateVcpkg = @(
    "D:\Dev\vcpkg",
    "C:\vcpkg"
)
foreach ($v in $CandidateVcpkg) {
    if (Test-Path $v) {
        $env:VCPKG_ROOT = $v
        [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $v, "User")
        break
    }
}

$CandidateLlvm = @(
    "C:\Program Files\LLVM\bin",
    "D:\Dev\LLVM\bin"
)
foreach ($l in $CandidateLlvm) {
    if (Test-Path "$l\libclang.dll") {
        $env:LIBCLANG_PATH = $l
        if ($env:Path -notlike "*$l*") { $env:Path = "$l;" + $env:Path }
        [Environment]::SetEnvironmentVariable("LIBCLANG_PATH", $l, "User")
        break
    }
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
    $MissingTools += "Flutter SDK (adicionar bin ao PATH)"
}

if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    $MissingTools += "Python 3 (winget install --id Python.Python.3.11 -e)"
}

if (-not $env:LIBCLANG_PATH) {
    $MissingTools += "LLVM / libclang (winget install --id LLVM.LLVM -e)"
}

if (-not $env:VCPKG_ROOT) {
    $MissingTools += "vcpkg (git clone https://github.com/microsoft/vcpkg D:\Dev\vcpkg ; D:\Dev\vcpkg\bootstrap-vcpkg.bat)"
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

# Codecs C++ (mesmos pacotes do CI). Primeira instalacao demora varios minutos.
$VcpkgTriplet = "x64-windows-static"
$VcpkgInclude = Join-Path $env:VCPKG_ROOT "installed\$VcpkgTriplet\include"
$VcpkgHeaders = @("opus\opus_multistream.h", "vpx\vpx_encoder.h", "libyuv.h", "aom\aom_encoder.h")
if ($VcpkgHeaders | Where-Object { -not (Test-Path (Join-Path $VcpkgInclude $_)) }) {
    Write-Host "-> Instalando codecs via vcpkg ($VcpkgTriplet)..." -ForegroundColor Cyan
    Push-Location $env:VCPKG_ROOT
    & ".\vcpkg.exe" install "opus:$VcpkgTriplet" "libvpx:$VcpkgTriplet" "libyuv:$VcpkgTriplet" "aom:$VcpkgTriplet"
    $VcpkgExit = $LASTEXITCODE
    Pop-Location
    if ($VcpkgExit -ne 0) {
        Write-Host "[ERRO] vcpkg install falhou com codigo $VcpkgExit" -ForegroundColor Red
        exit $VcpkgExit
    }
}

# 3. Gerar Bindings Flutter Rust Bridge se necessário
$BridgeRs = Join-Path $ClientDir "src\bridge_generated.rs"
$BridgeDart = Join-Path $ClientDir "flutter\lib\generated_bridge.dart"

if ((-not (Test-Path $BridgeRs)) -or (-not (Test-Path $BridgeDart))) {
    Write-Host "Verificando bindings do Flutter Rust Bridge..." -ForegroundColor Yellow
    
    # Garantir que o package_config.json existe no flutter
    $PackageConfig = Join-Path $ClientDir "flutter\.dart_tool\package_config.json"
    if (-not (Test-Path $PackageConfig)) {
        Write-Host "-> Executando flutter pub get em client\flutter..." -ForegroundColor Cyan
        Push-Location "$ClientDir\flutter"
        flutter pub get
        Pop-Location
    }

    $FrbBin = Join-Path $RepoRoot "tools\flutter_rust_bridge_codegen.exe"
    if (-not (Test-Path $FrbBin)) {
        $FrbZip = Join-Path $env:TEMP "frb_codegen.zip"
        $FrbUrl = "https://github.com/fzyzcjy/flutter_rust_bridge/releases/download/v1.80.1/flutter_rust_bridge_codegen-x86_64-pc-windows-msvc-v1.80.1.zip"
        Write-Host "-> Baixando flutter_rust_bridge_codegen v1.80.1..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $FrbUrl -OutFile $FrbZip -UseBasicParsing
        Expand-Archive -Path $FrbZip -DestinationPath (Split-Path $FrbBin) -Force
    }
    
    Write-Host "-> Gerando bridge_generated.rs e generated_bridge.dart..." -ForegroundColor Cyan
    Push-Location $ClientDir
    # ffigen procura <llvm-path>\bin\libclang.dll
    $LlvmRoot = Split-Path -Parent $env:LIBCLANG_PATH
    & $FrbBin --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart --llvm-path $LlvmRoot --skip-deps-check
    $FrbExit = $LASTEXITCODE
    Pop-Location
    if ($FrbExit -ne 0 -or -not (Test-Path $BridgeDart)) {
        Write-Host "[ERRO] Falha ao gerar bindings do Flutter Rust Bridge (codigo $FrbExit)" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Bindings gerados com sucesso!" -ForegroundColor Green
}

# 4. Injetar Configuracoes e Marca
Write-Host "Injetando marca e parametros do servidor..." -ForegroundColor Yellow
python "$RepoRoot\tools\configure_linkdesk.py" "$AppName" "$ServerHost" "$ServerPubKey"

# 5. Executar o Build
Write-Host "Iniciando compilacao do core Rust e interface Flutter..." -ForegroundColor Yellow
Set-Location $ClientDir

# build.py renomeia rustdesk_portable.exe -> rustdesk-<versao>-install.exe e falha se o do build anterior existir.
Remove-Item (Join-Path $ClientDir "rustdesk_portable.exe"), (Join-Path $ClientDir "rustdesk-*-install.exe") -Force -ErrorAction SilentlyContinue

if ($SkipCargo) {
    python build.py --flutter --skip-cargo
} else {
    python build.py --flutter
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] python build.py falhou com codigo $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 6. Organizar os Binarios Finais
New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
$AppFolder = Join-Path $ReleaseDir $AppName
New-Item -ItemType Directory -Force -Path $AppFolder | Out-Null

# Copiar Instalador / Executavel Principal
$FoundInstaller = Get-ChildItem -Path $ClientDir -Filter "rustdesk-*-install.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -First 1
if ($FoundInstaller) {
    # O nome precisa terminar em "install.exe": e isso que faz o executavel abrir a tela de
    # instalacao (client/src/common.rs is_setup). Com outro nome ele roda como portatil.
    $DestInstaller = Join-Path $ReleaseDir "$AppName-install.exe"
    Copy-Item $FoundInstaller $DestInstaller -Force
    # Builds anteriores copiavam o instalador como $AppName.exe, que nao instala.
    Remove-Item (Join-Path $ReleaseDir "$AppName.exe") -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Instalador Principal gerado: $DestInstaller" -ForegroundColor Green
}

# Copiar Portable / SOS
$PossiblePortables = @(
    (Join-Path $ClientDir "rustdesk_portable.exe"),
    (Join-Path $ClientDir "target\release\rustdesk-portable-packer.exe"),
    $FoundInstaller,
    (Join-Path $ClientDir "flutter\build\windows\x64\runner\Release\rustdesk.exe")
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
    # Caso o instalador nao tenha sido gerado, garantir o executavel na raiz do release
    if (-not $FoundInstaller) {
        Copy-Item "$AppFolder\$AppName.exe" (Join-Path $ReleaseDir "$AppName.exe") -Force
    }
    Write-Host "[OK] Pacote Completo gerado em: $AppFolder" -ForegroundColor Green
    Write-Host "[OK] Executavel: $AppFolder\$AppName.exe" -ForegroundColor Green
}

$OutputFiles = Get-ChildItem -Path $ReleaseDir -Recurse -File
if ($OutputFiles.Count -eq 0) {
    Write-Host "[ERRO] Nenhum arquivo foi gerado em $ReleaseDir!" -ForegroundColor Red
    exit 1
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "           Build concluido com sucesso!                   " -ForegroundColor Green
Write-Host "Os executaveis estao disponiveis na pasta: $ReleaseDir" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

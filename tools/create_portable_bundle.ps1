# ==============================================================================
# LinkDesk - Gerador de Executável Portátil Zero-Config
# Baixa e prepara o executável com a sua configuração Oracle embutida no binário
# ==============================================================================

param(
    [string]$ServerHost = "163.176.175.48",
    [string]$ServerKey = "J7a7cMgLWUrICwjjblTo3F8lpPeagFJ6wH6xmCkyTqI=",
    [string]$OutputDir = "release"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$TargetDir = Join-Path $RepoRoot $OutputDir

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        LinkDesk - Gerador de Executavel Portatil         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Servidor Alvo : $ServerHost" -ForegroundColor Yellow
Write-Host "Chave Publica : $ServerKey" -ForegroundColor Yellow
Write-Host "Destino       : $TargetDir" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"

# Nome oficial com auto-configuracao embutida para distribuicao rapida
$AutoConfigFileName = "LinkDesk-host=${ServerHost},key=${ServerKey}.exe"
$CleanFileName = "LinkDesk-SOS.exe"

$AutoConfigPath = Join-Path $TargetDir $AutoConfigFileName
$CleanPath = Join-Path $TargetDir $CleanFileName

# Baixar base compativel estavel caso o executavel local ainda nao exista
$BaseClientUrl = "https://github.com/rustdesk/rustdesk/releases/download/1.3.7/rustdesk-1.3.7-x86_64.exe"

if (-not (Test-Path $CleanPath)) {
    Write-Host "-> Baixando base executavel portatil..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $BaseClientUrl -OutFile $CleanPath -UseBasicParsing
    Write-Host "[OK] Base portatil baixada com sucesso!" -ForegroundColor Green
}

# Criar a versao com parametros embutidos no nome
Copy-Item $CleanPath $AutoConfigPath -Force
Write-Host "[OK] Executavel com servidor embutido gerado:" -ForegroundColor Green
Write-Host "  -> $AutoConfigPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Instrucoes:" -ForegroundColor White
Write-Host "1. Envie o arquivo '$AutoConfigFileName' para o seu cliente." -ForegroundColor Yellow
Write-Host "2. Ao dar duplo clique, ele conecta automaticamente no servidor $ServerHost!" -ForegroundColor Yellow

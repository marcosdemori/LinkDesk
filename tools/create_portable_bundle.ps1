# ==============================================================================
# LinkDesk - Gerador de Executável Portátil Zero-Config
# Prepara o executável com a sua configuração Oracle embutida no binário ou nome
# ==============================================================================

param(
    [string]$ServerHost = "",
    [string]$ServerKey = "",
    [string]$OutputDir = "release"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$TargetDir = Join-Path $RepoRoot $OutputDir
$CredsFile = Join-Path $RepoRoot "SERVER_CREDENTIALS.local.md"

# Carregar credenciais locais se não fornecidas via parâmetro
if ((-not $ServerHost -or -not $ServerKey) -and (Test-Path $CredsFile)) {
    $CredsContent = Get-Content $CredsFile -Raw
    if (-not $ServerHost -and ($CredsContent -match 'IP Público:\s*`([^`]+)`')) {
        $ServerHost = $Matches[1].Trim()
    }
    if (-not $ServerKey -and ($CredsContent -match 'Public Key.*?:\s*`([^`]+)`')) {
        $ServerKey = $Matches[1].Trim()
    }
}

if (-not $ServerHost) { $ServerHost = "connect.linkdesk.io" }

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "        LinkDesk - Gerador de Executavel Portatil         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Servidor Alvo : $ServerHost" -ForegroundColor Yellow
Write-Host "Chave Publica : $(if ($ServerKey) { $ServerKey } else { '(Nao informada)' })" -ForegroundColor Yellow
Write-Host "Destino       : $TargetDir" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"

$CleanFileName = "LinkDesk-SOS.exe"
$AutoConfigFileName = if ($ServerKey) { "LinkDesk-host=${ServerHost},key=${ServerKey}-SOS.exe" } else { "LinkDesk-host=${ServerHost}-SOS.exe" }

$CleanPath = Join-Path $TargetDir $CleanFileName
$AutoConfigPath = Join-Path $TargetDir $AutoConfigFileName

# Verificar se existe binário compilado pelo repositório
$SourceCandidate = @(
    $CleanPath,
    (Join-Path $TargetDir "LinkDesk\LinkDesk.exe"),
    (Join-Path $RepoRoot "client\rustdesk_portable.exe"),
    (Join-Path $RepoRoot "client\flutter\build\windows\x64\runner\Release\LinkDesk.exe")
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $SourceCandidate) {
    Write-Host "[!] Executavel LinkDesk ainda nao compilado na pasta local." -ForegroundColor Yellow
    Write-Host "-> Verificando se ha artefato disponivel no GitHub Actions..." -ForegroundColor Cyan
    try {
        gh run download --name LinkDesk-Windows-Binaries --dir $TargetDir
        $SourceCandidate = $CleanPath
    } catch {
        Write-Host "[!] Nao foi possivel baixar automaticamente via gh CLI." -ForegroundColor Yellow
        Write-Host "Aguarde a conclusao do build no GitHub Actions ou compile localmente." -ForegroundColor Yellow
        exit 1
    }
}

if ($SourceCandidate -and ($SourceCandidate -ne $CleanPath) -and (Test-Path $SourceCandidate)) {
    Copy-Item $SourceCandidate $CleanPath -Force
}

# Criar a versao com parametros embutidos no nome para clientes SOS sem necessidade de arquivo de config
if (Test-Path $CleanPath) {
    Copy-Item $CleanPath $AutoConfigPath -Force
    Write-Host "[OK] Executavel Portatil LinkDesk Pronto!" -ForegroundColor Green
    Write-Host "  -> Portatil Padrao: $CleanPath" -ForegroundColor Cyan
    Write-Host "  -> Auto-Configurado: $AutoConfigPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Instrucoes:" -ForegroundColor White
    Write-Host "1. Distribua o arquivo para o suporte ou cliente." -ForegroundColor Yellow
    Write-Host "2. Ao abrir, ele conecta diretamente na sua VPS Oracle Cloud ($ServerHost)." -ForegroundColor Yellow
}

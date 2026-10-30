# ==============================================================================
# LinkDesk - Iniciar Servidor Local de Sinalizacao e Relay (Windows)
# Executa hbbs.exe e hbbr.exe localmente em background
# ==============================================================================

$ServerDir = $PSScriptRoot
$BinDir = Join-Path $ServerDir "bin"
$HbbsExe = Join-Path $BinDir "hbbs.exe"
$HbbrExe = Join-Path $BinDir "hbbr.exe"
$DataDir = Join-Path $ServerDir "data"

New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

# Descobrir IP local da rede (ex: 192.168.x.x) para testes entre duas maquinas locais
$LocalIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*", "Ethernet*" -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" } | Select-Object -ExpandProperty IPAddress -First 1)
if (-not $LocalIp) { $LocalIp = "127.0.0.1" }

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         LinkDesk - Iniciando Servidor Local              " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "IP Loopback  : 127.0.0.1"
Write-Host "IP na Rede   : $LocalIp (utilize este IP para conectar outro PC)"
Write-Host "Diretorio    : $DataDir"
Write-Host "----------------------------------------------------------"

# Finalizar instancias anteriores se estiverem rodando
Stop-Process -Name "hbbs", "hbbr" -ErrorAction SilentlyContinue

# Iniciar HBBR (Relay)
Write-Host "Iniciando hbbr.exe (Relay de Video)..." -ForegroundColor Yellow
Start-Process -FilePath $HbbrExe -ArgumentList "-k _" -WorkingDirectory $DataDir -WindowStyle Hidden

# Iniciar HBBS (Rendezvous / STUN)
Write-Host "Iniciando hbbs.exe (Registro de ID e STUN)..." -ForegroundColor Yellow
Start-Process -FilePath $HbbsExe -ArgumentList "-r $LocalIp`:21117 -k _" -WorkingDirectory $DataDir -WindowStyle Hidden

Start-Sleep -Seconds 2

# Obter chave publica gerada
$PubKeyFile = Join-Path $DataDir "id_ed25519.pub"
if (Test-Path $PubKeyFile) {
    $PubKey = (Get-Content $PubKeyFile -Raw).Trim()
} else {
    $PubKey = "(Aguardando geracao...)"
}

Write-Host "`n[OK] Servidor LinkDesk Local em Execucao!" -ForegroundColor Green
Write-Host "----------------------------------------------------------"
Write-Host "Host Local   : 127.0.0.1 (ou $LocalIp para rede local)" -ForegroundColor Green
Write-Host "Chave Publica: $PubKey" -ForegroundColor Yellow
Write-Host "Portas ativas: 21115 (STUN), 21116 (ID), 21117 (Relay)"
Write-Host "----------------------------------------------------------"
Write-Host "Para parar o servidor, execute: .\server\stop-local-server.ps1"
Write-Host "==========================================================" -ForegroundColor Cyan

# Atualizar configuracao do cliente para apontar para o servidor local
$RepoRoot = Split-Path -Parent $ServerDir
python "$RepoRoot\tools\configure_linkdesk.py" "LinkDesk" "127.0.0.1" "$PubKey"

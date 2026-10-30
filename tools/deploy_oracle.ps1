<#
.SYNOPSIS
    Deploy 100% automatizado do servidor LinkDesk na Oracle Cloud Infrastructure.

.EXAMPLE
    .\tools\deploy_oracle.ps1 -Ip 129.148.45.10 -KeyFile "$HOME\Downloads\ssh-key.key"
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "IP público da instância Oracle Cloud")]
    [string]$Ip,

    [Parameter(Mandatory = $true, HelpMessage = "Caminho do arquivo da chave SSH (.key ou .pem)")]
    [string]$KeyFile,

    [string]$User = "ubuntu"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       LinkDesk - Deploy Automático na Oracle Cloud       " -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Servidor Alvo : $Ip" -ForegroundColor Yellow
Write-Host "Usuario SSH   : $User" -ForegroundColor Yellow
Write-Host "Chave Privada : $KeyFile" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"

# 1. Verificar se a chave existe
if (-not (Test-Path $KeyFile)) {
    Write-Host "[ERRO] Arquivo de chave privada nao encontrado: $KeyFile" -ForegroundColor Red
    exit 1
}

$ResolvedKey = (Resolve-Path $KeyFile).Path

# 2. Ajustar permissoes da chave no Windows (evita erro 'Permissions are too open')
Write-Host "→ Ajustando permissoes de seguranca da chave SSH..." -ForegroundColor Gray
icacls "$ResolvedKey" /inheritance:r | Out-Null
icacls "$ResolvedKey" /grant:r "$($env:USERNAME):(R)" | Out-Null

# 3. Testar conectividade SSH com retry
Write-Host "→ Conectando a instancia Oracle Cloud ($Ip)..." -ForegroundColor Yellow
$MaxRetries = 12
$Connected = $false

for ($i = 1; $i -le $MaxRetries; $i++) {
    $test = ssh -i "$ResolvedKey" -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$User@$Ip" "echo OK" 2>$null
    if ($test -match "OK") {
        $Connected = $true
        Write-Host "✓ Conexao SSH estabelecida com sucesso!" -ForegroundColor Green
        break
    }
    Write-Host "  Instancia ainda inicializando... Aguardando 10s (tentativa $i/$MaxRetries)..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
}

if (-not $Connected) {
    Write-Host "[ERRO] Nao foi possivel conectar via SSH em $User@$Ip apos $MaxRetries tentativas." -ForegroundColor Red
    Write-Host "Verifique se a VM esta 'Em Execucao' e se a porta 22 (SSH) esta liberada na Security List da VCN." -ForegroundColor Yellow
    exit 1
}

# 4. Executar script de instalacao do LinkDesk no servidor
Write-Host "→ Clonando repositorio e configurando LinkDesk no servidor..." -ForegroundColor Yellow
$RemoteCmd = @'
set -e
sudo apt-get update -y
sudo apt-get install -y git curl
if [ -d "/opt/LinkDesk" ]; then
    cd /opt/LinkDesk && sudo git pull
else
    sudo git clone https://github.com/marcosdemori/LinkDesk.git /opt/LinkDesk
fi
cd /opt/LinkDesk/server
sudo bash setup.sh
'@

ssh -i "$ResolvedKey" -o StrictHostKeyChecking=no "$User@$Ip" "$RemoteCmd"

# 5. Capturar a Chave Publica do Servidor
Write-Host "→ Obtendo chave criptografica do servidor..." -ForegroundColor Yellow
$PubKey = ssh -i "$ResolvedKey" -o StrictHostKeyChecking=no "$User@$Ip" "sudo cat /opt/LinkDesk/server/data/id_ed25519.pub 2>/dev/null"

if ($PubKey -and $PubKey.Trim().Length -gt 10) {
    $PubKey = $PubKey.Trim()
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "✓ SERVIDOR LINKDESK INSTALADO COM SUCESSO NA ORACLE CLOUD!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "IP do Servidor : $Ip" -ForegroundColor Yellow
    Write-Host "Chave Publica  : $PubKey" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------"
    
    # 6. Injetar automaticamente no projeto local
    Write-Host "→ Atualizando configuracao local do LinkDesk..." -ForegroundColor Gray
    python tools/configure_linkdesk.py -s "$Ip" -k "$PubKey"
    
    Write-Host ""
    Write-Host "✓ Configuracao aplicada ao seu projeto!" -ForegroundColor Green
    Write-Host "Agora basta executar o build para gerar os executaveis apontando para sua Oracle Cloud." -ForegroundColor Cyan
} else {
    Write-Host "[!] Servidor iniciado, mas a chave publica nao pode ser lida automaticamente." -ForegroundColor Yellow
}

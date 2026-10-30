<#
.SYNOPSIS
    Deploy 100% automatizado do servidor LinkDesk na Oracle Cloud Infrastructure.

.EXAMPLE
    .\tools\deploy_oracle.ps1 -Ip 137.131.149.127 -KeyFile "D:\Projetos\_Ferramentas\SSH\Oracle\Privada.ppk"
#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "IP publico da instancia Oracle Cloud")]
    [string]$Ip,

    [Parameter(Mandatory = $true, HelpMessage = "Caminho do arquivo da chave SSH (.key, .pem ou .ppk)")]
    [string]$KeyFile,

    [string]$User = "ubuntu"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       LinkDesk - Deploy Automatico na Oracle Cloud       " -ForegroundColor White
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

# 1.1 Se for chave PuTTY (.ppk), converter automaticamente para OpenSSH (.key)
if ($ResolvedKey.EndsWith(".ppk", [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "-> Detectada chave em formato PuTTY (.ppk). Convertendo para OpenSSH..." -ForegroundColor Yellow
    $ConvertedKey = [System.IO.Path]::ChangeExtension($ResolvedKey, ".key")
    python tools/convert_ppk.py "$ResolvedKey" "$ConvertedKey"
    if (Test-Path $ConvertedKey) {
        $ResolvedKey = $ConvertedKey
        Write-Host "[OK] Utilizando chave OpenSSH convertida: $ResolvedKey" -ForegroundColor Green
    } else {
        Write-Host "[AVISO] Nao foi possivel converter .ppk automaticamente. Tentando prosseguir..." -ForegroundColor Yellow
    }
}

# 2. Ajustar permissoes da chave no Windows (evita erro 'Permissions are too open')
Write-Host "-> Ajustando permissoes de seguranca da chave SSH no Windows..." -ForegroundColor Gray
try {
    icacls "$ResolvedKey" /inheritance:r | Out-Null
    icacls "$ResolvedKey" /grant:r "$($env:USERNAME):(R)" | Out-Null
} catch {
    Write-Host "[AVISO] Nao foi possivel redefinir permissoes via icacls. Prosseguindo..." -ForegroundColor Yellow
}

# 3. Testar conectividade SSH com retry
Write-Host "-> Conectando a instancia Oracle Cloud ($Ip)..." -ForegroundColor Yellow
$MaxRetries = 15
$Connected = $false

for ($i = 1; $i -le $MaxRetries; $i++) {
    $test = ssh -i "$ResolvedKey" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 "$User@$Ip" "echo OK" 2>$null
    if ($test -match "OK") {
        $Connected = $true
        Write-Host "[OK] Conexao SSH estabelecida com sucesso!" -ForegroundColor Green
        break
    }
    Write-Host "  Instancia ainda inicializando... Tentativa $i/$MaxRetries (aguardando 5s)..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

if (-not $Connected) {
    Write-Host "[ERRO] Nao foi possivel conectar via SSH em $User@$Ip apos $MaxRetries tentativas." -ForegroundColor Red
    Write-Host "Dicas importantes:" -ForegroundColor Yellow
    Write-Host " 1. Verifique se a VM esta 'Executando' na Oracle." -ForegroundColor Yellow
    Write-Host " 2. Verifique se a porta 22 (SSH) esta liberada na Security List da VCN." -ForegroundColor Yellow
    Write-Host " 3. Certifique-se de que a chave privada corresponde a chave cadastrada na VM." -ForegroundColor Yellow
    exit 1
}

# 4. Executar script de instalacao do LinkDesk no servidor
Write-Host "-> Instalando dependencias e configurando o LinkDesk no servidor..." -ForegroundColor Yellow
$Cmd1 = "sudo apt-get update -y && sudo apt-get install -y git curl"
$Cmd2 = "if [ -d /opt/LinkDesk ]; then cd /opt/LinkDesk && sudo git pull; else sudo git clone https://github.com/marcosdemori/LinkDesk.git /opt/LinkDesk; fi"
$Cmd3 = "cd /opt/LinkDesk/server && sudo bash setup.sh $Ip"
$FullRemoteCmd = "$Cmd1 && $Cmd2 && $Cmd3"

ssh -i "$ResolvedKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$User@$Ip" $FullRemoteCmd

# 5. Capturar a Chave Publica do Servidor
Write-Host "-> Obtendo chave criptografica do servidor..." -ForegroundColor Yellow
$PubKey = ssh -i "$ResolvedKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$User@$Ip" "sudo cat /opt/LinkDesk/server/data/id_ed25519.pub 2>/dev/null"

if ($PubKey -and $PubKey.Trim().Length -gt 10) {
    $PubKey = $PubKey.Trim()
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "[OK] SERVIDOR LINKDESK INSTALADO COM SUCESSO NA ORACLE!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "IP do Servidor : $Ip" -ForegroundColor Yellow
    Write-Host "Chave Publica  : $PubKey" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------"
    
    # 6. Injetar automaticamente no projeto local
    Write-Host "-> Atualizando configuracao local do LinkDesk..." -ForegroundColor Gray
    python tools/configure_linkdesk.py "LinkDesk" "$Ip" "$PubKey"
    
    Write-Host ""
    Write-Host "[OK] Configuracao aplicada ao seu projeto!" -ForegroundColor Green
    Write-Host "Agora basta executar o build para gerar os executaveis apontando para sua Oracle Cloud." -ForegroundColor Cyan
} else {
    Write-Host "[AVISO] Servidor iniciado, mas a chave publica nao pode ser lida automaticamente." -ForegroundColor Yellow
}

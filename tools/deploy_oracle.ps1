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

$ErrorActionPreference = "Continue"

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

# 1.1 Se for chave PuTTY (.ppk), converter para OpenSSH no diretorio TEMP
if ($ResolvedKey.EndsWith(".ppk", [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "-> Detectada chave em formato PuTTY (.ppk). Convertendo para OpenSSH..." -ForegroundColor Yellow
    $TempKey = Join-Path $env:TEMP "linkdesk_oracle.key"
    if (Test-Path $TempKey) {
        try {
            icacls "$TempKey" /grant "$($env:USERNAME):(F)" | Out-Null
            Remove-Item $TempKey -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    $convertOut = python tools/convert_ppk.py "$ResolvedKey" "$TempKey"
    if (Test-Path $TempKey) {
        $ResolvedKey = $TempKey
        Write-Host "[OK] Chave convertida com sucesso para: $ResolvedKey" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Falha ao converter chave PuTTY: $convertOut" -ForegroundColor Red
        exit 1
    }
}

# 2. Ajustar permissoes de seguranca da chave no Windows (exigencia do OpenSSH)
Write-Host "-> Ajustando permissoes de seguranca da chave SSH..." -ForegroundColor Gray
try {
    icacls "$ResolvedKey" /inheritance:r | Out-Null
    icacls "$ResolvedKey" /grant:r "$($env:USERNAME):(R)" | Out-Null
} catch {
    Write-Host "[AVISO] Nao foi possivel redefinir permissoes via icacls. Prosseguindo..." -ForegroundColor Yellow
}

# 3. Testar conectividade SSH com diagnostico em tempo real
Write-Host "-> Conectando a instancia Oracle Cloud ($Ip)..." -ForegroundColor Yellow
$MaxRetries = 10
$Connected = $false

$SshArgs = @(
    "-i", "$ResolvedKey",
    "-o", "BatchMode=yes",
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-o", "ConnectTimeout=6"
)

for ($i = 1; $i -le $MaxRetries; $i++) {
    $rawOut = & ssh $SshArgs "$User@$Ip" "echo OK" 2>&1
    $outputStr = ($rawOut | Out-String).Trim()

    if ($outputStr -match "OK") {
        $Connected = $true
        Write-Host "[OK] Conexao SSH estabelecida com sucesso!" -ForegroundColor Green
        break
    }
    
    # Filtra avisos conhecidos do known_hosts para exibir apenas o motivo real
    $filteredMsg = ($outputStr -split "`r?`n" | Where-Object { $_ -notmatch "Permanently added" -and $_.Trim() -ne "" }) -join " "
    if (-not $filteredMsg) { $filteredMsg = "Aguardando resposta do servidor..." }
    
    Write-Host "  Tentativa $i/${MaxRetries} - $filteredMsg" -ForegroundColor DarkGray
    Start-Sleep -Seconds 4
}

if (-not $Connected) {
    Write-Host ""
    Write-Host "[ERRO] Nao foi possivel autenticar via SSH em $User@$Ip apos $MaxRetries tentativas." -ForegroundColor Red
    Write-Host "Verificacoes importantes:" -ForegroundColor Yellow
    Write-Host " 1. A instancia esta como 'Executando' na Oracle Cloud?" -ForegroundColor Yellow
    Write-Host " 2. A porta 22 (SSH) esta liberada nas Regras de Entrada da Security List da VCN?" -ForegroundColor Yellow
    Write-Host " 3. Se aparecer 'Permission denied (publickey)', a chave privada nao corresponde a cadastrada na VM." -ForegroundColor Yellow
    exit 1
}

# 4. Executar script de instalacao do LinkDesk no servidor
Write-Host "-> Instalando dependencias e configurando o LinkDesk no servidor..." -ForegroundColor Yellow
$Cmd1 = "sudo apt-get update -y && sudo apt-get install -y git curl"
$Cmd2 = "if [ -d /opt/LinkDesk ]; then cd /opt/LinkDesk && sudo git pull; else sudo git clone https://github.com/marcosdemori/LinkDesk.git /opt/LinkDesk; fi"
$Cmd3 = "cd /opt/LinkDesk/server && sudo bash setup.sh $Ip"
$FullRemoteCmd = "$Cmd1 && $Cmd2 && $Cmd3"

& ssh -i "$ResolvedKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$User@$Ip" $FullRemoteCmd

# 5. Capturar a Chave Publica do Servidor
Write-Host "-> Obtendo chave criptografica do servidor..." -ForegroundColor Yellow
$PubKey = & ssh -i "$ResolvedKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$User@$Ip" "sudo cat /opt/LinkDesk/server/data/id_ed25519.pub 2>/dev/null"

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

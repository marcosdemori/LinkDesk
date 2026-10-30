#!/usr/bin/env bash
# ==============================================================================
# LinkDesk - Script de Instalação e Inicialização da Infraestrutura de Servidores
# Suporta: Ubuntu 20.04+, Debian 11+, Rocky Linux, Amazon Linux 2023
# ==============================================================================

set -e

COLOR_GREEN="\033[0;32m"
COLOR_BLUE="\033[0;34m"
COLOR_YELLOW="\033[1;33m"
COLOR_RED="\033[0;31m"
COLOR_RESET="\033[0m"

echo -e "${COLOR_BLUE}=====================================================${COLOR_RESET}"
echo -e "${COLOR_BLUE}        LinkDesk - Configuração de Servidor          ${COLOR_RESET}"
echo -e "${COLOR_BLUE}=====================================================${COLOR_RESET}"

# 1. Obter o IP ou Domínio Público do Servidor
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "SEU_IP_OU_DOMINIO")
read -p "Informe o IP público ou Domínio do servidor [Padrão: $PUBLIC_IP]: " INPUT_HOST
HOST=${INPUT_HOST:-$PUBLIC_IP}

echo -e "${COLOR_GREEN}✓ Host configurado: $HOST${COLOR_RESET}"

# 2. Instalação do Docker se não estiver presente
if ! command -v docker &> /dev/null; then
    echo -e "${COLOR_YELLOW}→ Docker não encontrado. Instalando Docker...${COLOR_RESET}"
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

# 3. Verificar/Instalar Docker Compose Plugin
if ! docker compose version &> /dev/null; then
    echo -e "${COLOR_YELLOW}→ Instalando plugin docker-compose...${COLOR_RESET}"
    apt-get update && apt-get install -y docker-compose-plugin || yum install -y docker-compose-plugin
fi

# 4. Configurar Firewall (UFW se ativo)
if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
    echo -e "${COLOR_YELLOW}→ Liberando portas no UFW (21115-21119)...${COLOR_RESET}"
    ufw allow 21115/tcp
    ufw allow 21116/tcp
    ufw allow 21116/udp
    ufw allow 21117/tcp
    ufw allow 21118/tcp
    ufw allow 21119/tcp
    ufw reload
fi

# 5. Atualizar o docker-compose.yml com o host correto
mkdir -p data
sed -i "s/relay.linkdesk.local:21117/$HOST:21117/g" docker-compose.yml

# 6. Iniciar os Containers
echo -e "${COLOR_YELLOW}→ Baixando e iniciando os serviços LinkDesk (hbbs e hbbr)...${COLOR_RESET}"
docker compose up -d

# Aguardar geração das chaves criptográficas
echo -e "${COLOR_YELLOW}→ Aguardando inicialização do HBBS e geração de chaves...${COLOR_RESET}"
sleep 5

# 7. Exibir Chave Pública Criptográfica Gerada
PUB_KEY_FILE="./data/id_ed25519.pub"
if [ -f "$PUB_KEY_FILE" ]; then
    PUB_KEY=$(cat "$PUB_KEY_FILE")
    echo ""
    echo -e "${COLOR_GREEN}=====================================================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}✓ Servidor LinkDesk instalado e rodando com sucesso!${COLOR_RESET}"
    echo -e "${COLOR_GREEN}=====================================================${COLOR_RESET}"
    echo -e "Host / IP do Servidor : ${COLOR_YELLOW}$HOST${COLOR_RESET}"
    echo -e "Chave Pública (Key)   : ${COLOR_YELLOW}$PUB_KEY${COLOR_RESET}"
    echo -e "Portas utilizadas     : 21115-21119 (TCP) e 21116 (UDP)"
    echo -e "-----------------------------------------------------"
    echo -e "Cole estas credenciais no script de personalização do cliente:"
    echo -e "  Host : $HOST"
    echo -e "  Key  : $PUB_KEY"
    echo -e "${COLOR_GREEN}=====================================================${COLOR_RESET}"
else
    echo -e "${COLOR_YELLOW}Containers iniciados. A chave pública será criada em ./data/id_ed25519.pub em alguns instantes.${COLOR_RESET}"
    echo -e "Para visualizá-la, execute: cat ./data/id_ed25519.pub"
fi

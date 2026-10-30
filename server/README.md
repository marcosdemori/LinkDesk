# LinkDesk Server - Guia de Implantação e Infraestrutura

Este diretório contém os arquivos necessários para hospedar a infraestrutura privada de sinalização, NAT Traversal e Relay de vídeo do **LinkDesk**.

---

## 1. Arquitetura dos Servidores

O sistema é dividido em dois serviços fundamentais:

1. **`hbbs` (Heartbeat / Rendezvous / ID Server):**
   - Gerencia a conexão inicial e o registro do ID de cada computador.
   - Realiza testes de tipo de NAT (STUN) para permitir conexão direta **P2P** de baixíssima latência (< 5ms em rede local, < 25ms nacional).
   - Valida a chave pública para garantir que apenas os clientes da sua empresa/SaaS usem sua infraestrutura.
2. **`hbbr` (Relay Server):**
   - Ativado automaticamente quando as duas máquinas estão atrás de firewalls corporativos restritivos ou CGNAT móvel (4G/5G).
   - Faz o relay do fluxo de vídeo e comandos com criptografia ponta a ponta (E2EE) sem ter acesso ao conteúdo da tela.

---

## 2. Requisitos de Rede e Portas do Firewall

Certifique-se de liberar as seguintes portas no Security Group / Firewall do seu provedor (AWS, Oracle, DigitalOcean, etc.):

| Porta | Protocolo | Função |
| :--- | :--- | :--- |
| **`21115`** | TCP | Teste de tipo de NAT (STUN) |
| **`21116`** | TCP | Inicialização de sessão e perfuração de NAT |
| **`21116`** | **UDP** | Registro contínuo de ID e Heartbeat |
| **`21117`** | TCP | Relay de tráfego de vídeo e comandos |
| **`21118`** | TCP | WebSocket de sinalização (opcional - para cliente web no navegador) |
| **`21119`** | TCP | WebSocket de relay (opcional - para cliente web no navegador) |

---

## 3. Implantação Rápida (1 Comando via Docker)

No seu VPS Linux (Ubuntu, Debian, Rocky Linux ou Amazon Linux):

```bash
# 1. Clone ou envie os arquivos da pasta server/ para o VPS
mkdir -p /opt/linkdesk-server
cd /opt/linkdesk-server

# 2. Torne o script executável e execute:
chmod +x setup.sh
./setup.sh
```

O script cuidará de:
* Instalar o Docker e Docker Compose automaticamente;
* Configurar as regras de firewall (UFW);
* Criar e iniciar os containers `linkdesk-hbbs` e `linkdesk-hbbr`;
* Exibir a **Chave Pública Criptográfica (`id_ed25519.pub`)** gerada.

---

## 4. Recomendações de Provedores de Hospedagem

| Provedor | Custo Aproximado | Recomendação |
| :--- | :--- | :--- |
| **Oracle Cloud (Always Free)** | **Grátis** | Instância ARM Ampere (4 OCPUs, 24GB RAM) ou AMD x86. Excelente para começar sem custos. |
| **Hetzner Cloud** | ~€4.50 / mês | Servidores na Europa/EUA com tráfego generoso de 20TB e altíssima estabilidade. |
| **DigitalOcean / Linode** | \$4 a \$6 / mês | VPS básico de 1 vCPU / 1GB RAM em data centers nos EUA ou América Latina. |
| **AWS Lightsail** | \$3.50 a \$5 / mês | Instância simples com IP estático atribuível com 1 clique. |

---

## 5. Gerenciando os Serviços

```bash
# Ver status dos serviços
docker compose ps

# Visualizar logs em tempo real
docker compose logs -f

# Parar serviços
docker compose down

# Reiniciar serviços
docker compose restart
```

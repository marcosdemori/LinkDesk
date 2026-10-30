# Guia Completo de Instalação, Deploy e Execução - LinkDesk 🚀

Este documento contém o passo a passo completo para:
1. **Executar e testar localmente no seu computador (já em funcionamento)**
2. **Fazer o deploy da infraestrutura de servidores na nuvem (Oracle Cloud Always Free)**
3. **Instalar as ferramentas de desenvolvimento e compilar os executáveis (`LinkDesk-SOS.exe` e `LinkDesk.exe`)**

---

## 🟢 1. Servidor Local (Em Execução no seu PC)

Seu servidor local de sinalização e relay já está **rodando em background** neste momento!

### Informações da Sessão Local:
* **Host / IP Local:** `127.0.0.1` (ou `10.1.4.31` para outros computadores na mesma rede Wi-Fi/cabo)
* **Chave Pública (Key):** `k15lJvG9IeFvvkXvdXgo22zOpKJwFIpGZ8CtKmqHdV4=`
* **Portas em Operação:**
  * `21115` (TCP) - Teste de NAT / STUN
  * `21116` (TCP/UDP) - Heartbeat e Registro de IDs
  * `21117` (TCP) - Relay de Vídeo e Comandos
  * `21118` (TCP) - WebSocket de Sinalização

### Como Testar o Servidor Local Agora Mesmo:
Você já tem o aplicativo cliente do RustDesk instalado na máquina. Para testar sua rede privada local:
1. Abra o aplicativo cliente.
2. Clique no ícone de menu (3 pontinhos ou engrenagem) ao lado do seu ID > **Rede (Network)** > **Desbloquear configurações de rede**.
3. Preencha os campos:
   * **Servidor ID:** `127.0.0.1` (ou `10.1.4.31`)
   * **Servidor Relay:** `127.0.0.1` (ou `10.1.4.31`)
   * **Key:** `k15lJvG9IeFvvkXvdXgo22zOpKJwFIpGZ8CtKmqHdV4=`
4. Clique em **OK**.
5. Verifique a barra inferior do aplicativo: ela mudará para o status **🟢 Pronto (Ready)**, indicando que você está conectado diretamente ao **seu próprio servidor local**!

### Como Controlar o Servidor Local:
* **Parar o servidor local:**
  ```powershell
  powershell -File server\stop-local-server.ps1
  ```
* **Reiniciar o servidor local:**
  ```powershell
  powershell -File server\start-local-server.ps1
  ```

---

## ☁️ 2. Deploy na Nuvem (Oracle Cloud Always Free - 100% Gratuito)

Quando você quiser que o **LinkDesk** funcione pela internet em qualquer lugar do mundo (sem depender do seu PC ligado), siga os passos abaixo no painel da Oracle Cloud:

### Passo 1: Criar a Instância (VM)
1. No console da Oracle Cloud, acesse o menu **Compute > Instances > Create Instance**.
2. Defina o nome como `linkdesk-server`.
3. Em **Image and shape**:
   * **Image:** Clique em *Change Image* e selecione **Canonical Ubuntu 22.04 ou 24.04**.
   * **Shape:**
     * **Opção ARM (Recomendada):** `Ampere VM.Standard.A1.Flex` com 2 a 4 OCPUs e 12GB ou 24GB de RAM (**100% Sempre Grátis**).
     * **Opção AMD:** `VM.Standard.E2.1.Micro` com 1 OCPU e 1GB de RAM (**100% Sempre Grátis**).
4. Em **Add SSH keys**:
   * Clique em **Save Private Key** e salve o arquivo `.key` no seu computador.
5. Clique em **Create** e aguarde o status mudar para verde (*Running*). Copie o **Public IP Address**.

---

### Passo 2: Liberar o Firewall da Oracle Cloud (Security List)
> [!IMPORTANT]
> A Oracle Cloud bloqueia todas as portas externas por padrão. É indispensável liberar no painel:

1. Na página de detalhes da sua instância, clique na sua **Subnet** (ex: *subnet-2026xxxx*).
2. Clique na **Default Security List for...**.
3. Clique em **Add Ingress Rules** e crie 2 regras:
   * **Regra 1 (TCP):**
     * Source CIDR: `0.0.0.0/0`
     * IP Protocol: `TCP`
     * Destination Port Range: `21115-21119`
   * **Regra 2 (UDP):**
     * Source CIDR: `0.0.0.0/0`
     * IP Protocol: `UDP`
     * Destination Port Range: `21116`
4. Clique em **Add Ingress Rules**.

---

### Passo 3: Conectar via SSH e Rodar o Instalador
No PowerShell do seu computador:

```powershell
# Conectar no servidor remoto
ssh -i "C:\caminho\para\sua-chave.key" ubuntu@IP_PUBLICO_DA_ORACLE
```

Dentro do terminal do servidor Ubuntu, execute:

```bash
# 1. Criar pasta e baixar o setup automatizado
mkdir -p /opt/linkdesk && cd /opt/linkdesk
curl -fsSL https://raw.githubusercontent.com/rustdesk/rustdesk-server/master/docker-compose.yml -o docker-compose.yml 2>/dev/null || true

# 2. Se preferir enviar os arquivos deste repositório, basta copiar a pasta server/ para o VPS
# e executar:
chmod +x setup.sh
sudo ./setup.sh
```

O script cuidará de:
* Instalar o Docker e Docker Compose;
* Liberar as regras de firewall do Ubuntu (`ufw` e `iptables`);
* Iniciar os serviços `hbbs` e `hbbr`;
* Exibir sua **Chave Pública (`id_ed25519.pub`)**.

---

## 🛠️ 3. Injetando seu Servidor de Nuvem no Cliente

Assim que tiver o IP da Oracle Cloud e a nova chave pública gerada, atualize o cliente executando apenas um comando:

```powershell
python tools\configure_linkdesk.py "LinkDesk" "IP_OU_DOMINIO_DA_ORACLE" "SUA_NOVA_CHAVE_PUBLICA"
```

O script atualizará automaticamente o core em Rust (`config.rs`) e os metadados do executável Windows (`Runner.rc`).

---

## 💻 4. Configuração do Ambiente de Compilação no Windows

Para compilar o executável portátil (`LinkDesk-SOS.exe`) e o instalador (`LinkDesk.exe`) localmente:

### Passo 1: Instalar Rust & Cargo
Abra o PowerShell como **Administrador** e execute:
```powershell
winget install --id Rustlang.Rustup -e
rustup default stable-x86_64-pc-windows-msvc
```

### Passo 2: Instalar o Flutter SDK
No PowerShell:
```powershell
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", "User")
```

### Passo 3: Compilar com 1 Comando
Feche e abra novamente o terminal para carregar o novo PATH e execute:
```powershell
powershell -File build\build-windows.ps1
```

O script compilará a engine em Rust, construirá a interface Flutter e gerará os binários finais na pasta:
* `release/LinkDesk-SOS.exe` (Portátil para suporte rápido, estilo HopToDesk)
* `release/LinkDesk.exe` (Instalador completo com suporte a serviço do Windows)

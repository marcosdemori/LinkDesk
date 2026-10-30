# LinkDesk 🚀
### O Melhor do RustDesk + HopToDesk: Acesso Remoto de Alta Performance e Zero Fricção

O **LinkDesk** é uma solução moderna de suporte e acesso remoto projetada para **TI corporativa, ferramentas internas de suporte e provedores de SaaS comercial**.

Ele combina a robustez, aceleração de hardware e segurança criptográfica da **engine em Rust do RustDesk** com a simplicidade, experiência limpa e modelo zero-configuração do **HopToDesk**.

---

## 🎯 Por Que Esta Combinação?

| Desafio no Suporte Remoto | No RustDesk Comum | No HopToDesk | **No LinkDesk** |
| :--- | :--- | :--- | :--- |
| **Experiência do Cliente Final** | Muitas opções e menus que confundem usuários leigos | Interface compacta e simples de 9 dígitos | **Modo SOS / Quick Support**: Apenas ID, Senha de uso único e status visual. |
| **Configuração de Servidor** | Cliente precisa colar IP e Chave Pública manualmente | Servidores públicos compartilhados | **Servidores Privados Embutidos**: Zero configuração para o cliente, dados trafegam pela sua infraestrutura. |
| **Performance e Codecs** | Aceleração por GPU (NVENC/AMF/QSV) e suporte a AV1/H.265 | Codecs padrão com foco em baixo consumo | **Otimização Híbrida**: Máxima qualidade quando há GPU, compressão adaptativa em redes instáveis. |
| **Acesso Não Supervisionado** | Suporte a serviço do Windows com bypass de UAC | Focado em sessões assistidas pontuais | **Instalação em 1 Clique**: Funciona portátil ou como serviço de sistema permanente. |

---

## 📁 Estrutura do Repositório

```text
acesso-remoto/
├── client/                     # Código-fonte do cliente Desktop/Mobile
│   ├── libs/                   # Bibliotecas Rust (hbb_common, scrap, enigo, etc.)
│   ├── src/                    # Core da engine em Rust (E2EE, WebRTC, áudio, vídeo)
│   └── flutter/                # Interface visual moderna multiplataforma
│       ├── lib/desktop/pages/  # Telas (Home, Conexão, Suporte, Configuração)
│       └── windows/runner/     # Executável nativo Windows e metadados
├── server/                     # Infraestrutura privada de sinalização e relay
│   ├── docker-compose.yml      # Stack pronta de produção (hbbs + hbbr)
│   ├── setup.sh                # Script de instalação em 1 clique para VPS Linux
│   └── README.md               # Guia de implantação (AWS, Oracle, Hetzner, etc.)
├── tools/                      # Ferramentas de automação e personalização
│   └── configure_linkdesk.py   # Script de personalização de marca e servidores
└── README.md                   # Este documento
```

---

## ⚡ Guia Rápido

### 1. Configurando sua Marca e Servidores
Para personalizar o nome do aplicativo, o domínio do servidor e a chave criptográfica em todo o código-fonte com um único comando:

```bash
python tools/configure_linkdesk.py "LinkDesk" "connect.seudominio.com" "SUA_CHAVE_PUBLICA_AQUI"
```

### 2. Subindo a Infraestrutura de Servidores (VPS)
Em qualquer máquina virtual Linux (Ubuntu, Debian, AWS, Oracle Cloud Free Tier):

```bash
cd server/
chmod +x setup.sh
./setup.sh
```

O script instala o Docker, libera o firewall e gera sua **chave pública (`id_ed25519.pub`)** para fechar a criptografia ponta a ponta (E2EE).

---

## 🛡️ Segurança e Privacidade
* **Criptografia E2EE:** Todas as sessões utilizam **X25519** para troca de chaves e **ChaCha20-Poly1305** para o túnel de dados e vídeo.
* **Privacidade dos Dados:** Nenhum dado passa por servidores de terceiros. Seu servidor próprio apenas realiza o STUN/sinalização e, se necessário, o relay encriptado de pacotes.
* **Consentimento Granular:** O usuário remoto pode revogar permissões de mouse, teclado ou arquivos a qualquer momento na barra de sessão.

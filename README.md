<p align="center">
  <img src="docs/images/logo.png" alt="LinkDesk Logo" width="480">
</p>

<p align="center">
  <strong>Acesso Remoto Corporativo de Alta Performance, Baixa Latência e Zero Fricção</strong><br>
  <em>Unindo a robustez do core em Rust à simplicidade instantânea de suporte rápido</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Status-Cloud%20Online-22c55e?style=for-the-badge&logo=statuspage&logoColor=white" alt="Server Status">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android-1E40AF?style=for-the-badge&logo=windows&logoColor=white" alt="Platforms">
  <img src="https://img.shields.io/badge/Core-Rust%20%7C%20Tokio-DEA584?style=for-the-badge&logo=rust&logoColor=white" alt="Rust Core">
  <img src="https://img.shields.io/badge/UI-Flutter%203.24-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Encryption-E2EE%20ChaCha20--Poly1305-10b981?style=for-the-badge&logo=lock&logoColor=white" alt="Security">
</p>

---

## 📌 Visão Geral

O **LinkDesk** é uma plataforma de acesso e suporte remoto projetada para **TI corporativa, suporte técnico a clientes e operações SaaS privadas**. 

O projeto nasceu com uma proposta clara: acesso remoto sem gargalos nem configuração para o cliente final, com experiência de usuário minimalista e infraestrutura de servidores 100% própria e privada.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        INFRAESTRUTURA LINKDESK                        │
│                 Oracle Cloud Always Free (São Paulo)                   │
│          Google BBR Habilitado (Zero Lag & Máxima Fluidez)             │
│          hbbs (Rendezvous / STUN)   │   hbbr (Relay Criptografado)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Criptografia E2EE (X25519)
             ┌──────────────────────┴──────────────────────┐
             ▼                                             ▼
┌───────────────────────────┐               ┌───────────────────────────┐
│     CLIENTE SOS (LEIGO)   │   P2P Direto  │    MODO TÉCNICO / TI      │
│ • Executável Portátil     │◄─────────────►│ • Catálogo de Máquinas    │
│ • Zero Instalação         │   (Fallback   │ • Transferência de Arquivo│
│ • ID 9 dígitos + Senha    │    Relay BBR) │ • Terminal / Multimonitor │
│ • Servidor Embutido       │               │ • Acesso Não Supervision. │
└───────────────────────────┘               └───────────────────────────┘
```

---

## ⚡ Diferenciais

| Recurso / Aspecto | **LinkDesk** |
| :--- | :--- |
| **Engine & Performance** | **Core Rust com Tuning BBR e P2P nativo desbloqueado** |
| **Interface do Cliente** | **Modo SOS / Quick Support limpo + Alternador Técnico** |
| **Configuração de Servidor** | **100% Embutido de Fábrica**: Zero configuração para o cliente |
| **Distribuição** | **Binário Autônomo Portable + Suporte a Serviço permanente** |
| **Privacidade** | **Servidor Próprio e Privado**: Nenhum dado trafega por fora |

---

## 🛠️ Tecnologias Utilizadas

### 🦀 Core Engine & Multimídia (Rust)
* **Linguagem:** Rust (Edição 2021) com runtime assíncrono Tokio.
* **Captura de Tela:** DirectX Desktop Duplication (DXGI no Windows), PipeWire (Linux), ScreenCaptureKit (macOS).
* **Codecs de Vídeo:** Aceleração de hardware (NVIDIA NVENC, AMD AMF, Intel QuickSync) + Codecs de software AV1 (`libaom`), VP9/VP8 (`libvpx`), YUV (`libyuv`).
* **Áudio de Baixa Latência:** Codec Opus nativo (`magnum-opus` / `cpal` WASAPI).
* **Segurança Criptográfica:** Criptografia ponta a ponta (E2EE) com **X25519** (troca de chaves Diffie-Hellman), **Ed25519** (identidade de nós) e **ChaCha20-Poly1305** (cifra autenticada de fluxo de vídeo e comandos).

### 📱 Interface de Usuário (Flutter & C++)
* **Framework:** Flutter 3.24+ / Dart 3 com arquitetura declarativa.
* **Runner Nativo:** C++ Windows Runner integrado com `flutter_rust_bridge` via Foreign Function Interface (FFI).
* **Design System:** Material 3 Corporativo com paleta Azul Safira (#1D4ED8 / #0E1E4C), badges de status em tempo real e layout responsivo com visualização dual (SOS vs. Operador).

### ☁️ Infraestrutura & Rede (Servidor Privado)
* **Hospedagem:** Oracle Cloud Infrastructure (OCI Always Free), Região Brasil East (São Paulo).
* **Kernel Tuning:** Controle de congestionamento **Google BBR** (`net.ipv4.tcp_congestion_control = bbr`) com buffers TCP/UDP de 16 MB para eliminar bufferbloat e latência.
* **Orquestração:** Docker & Docker Compose com reinicialização resiliente (`restart: unless-stopped`).
* **Sinalização & P2P:** `linkdesk-hbbs` (STUN, NAT discovery e registro dinâmico de IDs).
* **Relay de Alta Velocidade:** `linkdesk-hbbr` (Fallback automático caso P2P seja bloqueado por firewalls estritos).

---

## 📦 Como Usar o LinkDesk

### Configuração de Clientes Manuais
1. Abra o aplicativo na sua máquina ou celular;
2. Vá em **Configurações** ➔ **Rede** ➔ **Desbloquear configurações de rede**;
3. Preencha com o IP/Domínio do seu servidor privado e a sua chave criptográfica;
4. Clique em **OK**. O status mudará imediatamente para 🟢 **Pronto (Ready)**.

> *Nota de Segurança: As credenciais privadas de conexão da sua infraestrutura ficam armazenadas no arquivo local `SERVER_CREDENTIALS.local.md` (ignorado pelo Git).*

---

## 🚀 Compilação e Build Automatizado

### Build na Nuvem (GitHub Actions)
O repositório inclui a pipeline [`.github/workflows/build-linkdesk.yml`](.github/workflows/build-linkdesk.yml) para compilar os binários Windows na infraestrutura do GitHub:
1. Vá na aba **Actions** no seu GitHub;
2. Selecione o workflow **Build LinkDesk Windows Release**;
3. Clique em **Run workflow**. Os executáveis finais são gerados e disponibilizados na aba de artefatos/releases.

### Build Local no Windows
Para compilar localmente na sua máquina:
```powershell
# 1. Configurar parâmetros do servidor
python tools/configure_linkdesk.py "LinkDesk" "SEU_IP_OU_DOMINIO" "SUA_CHAVE_PUBLICA"

# 2. Executar compilação do executável
powershell -ExecutionPolicy Bypass -File build/build-windows.ps1
```

---

## 🔒 Segurança e Privacidade

1. **Zero Coleta de Telemetria:** Diferente de soluções comerciais de mercado, o LinkDesk não coleta identificadores pessoais, IPs ou logs em servidores externos.
2. **Criptografia Ponta a Ponta:** Toda a transmissão de áudio, vídeo, teclado e mouse é criptografada e autenticada via AEAD ChaCha20-Poly1305.
3. **Controle Granular na Sessão:** O cliente que recebe o suporte pode habilitar/desabilitar permissões a qualquer momento na interface (desativar mouse, bloquear transferência de arquivos ou pausar vídeo).

---

## 📄 Licença

O LinkDesk é distribuído sob a licença **GNU AGPL-3.0** (veja [`client/LICENCE`](client/LICENCE)). Ele é uma obra derivada de software livre AGPL-3.0; os avisos de copyright originais são mantidos nos arquivos-fonte, como a licença exige, e o código-fonte completo está disponível neste repositório.

---

<p align="center">
  <sub>Desenvolvido com foco em alta performance, soberania de dados e estabilidade corporativa.</sub>
</p>

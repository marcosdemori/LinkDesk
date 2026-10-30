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

O projeto nasceu com uma proposta clara: eliminar os gargalos e as complexidades de configuração do RustDesk tradicional, incorporando a experiência de usuário minimalista e a transparência de rede do HopToDesk, com infraestrutura de servidores 100% própria e privada.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        INFRAESTRUTURA LINKDESK                        │
│                 Oracle Cloud Always Free (São Paulo)                   │
│         IP: 163.176.175.48  •  Google BBR Habilitado (Zero Lag)        │
│          hbbs (Portas 21115-21116)  │  hbbr (Portas 21117, 21119)      │
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

## ⚡ O Melhor dos 2 Mundos

| Recurso / Aspecto | RustDesk Oficial | HopToDesk | **LinkDesk (Híbrido)** |
| :--- | :--- | :--- | :--- |
| **Engine & Performance** | Core Rust com aceleração NVENC/AMF/QSV | P2P direto com menor consumo | **Core Rust com Tuning BBR e P2P nativo desbloqueado** |
| **Interface do Cliente** | Banners de aviso, menus e opções técnicas | Janela compacta com ID/Senha | **Modo SOS / Quick Support limpo + Alternador Técnico** |
| **Configuração de Servidor** | Exige digitar IP e colar Chave Pública | Rede pública compartilhada | **100% Embutido de Fábrica**: Zero configuração para o cliente |
| **Distribuição** | Instaladores tradicionais | Executável único portátil | **Binário Autônomo Portable + Suporte a Serviço permanente** |
| **Privacidade** | Servidores públicos na China/EUA | Servidores de terceiros | **Servidor Próprio e Privado**: Nenhum dado trafega por fora |

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

### ☁️ Infraestrutura & Rede (Servidor em Produção)
* **Hospedagem:** Oracle Cloud Infrastructure (OCI Always Free), Região Brasil East (São Paulo).
* **Kernel Tuning:** Controle de congestionamento **Google BBR** (`net.ipv4.tcp_congestion_control = bbr`) com buffers TCP/UDP de 16 MB para eliminar bufferbloat e latência.
* **Orquestração:** Docker & Docker Compose com reinicialização resiliente (`restart: unless-stopped`).
* **Sinalização & P2P:** `linkdesk-hbbs` (STUN, NAT discovery e registro dinâmico de IDs).
* **Relay de Alta Velocidade:** `linkdesk-hbbr` (Fallback automático caso P2P seja bloqueado por firewalls estritos).

---

## 🌐 Servidor em Produção (Oracle Cloud)

O servidor de infraestrutura do LinkDesk já se encontra ativo e operacional:

| Serviço | Parâmetro de Conexão |
| :--- | :--- |
| **Host / Servidor ID** | `163.176.175.48` |
| **Servidor Relay** | `163.176.175.48` |
| **Chave Pública (Key)** | `J7a7cMgLWUrICwjjblTo3F8lpPeagFJ6wH6xmCkyTqI=` |
| **Portas Utilizadas** | TCP `21115-21119` e UDP `21116` |
| **Status Atual** | 🟢 **Online & Operacional** (Latência ~5-15ms no Brasil) |

---

## 📦 Como Usar o LinkDesk

### Método 1: Executável Portátil Pré-Configurado (Recomendado para Clientes)
Na pasta [`release/`](release/), disponibilizamos os executáveis prontos para uso:
* **`LinkDesk-host=163.176.175.48,key=J7a7cMgLWUrICwjjblTo3F8lpPeagFJ6wH6xmCkyTqI=.exe`**:
  O usuário apenas dá duplo clique. O próprio executável faz a leitura das credenciais pelo nome e conecta instantaneamente ao seu servidor da Oracle Cloud com status 🟢 **Pronto**.
* **`LinkDesk-SOS.exe`**: Versão portátil limpa com a identidade visual LinkDesk.

### Método 2: Conectar qualquer cliente oficial ao seu Servidor Privado
1. Abra o aplicativo na sua máquina ou celular;
2. Vá em **Configurações** ➔ **Rede** ➔ **Desbloquear configurações de rede**;
3. Preencha:
   * **Servidor ID:** `163.176.175.48`
   * **Servidor Relay:** `163.176.175.48`
   * **Key:** `J7a7cMgLWUrICwjjblTo3F8lpPeagFJ6wH6xmCkyTqI=`
4. Clique em **OK**. O status mudará imediatamente para 🟢 **Pronto (Ready)**.

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
python tools/configure_linkdesk.py "LinkDesk" "163.176.175.48" "J7a7cMgLWUrICwjjblTo3F8lpPeagFJ6wH6xmCkyTqI="

# 2. Executar compilação do executável
powershell -ExecutionPolicy Bypass -File build/build-windows.ps1
```

---

## 🔒 Segurança e Privacidade

1. **Zero Coleta de Telemetria:** Diferente de soluções comerciais de mercado, o LinkDesk não coleta identificadores pessoais, IPs ou logs em servidores externos.
2. **Criptografia Ponta a Ponta:** Toda a transmissão de áudio, vídeo, teclado e mouse é criptografada e autenticada via AEAD ChaCha20-Poly1305.
3. **Controle Granular na Sessão:** O cliente que recebe o suporte pode habilitar/desabilitar permissões a qualquer momento na interface (desativar mouse, bloquear transferência de arquivos ou pausar vídeo).

---

<p align="center">
  <sub>Desenvolvido com foco em alta performance, soberania de dados e estabilidade corporativa.</sub>
</p>

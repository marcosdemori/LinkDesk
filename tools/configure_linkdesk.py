#!/usr/bin/env python3
"""
LinkDesk - Script de Customizacao de Marca e Configuracao de Servidores
Permite configurar o Nome do Aplicativo, Dominio/IP do Servidor de Sinalizacao (HBBS)
e a Chave Publica Criptografica de ponta a ponta (E2EE).
"""

import sys
import os
import re
import argparse

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIENT_DIR = os.path.join(ROOT_DIR, "client")
CONFIG_RS = os.path.join(CLIENT_DIR, "libs", "hbb_common", "src", "config.rs")
PORTABLE_CARGO = os.path.join(CLIENT_DIR, "libs", "portable", "Cargo.toml")
RUNNER_RC = os.path.join(CLIENT_DIR, "flutter", "windows", "runner", "Runner.rc")
PUBSPEC_YAML = os.path.join(CLIENT_DIR, "flutter", "pubspec.yaml")

def replace_in_file(file_path, pattern, replacement):
    if not os.path.exists(file_path):
        print(f"[!] Arquivo nao encontrado: {file_path}")
        return False
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    new_content, count = re.subn(pattern, replacement, content)
    if count > 0:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"[OK] Atualizado {os.path.basename(file_path)} ({count} substituicao(oes))")
        return True
    else:
        print(f"[-] Nenhuma ocorrencia encontrada para o padrao em {os.path.basename(file_path)}")
        return False

def configure(app_name="LinkDesk", server_host="connect.linkdesk.io", pub_key=""):
    print("=== Configurando LinkDesk ===")
    print(f"Nome do App       : {app_name}")
    print(f"Host do Servidor  : {server_host}")
    print(f"Chave Publica     : {pub_key if pub_key else '(Manter padrao temporario)'}")
    print("------------------------------------------")

    # 1. Configurar hbb_common/src/config.rs
    replace_in_file(
        CONFIG_RS,
        r'pub static ref APP_NAME:\s*RwLock<String>\s*=\s*RwLock::new\("[^"]*"\.to_owned\(\)\);',
        f'pub static ref APP_NAME: RwLock<String> = RwLock::new("{app_name}".to_owned());'
    )

    if server_host:
        replace_in_file(
            CONFIG_RS,
            r'pub const RENDEZVOUS_SERVERS:\s*&\[&str\]\s*=\s*&\["[^"]*"\];',
            f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{server_host}"];'
        )

    if pub_key:
        replace_in_file(
            CONFIG_RS,
            r'pub const RS_PUB_KEY:\s*&str\s*=\s*"[^"]*";',
            f'pub const RS_PUB_KEY: &str = "{pub_key}";'
        )

    # 2. Configurar Runner.rc (Windows Metadata)
    replace_in_file(
        RUNNER_RC,
        r'VALUE "ProductName", "[^"]*"',
        f'VALUE "ProductName", "{app_name}"'
    )
    replace_in_file(
        RUNNER_RC,
        r'VALUE "FileDescription", "[^"]*"',
        f'VALUE "FileDescription", "{app_name} Remote Access"'
    )

    # 3. Configurar Portable Packer metadata
    replace_in_file(
        PORTABLE_CARGO,
        r'ProductName = "[^"]*"',
        f'ProductName = "{app_name}"'
    )
    replace_in_file(
        PORTABLE_CARGO,
        r'FileDescription = "[^"]*"',
        f'FileDescription = "{app_name} Remote Desktop"'
    )
    replace_in_file(
        PORTABLE_CARGO,
        r'OriginalFilename = "[^"]*"',
        f'OriginalFilename = "{app_name}-SOS.exe"'
    )

    print("\n[OK] Configuracao aplicada com sucesso!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Configurador de parametros do LinkDesk")
    parser.add_argument("pos_name", nargs="?", default="LinkDesk", help="Nome do App")
    parser.add_argument("pos_host", nargs="?", default="connect.linkdesk.io", help="Host do Servidor")
    parser.add_argument("pos_key", nargs="?", default="", help="Chave Publica")
    parser.add_argument("-n", "--name", dest="name", help="Nome do App")
    parser.add_argument("-s", "--server", dest="server", help="Host do Servidor")
    parser.add_argument("-k", "--key", dest="key", help="Chave Publica")

    args = parser.parse_args()

    app_name = args.name or args.pos_name or "LinkDesk"
    server_host = args.server or args.pos_host or "connect.linkdesk.io"
    pub_key = args.key or args.pos_key or ""

    configure(app_name, server_host, pub_key)

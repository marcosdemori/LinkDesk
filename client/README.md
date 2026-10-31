# LinkDesk — Cliente

Código-fonte do aplicativo LinkDesk (Windows): núcleo em Rust (`src/`, `libs/`) e interface em Flutter (`flutter/`).

## Build

Use o script da raiz do repositório, que prepara o ambiente (Flutter, vcpkg, LLVM) e gera os executáveis em `release/`:

```powershell
powershell -ExecutionPolicy Bypass -File build/build-windows.ps1
```

Executáveis gerados:

- `LinkDesk-install.exe` — instalador (serviço do Windows, ícone na bandeja, acesso permanente)
- `LinkDesk-SOS.exe` — suporte avulso, sem instalação
- `LinkDesk.exe` — modo técnico portátil

## Estrutura

- `src/` — núcleo: conexão, captura de tela, entrada, serviço, instalação
- `libs/` — bibliotecas internas (protocolo e configuração em `hbb_common`, captura em `scrap`, entrada em `enigo`, empacotador portátil em `portable`)
- `flutter/` — interface desktop e mobile
- `src/lang/` — traduções

## Licença

Distribuído sob a **GNU AGPL-3.0** — veja [`LICENCE`](LICENCE). Este código é uma obra derivada de software livre AGPL-3.0; os avisos de copyright originais permanecem nos arquivos-fonte.

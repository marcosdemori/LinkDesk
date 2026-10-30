with open('build/build-windows.ps1', 'r', encoding='utf-8') as f:
    text = f.read()

target = '$CargoBin = Join-Path $env:USERPROFILE ".cargo\\bin"'
replacement = '''$CargoBin = "C:\\Users\\Marcos De Mori\\.cargo\\bin"
if (-not (Test-Path $CargoBin)) {
    $CargoBin = Join-Path $env:USERPROFILE ".cargo\\bin"
}'''

if target in text:
    text = text.replace(target, replacement)
    with open('build/build-windows.ps1', 'w', encoding='utf-8') as f:
        f.write(text)
    print("PATCH_OK")
else:
    print("TARGET_NOT_FOUND")

Set-Location "$PSScriptRoot\data"
Write-Host "Iniciando HBBR (Relay)..."
$hbbr = Start-Process -FilePath "..\bin\hbbr.exe" -ArgumentList "-k _" -PassThru
Write-Host "Iniciando HBBS (Rendezvous)..."
..\bin\hbbs.exe -r 127.0.0.1:21117 -k _

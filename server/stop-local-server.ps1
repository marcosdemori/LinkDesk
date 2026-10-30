# ==============================================================================
# LinkDesk - Parar Servidor Local (Windows)
# ==============================================================================

Write-Host "Parando servidores LinkDesk locais (hbbs e hbbr)..." -ForegroundColor Yellow

$Stopped = $false
Get-Process -Name "hbbs", "hbbr" -ErrorAction SilentlyContinue | ForEach-Object {
    Stop-Process -Id $_.Id -Force
    Write-Host "[OK] Finalizado processo $($_.Name) (PID: $($_.Id))" -ForegroundColor Green
    $Stopped = $true
}

if (-not $Stopped) {
    Write-Host "Nenhum servidor LinkDesk local em execucao." -ForegroundColor Gray
} else {
    Write-Host "[OK] Servidor local parado com sucesso." -ForegroundColor Green
}

# Eksport obu buildow webowych + detektor urzadzenia.
# Uzycie (z katalogu SCIM):
#   $env:GODOT_BIN = "C:\Users\stanp\Documents\GameDev\Godot\Godot_v4.6.3-stable_win64_console.exe"
#   .\tools\export_web.ps1
# Wynik: builds\web\  (index.html = detektor, d\ = desktop 16:9, m\ = mobile pion).
# Deploy: wgraj CALA zawartosc builds\web\ do katalogu /scim/ na hostingu
# (https://przystan.tech/scim/). Wymagane szablony eksportu Web w edytorze Godota.

$ErrorActionPreference = "Stop"

$godot = $env:GODOT_BIN
if (-not $godot) { throw "Ustaw GODOT_BIN (sciezka do binarki Godota)." }

$root = Split-Path -Parent $PSScriptRoot  # tools\ -> korzen projektu

New-Item -ItemType Directory -Force (Join-Path $root "builds\web\d") | Out-Null
New-Item -ItemType Directory -Force (Join-Path $root "builds\web\m") | Out-Null

Write-Host "== Eksport: Web (desktop 16:9) =="
& $godot --headless --path $root --export-release "Web" "builds/web/d/index.html"
if ($LASTEXITCODE -ne 0) { throw "Eksport 'Web' nie powiodl sie (kod $LASTEXITCODE)." }

Write-Host "== Eksport: Web Mobile (pion) =="
& $godot --headless --path $root --export-release "Web Mobile" "builds/web/m/index.html"
if ($LASTEXITCODE -ne 0) { throw "Eksport 'Web Mobile' nie powiodl sie (kod $LASTEXITCODE)." }

Write-Host "== Detektor urzadzenia =="
Copy-Item (Join-Path $root "tools\web\index.html") (Join-Path $root "builds\web\index.html") -Force

Write-Host "OK: builds\web\ gotowe (detektor + d + m). Wgraj na https://przystan.tech/scim/"

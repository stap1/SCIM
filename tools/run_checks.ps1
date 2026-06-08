# SCIM - runner kontroli jakosci (audyt P0.2): GUT + twardy error-scan.
# Zwraca exit 1, jesli: testy GUT padly LUB wykryto runtime SCRIPT ERROR
# (czego smoke GUT nie lapie - Godot konczy z exit 0 mimo bledow w _process).
# Uzycie:  pwsh tools/run_checks.ps1 [-Frames 600]
# Binarka Godota: zmienna srodowiskowa GODOT_BIN albo domyslnie ..\Godot\Godot_v4.6.3-stable_win64_console.exe

param([int]$Frames = 600)

$proj = Split-Path $PSScriptRoot -Parent
$godot = $env:GODOT_BIN
if (-not $godot) {
	$godot = Join-Path (Split-Path $proj -Parent) "Godot\Godot_v4.6.3-stable_win64_console.exe"
}
if (-not (Test-Path $godot)) {
	Write-Host "BLAD: nie znaleziono binarki Godota. Ustaw GODOT_BIN lub poloz ja w ..\Godot\." -ForegroundColor Red
	exit 2
}

# Tokeny realnych bledow. Celowo NIE matchujemy golego "ERROR"/"WARNING" - inaczej
# benignne komunikaty zamkniecia ("resources still in use at exit", "ObjectDB leaked")
# dawalyby false-positive.
$errPattern = 'SCRIPT ERROR|Parse Error|Nonexistent|Invalid (get|set|call)|null instance'
$failed = $false

function Scan([string]$label, [string[]]$lines) {
	$hits = $lines | Select-String -Pattern $errPattern
	if ($hits) {
		Write-Host "[$label] WYKRYTO BLEDY:" -ForegroundColor Red
		$hits | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
		$script:failed = $true
	} else {
		Write-Host "[$label] brak bledow" -ForegroundColor Green
	}
}

Write-Host "== Import =="
$imp = & $godot --headless --path $proj --import 2>&1 | ForEach-Object { "$_" }
Scan "import" $imp

Write-Host "== GUT (testy) =="
$gut = & $godot --headless --path $proj -s "res://addons/gut/gut_cmdln.gd" -gdir=res://test -gexit 2>&1 | ForEach-Object { "$_" }
$gutExit = $LASTEXITCODE
$gut | Select-String -Pattern "Tests|Passing|Failing|All tests|Asserts" | Select-Object -Last 6 | ForEach-Object { Write-Host "  $_" }
if ($gutExit -ne 0) {
	Write-Host "[gut] testy NIE przeszly (exit $gutExit)" -ForegroundColor Red
	$failed = $true
}
Scan "gut" $gut

Write-Host "== Smoke (gra, $Frames klatek) =="
$sm = & $godot --headless --path $proj --quit-after $Frames 2>&1 | ForEach-Object { "$_" }
Scan "smoke" $sm

if ($failed) {
	Write-Host "`nWYNIK: FAIL" -ForegroundColor Red
	exit 1
}
Write-Host "`nWYNIK: OK (GUT zielony, brak runtime errors)" -ForegroundColor Green
exit 0

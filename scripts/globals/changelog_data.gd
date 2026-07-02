class_name ChangelogData
extends RefCounted

# Historia zmian gry - JEDNO zrodlo prawdy o wersji i changelogu.
# Najnowszy wpis na GORZE listy (ENTRIES[0]). Biezaca wersja = wersja najnowszego wpisu.
# Same dane + czyste funkcje formatujace (bez zaleznosci od drzewa scen) - latwo testowalne.

const FALLBACK_VERSION := "0.0.0"

# Kazdy wpis: {"version": String, "date": String (YYYY-MM-DD), "changes": Array[String]}.
# Dopisujac nowa wersje - dodaj ja na POCZATKU tej listy. Teksty zmian sa widoczne
# w grze - pisz je z polskimi znakami, jak reszte UI.
const ENTRIES: Array[Dictionary] = [
	{
		"version": "1.0.0",
		"date": "2026-06-30",
		"changes": [
			"Pierwsze publiczne wydanie gry.",
			"Ikona gry zamiast logo Godota (karta przeglądarki i ekran ładowania).",
			"Jawnie ustawiona rozdzielczość bazowa 1152x648 i vsync.",
			"Lokalne najlepsze wyniki z wpisywaniem pseudonimu (do 20 znaków).",
			"Ekran historii zmian oraz numer wersji w rogu menu.",
		],
	},
	{
		"version": "0.9.0",
		"date": "2026-06-24",
		"changes": [
			"Runda audio: dynamiczny ambient (morze w menu, burza w grze).",
			"Przestrojony mikser dźwięku i nowe efekty (SFX) oraz muzyka menu.",
		],
	},
	{
		"version": "0.8.0",
		"date": "2026-06-21",
		"changes": [
			"Warstwa narracji Santiago i kwestie reagujące na rozgrywkę.",
			"Meta-progresja: punkty i ulepszenia trwałe między sesjami.",
			"Spawn wagowy wrogów i koniec sesji świadomy walki z bossem.",
			"Pełna nawigacja menu klawiaturą.",
		],
	},
]

# Czysta funkcja: biezaca wersja = wersja najnowszego wpisu (lub fallback gdy pusto).
static func current_version() -> String:
	if ENTRIES.is_empty():
		return FALLBACK_VERSION
	return str(ENTRIES[0].get("version", FALLBACK_VERSION))

# Czysta funkcja: cala historia jako tekst, najnowsze na gorze. Format:
#   vX.Y.Z  -  DATA
#     - zmiana
static func format_all() -> String:
	var blocks: Array[String] = []
	for entry in ENTRIES:
		blocks.append(format_entry(entry))
	return "\n\n".join(blocks)

# Czysta funkcja: pojedynczy wpis jako tekst.
static func format_entry(entry: Dictionary) -> String:
	var header := "v%s  -  %s" % [str(entry.get("version", "?")), str(entry.get("date", "?"))]
	var lines: Array[String] = [header]
	for change in entry.get("changes", []):
		lines.append("    - " + str(change))
	return "\n".join(lines)

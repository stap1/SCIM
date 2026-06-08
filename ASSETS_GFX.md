# SCIM - Specyfikacja assetów GFX

**Cel:** jedno źródło prawdy dla docelowej grafiki gry (właściciel: Stanisław). Lista obejmuje **komplet** assetów wczytywanych przez grę - łącznie z obecnymi placeholderami oznaczonymi jako "do wymiany". Wywodzi się z `AUDIT.md` (sekcja 3, pozycje G1 - G4).

**Data:** 2026-06-08 · **Styl:** cartoon / malarski (rastrowy, cieniowany).

---

## Konwencje techniczne

- **Format:** PNG, RGBA (kanał alpha = przezroczystość), bez interlace. Web-friendly (CLAUDE.md: brak MP4/video, cząsteczki na CPUParticles2D).
- **Skala autoryzacji:** rysuj w **2x** wymiaru ekranowego, w grze sprite skalowany w dół. W tabelach: **1x** = rozmiar na ekranie przy bazie 1152x648, **2x** = rozmiar pliku do dostarczenia.
- **Bazowa rozdzielczość gry:** 1152x648, kamera śledzi łódź (bez mocnego zoomu).
- **Orientacja sprite'ów ruchomych:** "do góry" (nos/przód ku górze ekranu, rotacja 0). Kod obraca węzeł w stronę ruchu/celu - nie wpisuj rotacji w teksturę.
- **Środek (pivot):** geometryczny środek tekstury (węzły Sprite2D centrują domyślnie).
- **Tło:** wyłącznie przezroczyste (alpha), żadnego białego/jednolitego tła.
- **Paleta:** spójna morska tonacja (shader wody: granat #2A4A6B / fala #356087). Wrogowie i pociski mają kontrastować z wodą (czytelność przy dziesiątkach obiektów).
- **Ścieżka docelowa:** `res://assets/` (GFX), import Godota z filtrowaniem liniowym (gładkie skalowanie dla stylu malarskiego).

## Legenda

- **Ważność** (względem buildu prezentowalnego/oddawalnego, nie samego eksportu): **Krytyczny** - placeholder rażąco psuje odbiór · **Wysoki** - wyraźnie widać wersję roboczą · **Średni** - zauważalne, ale znośne · **Niski** - kosmetyka / poza rozgrywką.
- **Status:** `wymiana` - istnieje placeholder do zastąpienia · `brak` - do narysowania od zera · `reuse` - może użyć innego assetu.

---

## A. Postacie i obiekty gry

| Plik | 1x (ekran) | 2x (dostawa) | Opis | Ważność | Częstość | Status |
|---|---|---|---|---|---|---|
| `boat.png` | 64x128 | 128x256 | Łódź gracza widziana z góry, dziób ku górze. Mała łódź rybacka/motorówka, czytelna sylwetka. Zastępuje `lodz.svg.svg`. | Krytyczny | Ciągła (1 na ekranie, zawsze w centrum) | wymiana |
| `enemy_jellyfish.png` | 64x64 | 128x128 | Meduza - podstawowy, najliczniejszy wróg. Miękka, galaretowata, lekko świecąca. Zastępuje `meduza.svg.svg`. | Krytyczny | Bardzo częsta (dziesiątki, od startu) | wymiana |
| `enemy_barracuda.png` | 96x48 | 192x96 | Barakuda - szybki, wydłużony drapieżnik. Smukła sylwetka, agresywny akcent. Dziś: meduza z `modulate`. | Wysoki | Częsta (od minuty 1) | brak |
| `enemy_shark.png` | 128x96 | 256x192 | Rekin - duży, wolniejszy, wytrzymały (HP 40). Masywna sylwetka, wyraźny kontur. Dziś: meduza z `modulate`. | Wysoki | Średnia (od minuty 2) | brak |
| `miniboss_motorboat.png` | 128x256 | 256x512 | Mini-boss "Motorówka kłusownika" - duża, groźna jednostka z silnikiem. Widok z góry, dziób ku górze. Dziś: przeskalowana łódź gracza (rażące). | Wysoki | Raz na sesję (~4:30) | brak |
| `xp_orb.png` | 24x24 | 48x48 | Świecący orb XP wypadający z wroga. Mały, jasny, "do zebrania" (np. perła/bąbel energii). Dziś: ikona aplikacji `icon.svg`. | Wysoki | Bardzo częsta (drop z każdego wroga) | wymiana |
| `harpoon.png` | 16x64 | 32x128 | Harpun - pocisk auto-ataku. Cienki, ostry grot na lince, czytelny w locie. Zastępuje `harpun.svg.svg`. | Wysoki | Bardzo częsta (pula 20, ostrzał co ~0.8 s) | wymiana |
| `heal_plank.png` | 48x24 | 96x48 | Dryfująca deska do łatania kadłuba (heal pickup, +25 HP). Drewniana, lekko spękana, czytelnie "do złapania". Dziś placeholder Polygon2D (brązowy prostokąt). | Wysoki | Co ~25 s (jedna naraz) | brak |

## B. UI - ikony

Ikony kart ulepszeń (G2): po jednej na każde z 6 ulepszeń z `Upgrades.UPGRADES`. Wyświetlane na ekranie level-up (3 losowe karty). Dziś karty są tekstowe (`Card0/1/2` to przyciski z `Label`).

| Plik | 1x (ekran) | 2x (dostawa) | Opis | Ważność | Częstość | Status |
|---|---|---|---|---|---|---|
| `upgrade_faster_attack.png` | 96x96 | 192x192 | "Szybszy harpun" - atak częściej (np. harpun z motion-blur / zegar). | Średni | Co level-up (ekran wyboru) | brak |
| `upgrade_longer_range.png` | 96x96 | 192x192 | "Dłuższy zasięg" - +20% zasięgu (np. celownik/promień). | Średni | Co level-up | brak |
| `upgrade_tougher_hull.png` | 96x96 | 192x192 | "Mocniejszy kadłub" - +30 HP (np. tarcza/pancerz łodzi). | Średni | Co level-up | brak |
| `upgrade_faster_boat.png` | 96x96 | 192x192 | "Szybsza łódź" - +20% prędkości (np. śruba/fala prędkości). | Średni | Co level-up | brak |
| `upgrade_resource_magnet.png` | 96x96 | 192x192 | "Magnes na zasoby" - +40% zasięgu zbierania XP (np. magnes + orb). | Średni | Co level-up | brak |
| `upgrade_double_harpoon.png` | 96x96 | 192x192 | "Podwójny harpun" - atak na 2 wrogów (np. dwa groty). | Średni | Co level-up | brak |
| `hud_ammo_icon.png` | 32x32 | 64x64 | Ikona amunicji w HUD (licznik harpunów). Może użyć `harpoon.png`. | Niski | Ciągła (HUD) | reuse |
| `app_icon.png` | 128x128 | 256x256 | Ikona aplikacji / kafelek web. Poza rozgrywką. Dziś `icon.svg`. | Niski | Poza grą (launcher/web) | wymiana |

## C. Tło i efekty

| Plik | 1x (ekran) | 2x (dostawa) | Opis | Ważność | Częstość | Status |
|---|---|---|---|---|---|---|
| `water_noise.png` | 512x512 (kafel) | 1024x1024 | **Bezszwowa, kafelkowalna** tekstura szumu wody (grayscale wystarczy). Źródło fal dla `shaders/water.gdshader` zamiast proceduralnego `sin/cos`. Miękki, organiczny noise (Perlin/Simplex lub ręcznie malowany). | Wysoki | Ciągła (całe tło) | brak |
| `water_normal.png` *(opcjonalnie)* | 512x512 (kafel) | 1024x1024 | Opcjonalna mapa normalnych dla głębszego efektu fal/refleksów. Bezszwowa. | Niski | Ciągła (tło) | brak |
| `telegraph_charge.png` | 256x256 | 512x512 | Wizualny telegraf szarży mini-bossa (G4) - kierunkowa smuga/ostrzeżenie lub czerwony błysk-reflektor, tryb additive. Pokazywany tuż przed szarżą bossa. | Średni | W walce z bossem (przed każdą szarżą, ~co 3 s) | brak |

---

## Uwagi wdrożeniowe (kontekst dla artysty, nie zadania GFX)

- **Woda (`water_noise.png`):** obecny `shaders/water.gdshader` nie ma samplera tekstury - dorysowanie samej tekstury wymaga dodania `uniform sampler2D` i wpięcia (zadanie programistyczne, audyt G3). Tekstura musi być idealnie kafelkowalna (krawędzie bez szwu).
- **Telegraf (`telegraph_charge.png`):** logika szarży jest w `motor_boat.gd` (`_on_charge`); wyświetlenie telegrafu to oddzielne zadanie kodu (audyt P2.8 / G4). Asset = sama grafika ostrzeżenia.
- **Co NIE jest assetem GFX:** błysk śmierci (`death_burst`) i podobne efekty używają **CPUParticles2D** (proceduralne, bez tekstury) - zgodnie z ograniczeniem web. Nie trzeba rysować.
- **Per-typ wrogów:** barakuda i rekin nadpisują rozmiar/HP w swoich scenach `.tscn`; docelowe sprite'y powinny mieć proporcje zgodne z podanymi wymiarami 1x (kolizja: meduza/barakuda r≈14, rekin r≈40, boss r≈20).
- **Po dostarczeniu:** podmiana wymaga aktualizacji `ext_resource` w scenach (`boat.tscn`, `enemy.tscn`, `barracuda.tscn`, `shark.tscn`, `motor_boat.tscn`, `xp_orb.tscn`, `harpoon.tscn`, `hud.tscn`) - przejście z `.svg` na `.png` zmienia ścieżki.

*Dokument żywy - aktualizować wraz z realizacją assetów. Źródło priorytetów: `AUDIT.md` (sekcja 3, G1 - G4).*

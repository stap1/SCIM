# SCIM - Specyfikacja assetów audio (SFX + muzyka + ambient)

**Cel:** jedno źródło prawdy dla docelowego dźwięku gry (właściciel: Mateusz). Mimo nazwy "SFX" plik obejmuje **całe audio** wczytywane lub przewidziane przez kod: efekty dźwiękowe, muzykę i ambient. Wywodzi się z `AUDIT.md` (sekcja 3, pozycje S1 - S3).

**Data:** 2026-06-08.

---

## Konwencje techniczne

- **Format docelowy:** **OGG Vorbis** (CLAUDE.md: audio w OGG, nie WAV - rozmiar i kompatybilność web). Bez MP4/wideo, bez wątków.
- **Kanały:** SFX - **mono**; muzyka i ambient - **stereo**.
- **Próbkowanie:** 44.1 kHz. Jakość Vorbis: SFX ~q5, muzyka/ambient ~q6 (kompromis jakość/rozmiar web).
- **Pętle:** muzyka i ambient muszą być **bezszwowe** (seamless loop) - bez kliknięć i ciszy na złączeniu; krótki fade na brzegach, jeśli trzeba. SFX to one-shoty (bez pętli).
- **Głośność / normalizacja:** SFX szczyt ≈ -3 dBFS; muzyka i ambient ≈ -14 LUFS (zintegrowane), spójnie między utworami. Bez przesterów i trzasków na końcach.
- **Ścieżki docelowe:** SFX `res://audio/sfx/`, muzyka `res://audio/music/`, ambient `res://audio/ambient/`.
- **Magistrale (busy):** `SFX`, `Music`, `Ambient`, `Master` (w `default_bus_layout.tres`). AudioManager kieruje dźwięki na właściwy bus; głośność Music/SFX sterowana suwakami z ustawień.

## Legenda

- **Ważność** (względem buildu prezentowalnego/oddawalnego): **Krytyczny** · **Wysoki** - wyraźny brak feedbacku/klimatu · **Średni** - zauważalne · **Niski** - kosmetyka.
- **Status:** `jest (WAV)` - istnieje placeholder WAV do konwersji na OGG (S1) · `brak` - cichy placeholder w kodzie, do nagrania (S2/S3).

---

## A. SFX - efekty dźwiękowe

Nazwy SFX są **kontraktem z kodem** - `audio_manager.gd` mapuje dokładnie te klucze (`SFX_PATHS`). Plik OGG podpinamy pod istniejący klucz.

| Plik (klucz) | Długość | Kanały | Opis | Ważność | Częstość | Status |
|---|---|---|---|---|---|---|
| `harpoon_shot.ogg` (`harpoon_shot`) | 0.10 - 0.25 s | mono | Wystrzał harpuna - krótkie, suche "thwip"/świst wyrzutu. | Średni | Bardzo częsta (auto-atak co ~0.8 s, do 2x) | jest (WAV) |
| `hit.ogg` (`hit`) | 0.08 - 0.20 s | mono | Trafienie wroga pociskiem - mokre "thunk"/uderzenie. Kluczowy feedback celności; dziś **cisza**. | Wysoki | Bardzo częsta (każde trafienie) | brak |
| `enemy_death.ogg` (`enemy_death`) | 0.20 - 0.40 s | mono | Śmierć wroga - plusk/"pop" rozprysku. | Średni | Częsta (każdy zabity wróg, dziesiątki/min) | jest (WAV) |
| `level_up.ogg` (`level_up`) | 0.6 - 1.2 s | mono/stereo | Awans poziomu - pozytywny, nagradzający chime/jingle. Dziś cisza. | Wysoki | Okazjonalna (co awans) | brak |
| `game_over.ogg` (`game_over`) | 1.0 - 2.0 s | stereo | Koniec gry - poważny, domykający akcent (sting). Dziś cisza. | Średni | Raz na sesję | brak |
| `boss_spawn.ogg` (`boss_spawn`) | 1.0 - 2.0 s | stereo | Nadejście mini-bossa - złowrogi róg/alarm budujący napięcie. Gra na sygnał `boss_incoming` (~2 s przed bossem). Dziś cisza. | Wysoki | Raz na sesję (~4:30) | brak |

## B. Muzyka

Kod ma gotowe `play_music(track)` i `crossfade_to(track, duration)` oraz bus `Music`, ale **muzyka nie jest jeszcze wpięta** (audyt P2.7 / S3). Pliki bezszwowe (loop).

| Plik | Długość (pętla) | Kanały | Opis | Ważność | Częstość | Status |
|---|---|---|---|---|---|---|
| `music_menu.ogg` | 30 - 60 s | stereo | Motyw menu - spokojny, morski, lekki. Pętla w tle `MainMenu`. | Średni | Ciągła (w menu) | brak |
| `music_game.ogg` | 60 - 120 s | stereo | Motyw rozgrywki - rytmiczny, napędzający, niemęczący przy długiej sesji. Pętla podczas gry. | Wysoki | Ciągła (cała rozgrywka) | brak |
| `music_boss.ogg` | 45 - 90 s | stereo | Motyw mini-bossa - intensywny, dramatyczny. **Cel `crossfade_to`** przy `boss_incoming`. Pętla do końca walki/sesji. | Średni | Od pojawienia bossa do końca | brak |

## C. Ambient

Bus `Ambient` istnieje, odtwarzacz ambientu jest tworzony w `AudioManager`, ale ścieżka nie jest jeszcze wpięta.

| Plik | Długość (pętla) | Kanały | Opis | Ważność | Częstość | Status |
|---|---|---|---|---|---|---|
| `ambient_sea.ogg` | 20 - 40 s | stereo | Tło morza - delikatny szum fal i wiatru, bezszwowa pętla pod muzyką. Buduje klimat akwenu. | Średni | Ciągła (cała rozgrywka) | brak |

---

## Uwagi wdrożeniowe (kontekst dla dźwiękowca)

- **Kontrakt nazw SFX:** klucze w `audio_manager.gd > SFX_PATHS` to: `harpoon_shot`, `hit`, `enemy_death`, `level_up`, `game_over`, `boss_spawn`. Po dostarczeniu OGG wystarczy podmienić ścieżkę przy odpowiednim kluczu (puste `""` = dziś cichy placeholder).
- **Graceful fallback:** brak pliku nie wywala gry (AudioManager gra ciszę) - można dostarczać pliki pojedynczo.
- **Konwersja S1:** `harpoon_shot` i `enemy_death` mają dziś WAV (`GameFX_Shoot_01_fx_BANDLAB.wav`, `enemy_death.wav`) - docelowo OGG (te same klucze).
- **Wpięcie muzyki/ambientu** (`play_music`/`crossfade_to`, bus Ambient) to oddzielne zadania programistyczne (audyt P2.7) - tu specyfikujemy same pliki audio.
- **SFX pool:** efekty grane są przez pulę round-robin (do 8 naraz) - krótkie, nienakładające się "ogony" brzmią najlepiej przy gęstej akcji.

*Dokument żywy - aktualizować wraz z realizacją audio. Źródło priorytetów: `AUDIT.md` (sekcja 3, S1 - S3).*

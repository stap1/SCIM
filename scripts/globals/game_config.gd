extends Node

# GameConfig - JEDYNE zrodlo prawdy o BALANSIE gry (autoload tylko-const).
# Zmiana liczby balansu = zmiana TUTAJ, nie w 10 plikach (audyt P1.3, E1).
#
# Zasady:
#  - Wylacznie `const` (zero stanu, zero logiki) - balans jest niemutowalny w czasie gry.
#  - Wartosci sa AS-BUILT (zgodne z dotychczasowym zachowaniem gry), nie ze SCIM_TECH_SPEC
#    (hybryda: kod jako baza). Spec bywa rozjechany z gra - tu liczy sie rzeczywistosc.
#  - Skrypty gry czytaja stad swoje wartosci startowe (@export default = GameConfig.X),
#    co pozostawia mozliwosc per-instancyjnego tweaku w inspektorze/scenie.
#  - GameConfig jest PIERWSZYM autoloadem - inne autoloady (np. GameState) moga go czytac
#    juz w inicjalizatorach pol.
#
# UWAGA: progu XP (xp_threshold) celowo TU NIE ma - to czysta, przetestowana funkcja
# w GameState (zrodlo prawdy o stanie sesji). GameConfig pozostaje tylko-const.

# --- Gracz (lodz) ---
const PLAYER_MAX_HP: float = 100.0
const PLAYER_MAX_SPEED: float = 200.0
const PLAYER_ACCELERATION: float = 600.0
const PLAYER_FRICTION: float = 700.0
const PLAYER_ROTATION_SPEED: float = 5.0
# Obrazenia gracza na kontakt - FALLBACK, gdy zrodlo nie niesie wlasnej wartosci.
# Wlasciwe obrazenia sa PER-WROG (contact_damage w EnemyBase) - patrz nizej.
const PLAYER_CONTACT_DAMAGE: float = 10.0
# i-frames: minimalny odstep miedzy kolejnymi trafieniami gracza.
const PLAYER_HIT_COOLDOWN: float = 0.5

# --- Sterowanie (tryby i router w ControlModes; tu wylacznie liczby) ---
# Martwa strefa celu podrozy (click-to-follow / follow-touch): lodz staje przy celu.
const CONTROL_TARGET_DEADZONE_PX: float = 12.0
# Martwa strefa follow-cursor - wieksza, by lodz nie wibrowala pod kursorem.
const CONTROL_CURSOR_DEADZONE_PX: float = 24.0
# Martwa strefa galki joysticka ekranowego [0,1].
const CONTROL_JOYSTICK_DEADZONE: float = 0.2
# Promien bazy joysticka ekranowego (px ekranu).
const TOUCH_JOYSTICK_RADIUS_PX: float = 70.0
# Build pionowy (mobile): kamera lekko oddalona - podobny obszar gry co na desktopie.
const CAMERA_ZOOM_MOBILE: float = 0.85

# --- Kilwater (WakeTrail - dwa slady w "V" za poruszajacymi sie jednostkami) ---
# Prog predkosci, od ktorego smuga sie tworzy.
const WAKE_MIN_SPEED: float = 25.0
# Zycie czastki smugi (stale): dlugosc sladu = predkosc * zycie, wiec slad jest
# dokladnie o tyle dluzszy, o ile szybsza jest jednostka.
const WAKE_LIFETIME: float = 1.1
# Skala miekkiej tekstury piany (WAKE_TEXTURE_SIZE px); rosnie z predkoscia.
const WAKE_SCALE_SLOW: float = 0.35
const WAKE_SCALE_FAST: float = 0.75
# Docelowy odstep stempli piany WZDLUZ sladu (px) - odkladane co tyle PRZEBYTEJ DROGI,
# wiec gestosc jest idealnie stala przestrzennie, niezaleznie od predkosci i FPS.
const WAKE_SPACING_PX: float = 9.0
# Twardy globalny limit stempli piany (ring buffer WakeField) - sufit kosztu web.
const WAKE_MAX_STAMPS: int = 800
# Margines cullingu stempli poza kadrem (px swiata) - dalszych nie rysujemy.
const WAKE_CULL_MARGIN_PX: float = 64.0
# W scisku (separacja aktywna) jednostka odklada stemple rzadziej - stado nie buduje
# jednolitej sciany piany (mnoznik odstepu przy pelnym zatloczeniu).
const WAKE_CROWD_SPACING_MULT: float = 2.2
# Szersze jednostki dostaja wieksza piane (boss): mnoznik = half_width / REF, przyciety.
const WAKE_WIDTH_REF: float = 16.0
const WAKE_WIDTH_BOOST_MAX: float = 2.5
# Krycie piany (poczatek zycia czastki; ogon wygasa do zera).
const WAKE_ALPHA: float = 0.55
# Rozmiar generowanej radialnej tekstury piany (px).
const WAKE_TEXTURE_SIZE: int = 32
# Build mobilny: kamera oddalona (0.85) + maly fizyczny ekran - piana odrobine wieksza.
const WAKE_MOBILE_SCALE_BOOST: float = 1.35
# Dryf piany na zewnatrz jako ulamek predkosci jednostki: atan(0.3) ~ 17 stopni -
# staly kat rozejscia "V", blisko naturalnego kilwatera (~19.5 stopnia).
const WAKE_SPREAD_RATIO: float = 0.3
# Szerokosc zrodla, gdy cialo nie ma CollisionShape2D (rozstaw sladow = szerokosc).
const WAKE_WIDTH_FALLBACK: float = 24.0

# --- Separacja wrogow (zapobiega pelnemu nakladaniu sie cial i kilwaterow) ---
# Prog odpychania jako ulamek sumy promieni: 0.5 = "kolizja na pol rozmiaru" -
# wrogowie moga nachodzic na siebie do polowy, potem sie rozpychaja.
const ENEMY_SEPARATION_FACTOR: float = 0.5
# Maksymalna predkosc rozpychania (px/s) przy pelnym nalozeniu.
const ENEMY_SEPARATION_PUSH: float = 90.0
# Odswiezanie separacji co tyle klatek fizyki (fazy rozlozone losowo per wrog) -
# tnie koszt O(n^2) przy stadzie; miedzy odswiezeniami dziala zapamietane pchniecie.
const ENEMY_SEPARATION_EVERY: int = 3

# --- Spienione fale ambientowe (FoamWave - luk piany wedrujacy po wodzie) ---
# Odstep miedzy falami (losowo w widelkach) i pierwsza fala po starcie sesji.
const FOAM_WAVE_INTERVAL_MIN: float = 9.0
const FOAM_WAVE_INTERVAL_MAX: float = 20.0
# Ruch i geometria luku fali.
const FOAM_WAVE_SPEED_MIN: float = 35.0
const FOAM_WAVE_SPEED_MAX: float = 60.0
const FOAM_WAVE_RADIUS_MIN: float = 90.0
const FOAM_WAVE_RADIUS_MAX: float = 150.0
const FOAM_WAVE_SPAN_DEG: float = 110.0
const FOAM_WAVE_ARC_POINTS: int = 24
# Czas zycia frontu fali (emisja piany), potem ogon dogasa i wezel znika sam.
const FOAM_WAVE_TRAVEL_TIME: float = 6.5
# Krycie piany fali - subtelniejsze niz kilwater jednostek.
const FOAM_WAVE_ALPHA: float = 0.4

# --- Fale przeciwnosci (DangerWave - prad znosi lodz; gameplay) ---
# Start wraz z rekinami: tier 2 krzywej spawnu = 2. minuta sesji (straznik w testach).
const DANGER_WAVE_START_TIME: float = 120.0
const DANGER_WAVE_INTERVAL_MIN: float = 18.0
const DANGER_WAVE_INTERVAL_MAX: float = 30.0
const DANGER_WAVE_SPEED: float = 70.0
# "Lekko wieksza" od fali ambientowej (90-150).
const DANGER_WAVE_RADIUS_MIN: float = 130.0
const DANGER_WAVE_RADIUS_MAX: float = 200.0
# Grubosc pasa dzialania pradu wokol luku piany (latwa do uniknieci wstega).
const DANGER_WAVE_BAND_PX: float = 28.0
# Prad: z fala +20% predkosci, pod fale -25% ("delikatne" - do ogrania w obie strony).
const DANGER_WAVE_BOOST_WITH: float = 0.20
const DANGER_WAVE_SLOW_AGAINST: float = 0.25
# Fala gameplayowa wyrazniejsza od ambientowej.
const DANGER_WAVE_ALPHA: float = 0.5

# --- Harpun: progresja obrazen i spowolnienie (rebalans kart level-up) ---
# "Ostrzejszy grot": +2 obrazen na poziom (breakpointy TTK - zob. test_damage_progression).
const HARPOON_DAMAGE_PER_LEVEL: float = 2.0
# "Harpun z linka": procent spowolnienia trafionego wroga per poziom karty.
const HARPOON_SLOW_PCT_PER_LEVEL: Array[float] = [0.25, 0.35, 0.45]
const HARPOON_SLOW_DURATION: float = 1.5

# --- Bron (harpun) ---
const HARPOON_DAMAGE: float = 5.0
const HARPOON_SPEED: float = 400.0
# Po tylu sekundach lecacy harpun usypia sie (pooling, brak wyciekow).
const HARPOON_LIFETIME: float = 3.0
# Auto-atak: odstep miedzy salwami i zasieg wykrywania wroga.
const HARPOON_BASE_INTERVAL: float = 0.8
const HARPOON_BASE_RANGE: float = 350.0
# Rozmiar puli harpunow (Object Pooling). Zapas na stackowanie ulepszen (wiele pociskow naraz).
const HARPOON_POOL_SIZE: int = 30

# --- Wrogowie (baza = meduza; barracuda/rekin nadpisuja w scenach .tscn) ---
const ENEMY_JELLYFISH_SPEED: float = 80.0
const ENEMY_JELLYFISH_HP: float = 10.0
const ENEMY_JELLYFISH_SCORE: int = 1
# Obrazenia kontaktowe zwyklego wroga (baza EnemyBase). Rowne legacy PLAYER_CONTACT_DAMAGE.
const ENEMY_CONTACT_DAMAGE: float = PLAYER_CONTACT_DAMAGE
# Twardy cap jednoczesnych wrogow (wydajnosc + Web). Przy lekkich meduzach (waga 1) to
# wlasnie ten cap - nie budzet - byl realnym ogranicznikiem. Test wydajnosci/feel: max 100.
const ENEMY_MAX_COUNT: int = 500
# Karencja startowa: przez tyle sekund od startu sesji spawner nie wypuszcza
# zwyklych wrogow (onboarding - gracz zdazy sie rozejrzec; fix obrazen na starcie).
const SPAWN_GRACE_SECONDS: float = 2.0

# --- Spawn wagowy (R5): presja rosnie z czasem przez budzet wagi na ekranie ---
# Wagi per typ (Enemy.EnemyType jako int): meduza(0)=1, barakuda(1)=2, rekin(2)=3.
const ENEMY_WEIGHT := {0: 1, 1: 2, 2: 3}
# Budzet sumy wag zywych wrogow na ekranie: BASE na starcie, rosnie PER_MIN, cap MAX.
# Podniesione (rebalans): pelniejszy start, wyrazny wzrost z czasem, wyzszy sufit -
# wiecej meduz wczesniej i pozniej (cap liczby ENEMY_MAX_COUNT chroni FPS).
const ENEMY_WEIGHT_BUDGET_BASE: float = 14.0
# Stromy wzrost, by twardy cap ENEMY_MAX_COUNT (500) byl realnie osiagalny pod koniec sesji.
const ENEMY_WEIGHT_BUDGET_PER_MIN: float = 100.0
const ENEMY_WEIGHT_BUDGET_MAX: float = 520.0
# Eventowe hordy (np. rojenie meduz) wypelniaja tylko ten ulamek budzetu - reszta zostaje
# na zwykly spawn (event nie zapycha calego pola).
const EVENT_FILL_FRACTION: float = 0.6
# Skracanie interwalu spawnu z czasem (mnoznik bazowego interwalu z difficulty_curve, capowany).
const SPAWN_INTERVAL_RAMP: float = 0.08      # spadek mnoznika na minute
const SPAWN_INTERVAL_MIN_FACTOR: float = 0.45
# Mnoznik liczby zrzucanych orbow XP (R5b): kazdy wrog zrzuca x2 orbow (x2 XP).
const XP_ORB_DROP_MULT: int = 2

# --- Mini-boss (MotorBoat) ---
const MINIBOSS_HP: float = 300.0
const MINIBOSS_SCORE: int = 500
# Mini-boss rani gracza na kontakt mocniej niz zwykly wrog.
const MINIBOSS_CONTACT_DAMAGE: float = 25.0
const MINIBOSS_TRACK_SPEED: float = 85.0
const MINIBOSS_CHARGE_INTERVAL: float = 3.0
const MINIBOSS_CHARGE_DURATION: float = 0.55
# Dystans szarzy: boss natiera w linii o ta dlugosc w kierunku gracza, PRZELATUJAC obok
# (a nie zatrzymujac sie przed nim) - dzieki temu odslania bok do ostrzelania.
const MINIBOSS_CHARGE_DISTANCE: float = 520.0
# Wind-up (telegraf) przed szarza - czas, ktory gracz ma na reakcje/unik.
const MINIBOSS_TELEGRAPH_DURATION: float = 0.6
# Szybkosc wygladzania obrotu bossa ku celowi (waga lerp_angle skalowana czasem klatki).
const MINIBOSS_TURN_SPEED: float = 6.0
# Telegraf wizualny: ile pulsow rozblysku w czasie wind-upu i ich barwa. Overbright (>1)
# rozjasnia pelnokolorowy sprite bossa - rozblysk widoczny mimo bialej bazy modulate
# (placeholder mial czerwona baze, biel wystarczala; docelowy PNG wymaga overbright).
const MINIBOSS_TELEGRAPH_PULSES: int = 3
const MINIBOSS_TELEGRAPH_COLOR: Color = Color(1.8, 1.8, 1.8, 1.0)
# Czas (s) pojawienia bossa i wyprzedzenie ostrzezenia boss_incoming.
# A2: 210 s (3:30) - rekin wchodzi w min. 2 (120 s), wiec ~90 s walki z pelnym skladem.
const MINIBOSS_SPAWN_TIME: float = 210.0
const MINIBOSS_WARNING: float = 2.0

# --- Juice (FAZA 5): animacje "zycia" obiektow (kosmetyka Tweenow, nie balans rozgrywki) ---
# Idle wrogow: bob (px, pion) + sway (rad, obrot) Sprite'a, profil per typ wroga.
const ENEMY_IDLE := {
	"barracuda": {"bob_amount": 1.2, "bob_period": 0.5, "sway_amount": 0.04, "sway_period": 0.7},
	"shark": {"bob_amount": 2.0, "bob_period": 1.7, "sway_amount": 0.03, "sway_period": 1.8},
	# Meduza: wyrazny plyw gora-dol, bez kolysania (sway 0) - shader wobble robi galaretowatosc.
	"jellyfish": {"bob_amount": 5.0, "bob_period": 2.2, "sway_amount": 0.0, "sway_period": 1.0},
}
# Kolysanie bossa: bob lokalnego Sprite'a (NIE ciala - szarza/telegraf graja rownolegle).
const MINIBOSS_BOB_AMOUNT: float = 3.0
const MINIBOSS_BOB_PERIOD: float = 1.6
# Dryf deski leczniczej: bob (px) + sway (rad) o roznych okresach (nieregularny dryf).
const HEAL_PLANK_BOB_AMOUNT: float = 3.0
const HEAL_PLANK_BOB_PERIOD: float = 1.4
const HEAL_PLANK_SWAY_AMOUNT: float = 0.12
const HEAL_PLANK_SWAY_PERIOD: float = 1.9

# --- XP / orby ---
# Wartosc bazowa orba (meduza). Mocniejsze typy zrzucaja wiecej: barakuda x2, rekin x5
# (nadpisane jako xp_value w ich scenach .tscn - jak speed/hp/score), mini-boss = ponizej.
const XP_ORB_VALUE: int = 1
const XP_ORB_MINIBOSS: int = 10
const XP_PICKUP_RADIUS: float = 30.0
# Magnes: orb dogania gracza nawet gdy ten ucieka na max (PLAYER_MAX_SPEED=200) i lapie
# wczesniej (A1). Wczesniej 250/120 - orb wypadal poza zasieg przy ucieczce.
const XP_MAGNET_SPEED: float = 400.0
const XP_MAGNET_RANGE: float = 180.0
# Po tylu sekundach aktywnej gry niezebrany orb znika (audyt P0.1).
const XP_ORB_LIFETIME: float = 12.0
# Model 1 orb = 1 XP (FAZA 6): wrog zrzuca xp_value orbow po 1 XP, rozrzuconych w promieniu.
# Cap chroni FPS - po przekroczeniu nadmiar oddaje XP wprost (gracz nie traci nagrody).
const XP_ORB_SCATTER_RADIUS: float = 28.0
const XP_ORB_MAX_ON_SCREEN: int = 120
# Boss: kilka "grubych" orbow (hybryda) - count x value (~12 XP), kazdy wiekszy wizualnie.
const XP_ORB_BOSS_COUNT: int = 4
const XP_ORB_BOSS_VALUE: int = 3
const XP_ORB_FAT_SCALE: float = 1.6
# Zbieranie: czas wsiakania orba do gracza; combo (seria w czasie) -> sila blysku + pitch.
const XP_ORB_ABSORB_TIME: float = 0.18
const XP_COMBO_RESET_TIME: float = 0.6
const XP_COMBO_MAX: int = 12
const XP_COMBO_PITCH_STEP: float = 0.04

# --- Progresja ---
# Maksymalny poziom gracza = wiek Ernesta Hemingwaya w chwili smierci.
const MAX_LEVEL: int = 61
# Co tyle poziomow zamiast zwyklej karty pojawia sie specjalny power-up (harpun/przebijanie).
const MILESTONE_LEVEL_INTERVAL: int = 5

# --- Meta-progresja (R3): trwale ulepszenia kupowane miedzy sesjami ---
const META_POINTS_PER_SCORE: int = 10     # tyle wyniku = 1 punkt meta
const META_COST_BASE: int = 50            # koszt poziomu L = BASE*(L+1)
const META_BOAT_SPEED_MAX: float = 80.0   # bonus startowej predkosci lodzi na maks. poziomie
const META_MAGNET_MULT_MAX: float = 1.0   # dodatek mnoznika zasiegu zbierania na maks (1.0 -> x2)
const META_HORDE_BUDGET_MAX: float = 18.0 # dodatek do budzetu wrogow na maks (wiecej wrogow = wiecej punktow)

# --- Leczenie ---
# Dryfujaca deska (rybak lata nia kadlub): ile HP przywraca i jak czesto sie pojawia.
const HEAL_PLANK_AMOUNT: float = 25.0
const HEAL_PLANK_INTERVAL: float = 25.0
# Po tylu sekundach niezebrana deska znika.
const HEAL_PLANK_LIFETIME: float = 15.0

# --- Efekty ---
# Czas zycia bursta smierci wroga (CPUParticles2D) zanim sam sie zwolni.
const DEATH_BURST_LIFETIME: float = 1.5

# --- Narracja: efekt maszyny do pisania (dialogi B4 + ostrzezenie o bossie) ---
const TYPEWRITER_CPS: float = 16.0          # znaki/s ujawniania; wolno, by mlodszy gracz zdazyl przeczytac
const TYPEWRITER_KEY_EVERY: int = 2         # dzwiek klawisza co N ujawnionych nie-bialych znakow
const TYPEWRITER_KEY_PITCH_JITTER: float = 0.12  # +/- losowy pitch klawisza (naturalnosc)

# --- Narracja: dialogi w grze (dolny pasek, bez pauzy) ---
const DIALOGUE_FADE: float = 0.4            # czas fade in/out paska
const DIALOGUE_HOLD: float = 3.5            # ile sekund kwestia trzyma sie PO napisaniu

# --- Intro Santiago (B3) ---
const INTRO_COUNTDOWN_STEP: float = 0.7     # czas jednego kroku odliczania 3-2-1
const INTRO_PAGE_TURN_TIME: float = 0.5     # czas animacji przewrocenia strony (komiks/ksiazka)

# --- Koniec sesji (R4) ---
# Po spelnieniu warunku wygranej: laska na zebranie orbow, zanim pojawi sie ekran wyniku.
const VICTORY_COLLECT_GRACE: float = 3.0

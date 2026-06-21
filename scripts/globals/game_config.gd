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
# Cap jednoczesnych wrogow (wydajnosc + Web).
const ENEMY_MAX_COUNT: int = 30
# Karencja startowa: przez tyle sekund od startu sesji spawner nie wypuszcza
# zwyklych wrogow (onboarding - gracz zdazy sie rozejrzec; fix obrazen na starcie).
const SPAWN_GRACE_SECONDS: float = 2.0

# --- Mini-boss (MotorBoat) ---
const MINIBOSS_HP: float = 300.0
const MINIBOSS_SCORE: int = 500
# Mini-boss rani gracza na kontakt mocniej niz zwykly wrog.
const MINIBOSS_CONTACT_DAMAGE: float = 25.0
const MINIBOSS_TRACK_SPEED: float = 60.0
const MINIBOSS_CHARGE_INTERVAL: float = 3.0
const MINIBOSS_CHARGE_DURATION: float = 0.45
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

# --- Leczenie ---
# Dryfujaca deska (rybak lata nia kadlub): ile HP przywraca i jak czesto sie pojawia.
const HEAL_PLANK_AMOUNT: float = 25.0
const HEAL_PLANK_INTERVAL: float = 25.0
# Po tylu sekundach niezebrana deska znika.
const HEAL_PLANK_LIFETIME: float = 15.0

# --- Efekty ---
# Czas zycia bursta smierci wroga (CPUParticles2D) zanim sam sie zwolni.
const DEATH_BURST_LIFETIME: float = 1.5

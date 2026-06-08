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
# Obrazenia, ktore gracz przyjmuje na pojedynczy kontakt z wrogiem.
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
# Rozmiar puli harpunow (Object Pooling).
const HARPOON_POOL_SIZE: int = 20

# --- Wrogowie (baza = meduza; barracuda/rekin nadpisuja w scenach .tscn) ---
const ENEMY_JELLYFISH_SPEED: float = 80.0
const ENEMY_JELLYFISH_HP: float = 10.0
const ENEMY_JELLYFISH_SCORE: int = 1
# Cap jednoczesnych wrogow (wydajnosc + Web).
const ENEMY_MAX_COUNT: int = 30
# Karencja startowa: przez tyle sekund od startu sesji spawner nie wypuszcza
# zwyklych wrogow (onboarding - gracz zdazy sie rozejrzec; fix obrazen na starcie).
const SPAWN_GRACE_SECONDS: float = 5.0

# --- Mini-boss (MotorBoat) ---
const MINIBOSS_HP: float = 300.0
const MINIBOSS_SCORE: int = 500
const MINIBOSS_TRACK_SPEED: float = 60.0
const MINIBOSS_CHARGE_INTERVAL: float = 3.0
const MINIBOSS_CHARGE_DURATION: float = 0.45
# Czas (s) pojawienia bossa i wyprzedzenie ostrzezenia boss_incoming.
const MINIBOSS_SPAWN_TIME: float = 270.0
const MINIBOSS_WARNING: float = 2.0

# --- XP / orby ---
# Wartosc bazowa orba (meduza). Mocniejsze typy zrzucaja wiecej: barakuda x2, rekin x5
# (nadpisane jako xp_value w ich scenach .tscn - jak speed/hp/score), mini-boss = ponizej.
const XP_ORB_VALUE: int = 1
const XP_ORB_MINIBOSS: int = 10
const XP_PICKUP_RADIUS: float = 30.0
const XP_MAGNET_SPEED: float = 250.0
const XP_MAGNET_RANGE: float = 120.0
# Po tylu sekundach aktywnej gry niezebrany orb znika (audyt P0.1).
const XP_ORB_LIFETIME: float = 12.0

# --- Progresja ---
# Maksymalny poziom gracza = wiek Ernesta Hemingwaya w chwili smierci.
const MAX_LEVEL: int = 61

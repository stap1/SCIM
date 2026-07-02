class_name NarrativeData
extends RefCounted

# NarrativeData - jedyne zrodlo tekstow narracji i listy portretow intro.
# Wzorzec jak GameConfig: tylko const + czyste static func, zero stanu, zero logiki sceny.
#
# UWAGA PRAWNA: ponizsze kwestie to ORYGINALNE teksty napisane dla SCIM - wierne faktom
# i charakterowi "Starego czlowieka i morza", ale wolne od praw. To NIE sa cytaty i nie
# wolno ich tak oznaczac. Charakterystyka: pierwsza osoba, krotkie zdania, ton zmeczonej
# determinacji; motywy samotnosci, godnosci, walki; bez patosu i archaizmow.

# Okrzyk na koniec odliczania intro (przejscie na wode).
const INTRO_SHOUT := "NA MORZE!"

# Pierwsza kwestia protagonisty - pojawia sie JUZ W GRZE (z efektem maszyny), nie na intro.
const FIRST_LINE := "Tym razem nie wrócę z morza z pustymi rękami."

# Kwestia otwierajaca (zapas; aktualnie intro pokazuje samo odliczanie).
const INTRO := "Osiemdziesiąt cztery dni bez połowu. Dziś morze odda mi to, co moje."

# Progi liczby zabitych meduz -> kwestia (jedna na osiagniety prog).
const JELLYFISH_LINES := {
	10: "Morze roi się od galaretowatych cieni. Same w sobie niegroźne - groźna jest ich liczba.",
	30: "Im dłużej jestem na wodzie, tym więcej ich przybywa. Morze nie znosi pustki.",
	60: "Człowiek na tej łodzi jest sam. Ale samotność to nie to samo co słabość.",
}

# Pierwszy kontakt z drapieznikiem.
const FIRST_BARRACUDA := "Coś smukłego i szybkiego przecięło wodę. Drapieżnik - jak ja."
const FIRST_SHARK := "Rekin. Tego się obawiałem najbardziej. Przyszedł po to, co zdobyłem. Będę walczył, choćby bez nadziei."

# Pierwsza fala przeciwnosci (DangerWave) - trudy morza; prad mozna ograc w obie strony.
const FIRST_DANGER_WAVE := "Morze się burzy. Fala nie pyta, dokąd płyniesz - mądry rybak nie walczy z nią, tylko pozwala się nieść."

# Zapowiedz bossa (klusownik) i kwestia po jego pokonaniu.
const BOSS_INCOMING := "Silnik na horyzoncie. Człowiek gorszy od rekina - przypływa ukraść mój połów."
const BOSS_DEFEATED := "Obroniłem to, co moje. Morze jeszcze nie powiedziało ostatniego słowa."

# Portrety Santiago do intro (losowanie, B3). Pelnoekranowe, nieprzezroczyste.
const SANTIAGO_PORTRAITS: Array[String] = [
	"res://assets/splash/santiago_intro_1.jpg",
	"res://assets/splash/santiago_intro_2.jpg",
	"res://assets/splash/santiago_intro_3.jpg",
	"res://assets/splash/santiago_intro_4.jpg",
]

# Czysta funkcja: najwyzszy prog meduz <= count (lub "" gdy zaden jeszcze nieosiagniety).
# Logike "tylko raz na prog" trzyma wolajacy (DialogueBanner sledzi ostatni prog).
static func jellyfish_line_for(count: int) -> String:
	var best_key := -1
	for k in JELLYFISH_LINES:
		if int(k) <= count and int(k) > best_key:
			best_key = int(k)
	return JELLYFISH_LINES[best_key] if best_key != -1 else ""

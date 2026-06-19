shader_type canvas_item;

// Naturalne plyniecie ryby (karangiform): GLOWA niemal nieruchoma, amplituda undulacji
// ROSNIE ku ogonowi (pow(along,1.6)), a fala biegnie od glowy do ogona (body_wave to
// opoznienie fazy). Bez przeciwfazy glowa<->ogon (to wygladalo nienaturalnie). Faza zalezna
// od pozycji swiatowej (world.x) -> kazda ryba w innym rytmie, jeden wspoldzielony material.
//
// Wydajnosc: tylko vertex(), bez fragment(); Sprite2D = 4 wierzcholki -> koszt znikomy.
// Compatibility-safe (pojedynczy sin, bez petli/pochodnych).

uniform float swim_speed = 5.0;   // tempo machania ogonem
uniform float swim_amp = 10.0;    // maks. amplituda (ogon), px
uniform float swim_freq = 0.05;   // rozjazd fazy wg pozycji swiatowej (desync ryb)
uniform float body_wave = 1.5;    // opoznienie fazy glowa->ogon (fala biegnaca)
uniform float head_y = -90.0;     // gora sprite'a (glowa)
uniform float tail_y = 110.0;     // dol sprite'a (ogon)

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float along = clamp(smoothstep(head_y, tail_y, VERTEX.y), 0.0, 1.0);  // 0 glowa, 1 ogon
	float wave = sin(TIME * swim_speed + world.x * swim_freq - along * body_wave);
	float amp = swim_amp * pow(along, 1.6);  // glowa ~nieruchoma, ogon macha najmocniej
	VERTEX.x += wave * amp;
}

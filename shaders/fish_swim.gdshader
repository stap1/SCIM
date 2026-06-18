shader_type canvas_item;

// "Rybi" ruch wroga: undulacja ciala (fala biegnaca od glowy do ogona). Glowa i ogon
// machaja w PRZECIWFAZIE (body_wave) -> cialo wygina sie w S jak plynaca ryba, a ogon
// macha najmocniej (amp rosnie ku dolowi sprite'a). Faza zalezy od pozycji swiatowej
// (world.x) -> kazda ryba plynie w innym rytmie, mimo JEDNEGO wspoldzielonego materialu.
//
// Wydajnosc: tylko vertex(), bez fragment(); Sprite2D = 4 wierzcholki -> koszt znikomy
// nawet dla setek ryb. Compatibility-safe (pojedynczy sin, bez petli/pochodnych).

uniform float swim_speed = 7.0;   // tempo machania
uniform float swim_amp = 9.0;     // amplituda ogona (px)
uniform float head_amp = 2.0;     // amplituda glowy (mniejsza, przeciwna faza)
uniform float swim_freq = 0.05;   // rozjazd fazy wg pozycji swiatowej (desync ryb)
uniform float body_wave = 2.6;    // przesuniecie fazy glowa->ogon (wygiecie S)
uniform float head_y = -90.0;     // gora sprite'a (glowa)
uniform float tail_y = 110.0;     // dol sprite'a (ogon)

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float along = smoothstep(head_y, tail_y, VERTEX.y);   // 0 = glowa, 1 = ogon
	float wave = sin(TIME * swim_speed + world.x * swim_freq - along * body_wave);
	float amp = mix(head_amp, swim_amp, along);           // glowa lekko, ogon mocno
	VERTEX.x += wave * amp;
}

shader_type canvas_item;

// "Rybi" ruch wroga: pletwa ogonowa macha na boki. Przesuniecie VERTEX.x rosnie ku ogonowi
// (dol sprite'a, VERTEX.y>0); glowa (gora) prawie nieruchoma. Faza zalezy od pozycji
// swiatowej (world.x) -> kazda ryba macha w innym rytmie mimo wspoldzielonego materialu.
// Compatibility-safe. Sprite obraca sie z cialem (celowanie), wiec mach jest prostopadly
// do kierunku plyniecia - dokladnie jak prawdziwa ryba.

uniform float swim_speed = 6.0;
uniform float swim_amp = 5.0;
uniform float swim_freq = 0.05;
uniform float tail_start = 0.0;
uniform float tail_end = 110.0;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	float tail = smoothstep(tail_start, tail_end, VERTEX.y);  // 0 przy glowie, 1 przy ogonie
	VERTEX.x += sin(TIME * swim_speed + world.x * swim_freq) * swim_amp * tail;
}

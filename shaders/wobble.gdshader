shader_type canvas_item;

// Delikatne falowanie galaretowatego wroga (meduzy): przesuniecie VERTEX zalezne od TIME
// i pozycji SWIATOWEJ wierzcholka. Dzieki world.y kazda meduza ma inna faze -> nie falują
// w zgranej rytmice, mimo JEDNEGO wspoldzielonego materialu (tanio na webie).
// Compatibility-safe: pojedynczy sin, bez petli/pochodnych.

uniform float wobble_speed = 2.0;
uniform float wobble_amount = 3.0;
uniform float wobble_freq = 0.05;

void vertex() {
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	VERTEX.x += sin(TIME * wobble_speed + world.y * wobble_freq) * wobble_amount;
}

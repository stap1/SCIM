shader_type canvas_item;

// Zunifikowany wskaznik HP gracza NA ilustracji kadluba:
//  1) PLYNNY blend 5 klatek uszkodzen wg % HP (bez twardych progow),
//  2) desaturacja rosnaca z utrata HP,
//  3) "zapelnienie" - czesc kadluba do poziomu HP pelnokolorowa, reszta przyciemniona.
// Wszystkie 5 tekstur probkowane bezwarunkowo (bezpieczne w Compatibility), wybor przez ?:.

uniform sampler2D s0;
uniform sampler2D s1;
uniform sampler2D s2;
uniform sampler2D s3;
uniform sampler2D s4;
uniform float health : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float dmg = clamp(1.0 - health, 0.0, 1.0);
	float sf = dmg * 4.0;          // 0 (cale) .. 4 (roztrzaskane)
	float fi = floor(sf);
	float f = sf - fi;

	vec4 t0 = texture(s0, UV);
	vec4 t1 = texture(s1, UV);
	vec4 t2 = texture(s2, UV);
	vec4 t3 = texture(s3, UV);
	vec4 t4 = texture(s4, UV);

	vec4 a = fi < 0.5 ? t0 : (fi < 1.5 ? t1 : (fi < 2.5 ? t2 : t3));
	vec4 b = fi < 0.5 ? t1 : (fi < 1.5 ? t2 : (fi < 2.5 ? t3 : t4));
	vec4 col = mix(a, b, f);       // plynne przejscie miedzy klatkami uszkodzen

	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(lum), dmg * 0.7);   // desaturacja wg %

	// Zapelnienie poziome: do UV.x == health pelny kolor, dalej przyciemnione (czytelny poziom).
	float beyond = smoothstep(health - 0.03, health + 0.03, UV.x);
	col.rgb *= mix(1.0, 0.32, beyond);

	COLOR = vec4(col.rgb, col.a);
}

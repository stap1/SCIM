shader_type canvas_item;

// Analogowy wskaznik HP na sprite kadluba: im wiekszy "damage" (0=pelne HP, 1=zero), tym
// mocniejsza desaturacja + ciemniejszy/czerwonawy ton. Dziala plynnie miedzy progowymi
// klatkami hull_hp_<stage>, dajac ciagle sprzezenie zwrotne.

uniform float damage : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c.rgb, vec3(lum), clamp(damage * 0.85, 0.0, 1.0));   // desaturacja wg %
	col = mix(col, col * vec3(1.05, 0.6, 0.55), clamp(damage * 0.6, 0.0, 1.0)); // ciemny czerwonawy ton
	COLOR = vec4(col, c.a);
}

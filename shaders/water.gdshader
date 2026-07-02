shader_type canvas_item;

// Woda: JEDNA tekstura z dwoma szumami w kanalach R/G (2 fetche cache-friendly),
// refleks grzbietow liczony z wysokosci (bez normal mapy i pow-speculara).
// Web / GL Compatibility-safe: bez petli zmiennych, bez pochodnych, bez SCREEN_TEXTURE.
// Kolory sterowane per klatke z water_background.gd (jasny poranek -> ciemna ton).

uniform vec4 water_color : source_color = vec4(0.11, 0.22, 0.34, 1.0);
uniform vec4 wave_color : source_color = vec4(0.3, 0.52, 0.7, 1.0);

// R = szum 1, G = szum 2 (assets/water_noise_rg.png, tools/pack_water_noise.gd).
uniform sampler2D noise_tex : repeat_enable, filter_linear;

// Przeciwne kierunki przewijania = interferencja fal, brak jednolitego dryfu.
uniform vec2 scroll_dir_1 = vec2(1.0, 0.3);
uniform vec2 scroll_dir_2 = vec2(-0.5, -0.8);
uniform float scroll_speed_1 = 0.02;
uniform float scroll_speed_2 = 0.012;
uniform float tex_scale = 2.0;
// Sila rozjasnienia grzbietow fal (zamiast normal mapy + speculara).
uniform float glint_strength = 0.7;
// Woda pasmowa/toon (decyzja art-direction 2026-07-02, wariant B1 z analizy):
// kwantyzacja do plaskich pasm; 0 przywraca gladki mix (fallback/testy stylu).
uniform float band_count = 3.0;

varying vec2 v_world;

void vertex() {
	// Pozycja swiatowa wierzcholka - fale zakotwiczone w swiecie, nie na ekranie
	// (ColorRect podaza za kamera, ale woda i tak "stoi" w swiecie).
	v_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 base_uv = v_world / 1024.0 * tex_scale;
	vec2 uv1 = base_uv + scroll_dir_1 * TIME * scroll_speed_1;
	vec2 uv2 = base_uv + scroll_dir_2 * TIME * scroll_speed_2;

	// Wysokosc fali z dwoch warstw szumu (kanaly tej samej tekstury) przewijanych przeciwnie.
	float h1 = texture(noise_tex, uv1).r;
	float h2 = texture(noise_tex, uv2).g;
	float h = h1 * 0.6 + h2 * 0.4;
	h = clamp((h - 0.5) * 1.8 + 0.5, 0.0, 1.0);  // wiekszy kontrast grzbietow fal

	// B1 (toon): kwantyzacja wysokosci do plaskich pasm; galaz po uniformie jest
	// spojna dla calego ekranu (tania w GL). band_count=0 -> gladki styl bazowy.
	float mix_t = h;
	if (band_count >= 1.0) {
		mix_t = clamp(floor(h * band_count) / max(band_count - 1.0, 1.0), 0.0, 1.0);
	}
	vec3 col = mix(water_color.rgb, wave_color.rgb, mix_t);

	// Refleks: waski, jasny pas na samych grzbietach - czytany wprost z wysokosci.
	// Prog podniesiony (0.82-0.96) i sila stonowana - subtelniejsze grzbiety na pasmach.
	float crest = smoothstep(0.82, 0.96, h);
	col += wave_color.rgb * crest * glint_strength;

	COLOR = vec4(col, 1.0);
}

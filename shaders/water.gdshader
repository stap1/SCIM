shader_type canvas_item;

// Woda czytajaca dwie heightmapy szumu + normal map (zamiast proceduralnego sin/cos).
// Web / GL Compatibility-safe: bez petli zmiennych, bez pochodnych. Repeat przez hint samplera.

uniform vec4 water_color : source_color = vec4(0.165, 0.29, 0.42, 1.0);
uniform vec4 wave_color : source_color = vec4(0.21, 0.37, 0.53, 1.0);

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D noise_tex_2 : repeat_enable, filter_linear;
uniform sampler2D normal_tex : repeat_enable, filter_linear;

// Przeciwne kierunki przewijania = interferencja fal, brak jednolitego dryfu.
uniform vec2 scroll_dir_1 = vec2(1.0, 0.3);
uniform vec2 scroll_dir_2 = vec2(-0.5, -0.8);
uniform float scroll_speed_1 = 0.02;
uniform float scroll_speed_2 = 0.012;
uniform float tex_scale = 2.0;
uniform float normal_strength = 0.5;

void fragment() {
	vec2 base_uv = UV * tex_scale;
	vec2 uv1 = base_uv + scroll_dir_1 * TIME * scroll_speed_1;
	vec2 uv2 = base_uv + scroll_dir_2 * TIME * scroll_speed_2;

	// Wysokosc fali z dwoch warstw szumu przewijanych przeciwnie.
	float h1 = texture(noise_tex, uv1).r;
	float h2 = texture(noise_tex_2, uv2).r;
	float h = h1 * 0.6 + h2 * 0.4;
	vec3 col = mix(water_color.rgb, wave_color.rgb, h);

	// Subtelny refleks na grzbietach: rozpakuj normal (*2-1), spec wzgledem stalego swiatla.
	vec3 n = normalize(texture(normal_tex, uv1).rgb * 2.0 - 1.0);
	vec3 light_dir = normalize(vec3(0.4, -0.6, 0.7));
	float spec = pow(max(dot(n, light_dir), 0.0), 16.0);
	col += wave_color.rgb * spec * normal_strength;

	COLOR = vec4(col, 1.0);
}

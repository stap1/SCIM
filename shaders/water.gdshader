shader_type canvas_item;

// Prosty, lekki shader wody (web-friendly): animowane fale z funkcji sinusoidalnej.
uniform vec4 water_color : source_color = vec4(0.165, 0.29, 0.42, 1.0);
uniform vec4 wave_color : source_color = vec4(0.21, 0.37, 0.53, 1.0);
uniform float speed = 0.3;
uniform float wave_scale = 10.0;

float wave_noise(vec2 p) {
	return sin(p.x) * cos(p.y);
}

void fragment() {
	vec2 uv = UV * wave_scale;
	float n = wave_noise(uv + vec2(TIME * speed, TIME * speed * 0.7));
	n += 0.5 * wave_noise(uv * 2.0 - vec2(TIME * speed * 0.5, 0.0));
	float t = smoothstep(-1.5, 1.5, n);
	COLOR = mix(water_color, wave_color, t * 0.6);
}

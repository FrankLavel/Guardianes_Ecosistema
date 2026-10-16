shader_type canvas_item;
// Rompe la repetición de una textura de suelo con manchas suaves de luz y sombra (fijas en el mundo).

uniform float intensidad : hint_range(0.0, 0.5) = 0.16;
uniform float escala = 0.0016;

varying vec2 posicion_mundo;

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float n = ruido(posicion_mundo * escala) * 0.65 + ruido(posicion_mundo * escala * 3.1) * 0.35;
	c.rgb *= 1.0 + (n - 0.5) * 2.0 * intensidad;
	// Un poco más amarillo en las zonas claras: pasto seco y pasto verde intercalados.
	c.rgb = mix(c.rgb, c.rgb * vec3(1.08, 1.04, 0.85), smoothstep(0.55, 0.9, n) * 0.6);
	COLOR = c * COLOR;
}

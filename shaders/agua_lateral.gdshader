shader_type canvas_item;
// Agua de río vista de lado (para un ColorRect). Superficie con ondas y brillos;
// `limpieza` cambia de agua turbia (café verdoso, opaca) a agua limpia (azul, transparente).

uniform float limpieza : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color_sucio : source_color = vec4(0.36, 0.35, 0.18, 0.95);
uniform vec4 color_limpio : source_color = vec4(0.18, 0.55, 0.85, 0.78);
uniform vec4 color_profundo_limpio : source_color = vec4(0.06, 0.26, 0.55, 0.9);
uniform float alto_px = 104.0;

void fragment() {
	float y = UV.y * alto_px;
	// Ondas en la superficie (los primeros pixeles se recortan siguiendo una onda).
	float onda = sin(UV.x * 40.0 + TIME * 2.2) * 2.0 + sin(UV.x * 17.0 - TIME * 1.3) * 1.5;
	if (y < 4.0 + onda) {
		discard;
	}
	vec4 limpio = mix(color_limpio, color_profundo_limpio, UV.y);
	vec4 sucio = mix(color_sucio, color_sucio * vec4(0.7, 0.7, 0.7, 1.0), UV.y);
	vec4 c = mix(sucio, limpio, limpieza);
	// Línea de espuma/brillo en la superficie.
	float superficie = 1.0 - smoothstep(0.0, 6.0, y - (4.0 + onda));
	c.rgb += superficie * mix(0.12, 0.45, limpieza);
	// Destellos que se mueven (solo con agua limpia).
	float destello = step(0.985, fract(sin(floor(UV.x * 60.0 + TIME * 3.0) * 12.9898 + floor(y / 6.0) * 78.233) * 43758.5453));
	c.rgb += destello * limpieza * 0.35 * (1.0 - UV.y);
	COLOR = c;
}

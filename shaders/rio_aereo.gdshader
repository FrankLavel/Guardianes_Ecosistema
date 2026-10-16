shader_type canvas_item;
// Río del mapa aéreo (Line2D con textura). El agua fluye y se ve turbia según `contaminacion`;
// las orillas (pasto) se quedan quietas.

uniform float velocidad = 0.06;
uniform float contaminacion : hint_range(0.0, 1.0) = 0.0;
uniform vec3 color_sucio : source_color = vec3(0.42, 0.40, 0.22);

void fragment() {
	vec4 quieto = texture(TEXTURE, UV);
	vec4 fluyendo = texture(TEXTURE, vec2(UV.x - TIME * velocidad, UV.y));
	// Qué tanto es agua (azul) y no orilla.
	float agua = clamp((quieto.b - max(quieto.r, quieto.g)) * 4.0, 0.0, 1.0);
	vec4 c = mix(quieto, fluyendo, agua);
	float brillo = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 turbio = color_sucio * (0.6 + brillo * 0.8);
	c.rgb = mix(c.rgb, turbio, agua * contaminacion * 0.85);
	COLOR = c * COLOR;
}

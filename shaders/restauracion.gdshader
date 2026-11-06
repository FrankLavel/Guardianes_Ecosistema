shader_type canvas_item;
// Post-proceso del mundo: mientras más dañado está el ecosistema, más gris y apagado se ve.

uniform sampler2D pantalla : hint_screen_texture, filter_linear_mipmap;
uniform float desaturacion : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 c = texture(pantalla, SCREEN_UV);
	float gris = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 apagado = vec3(gris) * vec3(1.02, 0.98, 0.9);
	COLOR = vec4(mix(c.rgb, apagado, desaturacion), 1.0);
}

shader_type canvas_item;
// Tierra arada de la milpa: la textura de surcos solo donde hay cuadros abiertos, con la orilla
// deshilachada para que se funda con el pasto (igual que el camino). La máscara trae un texel por
// cuadro (más una orilla vacía): R = abierto, G = regado.

uniform sampler2D tierra : source_color, repeat_enable, filter_linear;
uniform sampler2D mascara : filter_nearest;
uniform vec2 origen;
uniform vec2 tam = vec2(136.0, 96.0);
uniform vec2 celdas = vec2(6.0, 5.0);

varying vec2 posicion;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), u.x), mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	posicion = VERTEX;
}

void fragment() {
	vec2 local = posicion - origen;
	vec2 celda = local / tam;
	ivec2 aqui = ivec2(floor(celda)) + 1;
	// Distancia (en px) a la tierra abierta más cercana y al pasto más cercano, mirando los vecinos.
	float a_tierra = 1e4;
	float a_pasto = 1e4;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			ivec2 vecino = aqui + ivec2(x, y);
			bool abierto = all(greaterThanEqual(vecino, ivec2(0))) && all(lessThan(vecino, ivec2(celdas)))
				&& texelFetch(mascara, vecino, 0).r > 0.5;
			vec2 centro = (vec2(vecino - 1) + 0.5) * tam;
			float d = length(max(abs(local - centro) - tam * 0.5, 0.0));
			if (abierto) {
				a_tierra = min(a_tierra, d);
			} else {
				a_pasto = min(a_pasto, d);
			}
		}
	}
	// Orilla irregular a pixeles de 4: el pasto se mete un poco en la tierra y al revés.
	vec2 bloque = floor(posicion / 4.0);
	float vaiven = (ruido(bloque * 0.16) - 0.5) * 14.0 + (azar(bloque) - 0.5) * 4.0;
	// Distancia con signo a la orilla (negativa dentro de la tierra): el vaivén solo la mueve ahí.
	float orilla = a_tierra > 0.0 ? a_tierra : -a_pasto;
	float alfa = 1.0 - step(4.0, orilla + vaiven);
	vec4 c = texture(tierra, local / 192.0);
	// Junto al pasto la tierra está más apisonada (más clara) y entre cuadro y cuadro hay un canal.
	c.rgb = mix(c.rgb * vec3(1.14, 1.09, 1.0), c.rgb, smoothstep(0.0, 14.0, a_pasto - vaiven));
	vec2 dentro = fract(celda) * tam;
	float canal = min(min(dentro.x, tam.x - dentro.x), min(dentro.y, tam.y - dentro.y));
	c.rgb *= mix(0.72, 1.0, smoothstep(1.0, 4.0, canal));
	c.rgb *= mix(1.0, 0.68, texelFetch(mascara, aqui, 0).g);
	COLOR = vec4(c.rgb, alfa);
}

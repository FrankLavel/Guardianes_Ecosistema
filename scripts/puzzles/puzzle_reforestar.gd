class_name PuzzleReforestar
extends PuzzleAsignar
## Puzzle 3 (Zona 2): plantar cada árbol a la altura de la montaña donde crece.
## Arriba (frío y neblina): oyamel · En medio (ladera): pino · Abajo (cálido, junto al arroyo): encino.


func _configurar() -> void:
	opciones = {
		"oyamel": {"nombre": "Oyamel", "imagen": "res://assets/ui/bitacora/oyamel.png", "destino": "arriba",
			"pista": "El oyamel necesita frío y neblina: crece en lo más alto de la montaña."},
		"pino": {"nombre": "Pino", "imagen": "res://assets/ui/bitacora/pino.png", "destino": "medio",
			"pista": "El pino aguanta el viento y el suelo seco de las laderas, a media montaña."},
		"encino": {"nombre": "Encino", "imagen": "res://assets/ui/bitacora/encino.png", "destino": "abajo",
			"pista": "El encino prefiere la parte baja y cálida de la montaña, cerca del arroyo."},
	}
	destinos = {
		"arriba": {"nombre": "Cumbre", "posicion": Vector2(650, 130)},
		"medio": {"nombre": "Ladera", "posicion": Vector2(430, 300)},
		"abajo": {"nombre": "Junto al arroyo", "posicion": Vector2(200, 440)},
	}
	texto_inicio = "Cada árbol crece mejor a cierta altura de la montaña.\nElige un árbol y luego el lugar donde plantarlo."
	texto_final = "¡El bosque vuelve a crecer! Cada árbol en su lugar:\nasí el bosque protege el suelo, el agua y a los animales."
	especies_al_resolver = ["oyamel", "pino", "encino"]


func _ready() -> void:
	super()
	lienzo.draw.connect(_dibujar_montana)


## Altura (fracción del escenario) donde termina la cumbre y donde termina la ladera.
const LIMITE_CUMBRE := 0.33
const LIMITE_LADERA := 0.62


## Paisaje: cielo, cordillera lejana y la montaña con tres franjas de altura (cumbre fría con
## nieve y neblina, ladera y parte baja cálida con su arroyo).
func _dibujar_montana() -> void:
	var tam := lienzo.size
	var y_cumbre := tam.y * LIMITE_CUMBRE
	var y_ladera := tam.y * LIMITE_LADERA
	var cielo_arriba := Color(0.42, 0.66, 0.88)
	var cielo_abajo := Color(0.85, 0.92, 0.95)
	lienzo.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(tam.x, 0), tam, Vector2(0, tam.y)]),
		PackedColorArray([cielo_arriba, cielo_arriba, cielo_abajo, cielo_abajo]))
	lienzo.draw_circle(Vector2(tam.x * 0.4, tam.y * 0.12), 44, Color(1, 0.97, 0.8, 0.35), true, -1.0, true)
	lienzo.draw_circle(Vector2(tam.x * 0.4, tam.y * 0.12), 30, Color(1, 0.94, 0.66), true, -1.0, true)
	lienzo.draw_colored_polygon(_cordillera(tam, tam.y * 0.45, 70.0, 0.0), Color(0.6, 0.7, 0.82))
	lienzo.draw_colored_polygon(_cordillera(tam, tam.y * 0.58, 50.0, 2.0), Color(0.5, 0.62, 0.68))

	var cima := Vector2(tam.x * 0.66, tam.y * 0.08)
	var montana := _perfil(tam, cima)
	var franjas := [
		[y_ladera, tam.y + 20.0, Color(0.42, 0.6, 0.3)],
		[y_cumbre, y_ladera, Color(0.38, 0.5, 0.32)],
		[-20.0, y_cumbre, Color(0.56, 0.6, 0.62)],
	]
	for f in franjas:
		_rellenar(montana, _banda(tam, f[0], f[1]), f[2])
	# Nieve en la punta, con el borde de abajo irregular.
	var nieve := PackedVector2Array([Vector2(-50, -20), Vector2(tam.x + 250, -20), Vector2(tam.x + 250, y_cumbre * 0.55)])
	for i in range(8, -1, -1):
		var x := cima.x - 120 + i * 30
		nieve.append(Vector2(x, y_cumbre * (0.5 if i % 2 == 0 else 0.68)))
	nieve.append(Vector2(-50, y_cumbre * 0.55))
	_rellenar(montana, nieve, Color(0.95, 0.97, 1.0))
	# Cara derecha en sombra: le da volumen.
	_rellenar(montana, PackedVector2Array([cima, Vector2(tam.x + 250, tam.y + 20), Vector2(cima.x + 40, tam.y + 20)]), Color(0.05, 0.08, 0.2, 0.22))
	# Arbolitos de fondo en la ladera y abajo (solo textura; los lugares de plantar son los recuadros).
	for i in 22:
		var x := fmod(37.0 + i * 71.3, tam.x - 40.0) + 20.0
		var y := y_cumbre + 20.0 + fmod(i * 53.7, tam.y - y_cumbre - 40.0)
		if Geometry2D.is_point_in_polygon(Vector2(x, y + 6), montana):
			var verde := Color(0.2, 0.36, 0.2) if y > y_ladera else Color(0.18, 0.3, 0.2)
			lienzo.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, y + 6), Vector2(x, y - 12), Vector2(x + 7, y + 6)]), verde)
	# Límites entre franjas.
	for y in [y_cumbre, y_ladera]:
		for pieza in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([Vector2(-50, y), Vector2(tam.x + 250, y)]), montana):
			lienzo.draw_dashed_line(pieza[0], pieza[1], Color(1, 1, 1, 0.55), 2.0, 10.0)
	# Neblina alrededor de la cumbre.
	for i in 6:
		var centro := cima + Vector2(-150 + i * 55, y_cumbre * 0.75 + (i % 3) * 10)
		lienzo.draw_circle(centro, 34 + (i % 2) * 10, Color(1, 1, 1, 0.28), true, -1.0, true)
	# Arroyo que baja por la parte cálida, con brillo.
	var arroyo := PackedVector2Array()
	for i in 13:
		var f := i / 12.0
		arroyo.append(Vector2(f * tam.x * 0.62, tam.y - 30 + sin(f * TAU * 1.3) * 16 - f * 10))
	lienzo.draw_polyline(arroyo, Color(0.18, 0.42, 0.7), 22.0, true)
	lienzo.draw_polyline(arroyo, Color(0.3, 0.62, 0.95), 16.0, true)
	lienzo.draw_polyline(arroyo, Color(0.75, 0.9, 1.0, 0.7), 3.0, true)
	_etiqueta(Vector2(18, y_cumbre * 0.4), "Frío y neblina")
	_etiqueta(Vector2(18, (y_cumbre + y_ladera) / 2.0), "Ladera")
	_etiqueta(Vector2(18, y_ladera + 34), "Cálido")


## Silueta de montañas lejanas a la altura `base`.
func _cordillera(tam: Vector2, base: float, alto: float, fase: float) -> PackedVector2Array:
	var puntos := PackedVector2Array([Vector2(0, tam.y)])
	for i in 25:
		var x := tam.x * i / 24.0
		puntos.append(Vector2(x, base - alto * (0.5 + 0.3 * sin(i * 0.9 + fase) + 0.2 * sin(i * 2.3 + fase))))
	puntos.append(tam)
	return puntos


## Perfil de la montaña principal: laderas con algunos picos, más allá de los bordes.
func _perfil(tam: Vector2, cima: Vector2) -> PackedVector2Array:
	var izquierda := Vector2(-140, tam.y + 20)
	var derecha := Vector2(tam.x + 250, tam.y + 20)
	var puntos := PackedVector2Array([izquierda])
	for i in range(1, 10):
		var f := i / 10.0
		puntos.append(izquierda.lerp(cima, f) + Vector2(0, (8.0 if i % 2 == 0 else -10.0) * (1.0 - f)))
	puntos.append(cima)
	for i in range(1, 10):
		var f := i / 10.0
		puntos.append(cima.lerp(derecha, f) + Vector2(0, (-9.0 if i % 2 == 0 else 7.0) * f))
	puntos.append(derecha)
	return puntos


func _banda(tam: Vector2, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-200, y0), Vector2(tam.x + 300, y0), Vector2(tam.x + 300, y1), Vector2(-200, y1)])


## Dibuja la parte de `zona` que cae dentro de la montaña.
func _rellenar(montana: PackedVector2Array, zona: PackedVector2Array, color: Color) -> void:
	for pieza in Geometry2D.intersect_polygons(montana, zona):
		lienzo.draw_colored_polygon(pieza, color)


## Texto en una etiqueta oscura redondeada que empieza en `izquierda`.
func _etiqueta(izquierda: Vector2, texto: String) -> void:
	var fuente := lienzo.get_theme_default_font()
	var tam := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	var caja := Rect2(izquierda - Vector2(0, tam.y / 2.0 + 6), Vector2(tam.x + 28, tam.y + 12))
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.1, 0.16, 0.12, 0.72)
	fondo.set_corner_radius_all(14)
	lienzo.draw_style_box(fondo, caja)
	lienzo.draw_string(fuente, caja.position + Vector2(14, 6 + fuente.get_ascent(22)), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.96, 0.85))

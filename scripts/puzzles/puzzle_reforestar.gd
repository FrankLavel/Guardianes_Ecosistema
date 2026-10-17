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
	escenario.draw.connect(_dibujar_montana)


## Montaña con tres franjas: base cálida con arroyo, ladera y cumbre fría con neblina.
func _dibujar_montana() -> void:
	var tam := escenario.size
	escenario.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.62, 0.8, 0.92))
	var cima := Vector2(tam.x * 0.55, 40)
	var base := [Vector2(-20, tam.y), cima, Vector2(tam.x + 20, tam.y)]
	escenario.draw_colored_polygon(PackedVector2Array(base), Color(0.42, 0.55, 0.32))
	# Franja de en medio y cumbre (más fría, más azulada).
	var medio := [Vector2(tam.x * 0.2, tam.y * 0.62), cima, Vector2(tam.x * 0.9, tam.y * 0.62)]
	escenario.draw_colored_polygon(PackedVector2Array(medio), Color(0.47, 0.55, 0.42))
	var cumbre := [Vector2(tam.x * 0.4, tam.y * 0.33), cima, Vector2(tam.x * 0.72, tam.y * 0.33)]
	escenario.draw_colored_polygon(PackedVector2Array(cumbre), Color(0.66, 0.72, 0.74))
	# Neblina arriba.
	for i in 4:
		escenario.draw_circle(cima + Vector2(-90 + i * 60, 40 + (i % 2) * 14), 46, Color(1, 1, 1, 0.35))
	# Arroyo abajo a la izquierda.
	var arroyo := PackedVector2Array([Vector2(0, tam.y - 40), Vector2(160, tam.y - 60), Vector2(330, tam.y - 30), Vector2(460, tam.y)])
	escenario.draw_polyline(arroyo, Color(0.3, 0.6, 0.95), 18.0, true)
	escenario.draw_string(ThemeDB.fallback_font, Vector2(tam.x - 330, 70), "Frío y neblina ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.15, 0.25, 0.35))
	escenario.draw_string(ThemeDB.fallback_font, Vector2(tam.x - 330, tam.y - 24), "Cálido ↓", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.35, 0.2, 0.1))

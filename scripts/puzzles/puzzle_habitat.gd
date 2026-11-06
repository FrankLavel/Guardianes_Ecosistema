class_name PuzzleHabitat
extends PuzzleAsignar
## Puzzle 4 (Zona 2): "¿Quién vive aquí?" Llevar a cada animal a su lugar en el bosque.
## Copa: mariposa monarca · Tronco: pájaro carpintero · Suelo: venado.

const ARBOL := preload("res://assets/maps/valle/objetos/oyamel.png")


func _configurar() -> void:
	opciones = {
		"monarca": {"nombre": "Mariposa monarca", "imagen": "res://assets/ui/bitacora/monarca.png", "destino": "copa",
			"pista": "En invierno, las monarcas se juntan en racimos en las ramas altas de los oyameles para no pasar frío."},
		"carpintero": {"nombre": "Pájaro carpintero", "imagen": "res://assets/ui/bitacora/carpintero.png", "destino": "tronco",
			"pista": "El carpintero pica la madera del tronco para hacer su nido y guardar bellotas."},
		"venado": {"nombre": "Venado", "imagen": "res://assets/ui/bitacora/venado.png", "destino": "suelo",
			"pista": "El venado no trepa ni vuela: camina por el suelo del bosque y come hierbas y bellotas."},
	}
	destinos = {
		"copa": {"nombre": "Copa", "posicion": Vector2(640, 120)},
		"tronco": {"nombre": "Tronco", "posicion": Vector2(640, 330)},
		"suelo": {"nombre": "Suelo", "posicion": Vector2(330, 450)},
	}
	texto_inicio = "En un mismo árbol viven muchos animales, cada uno en su lugar.\nElige un animal y luego dónde vive."
	texto_final = "¡Todos tienen su hogar! Un solo árbol da casa a muchos seres vivos:\npor eso cortar un bosque deja sin hogar a tantos animales."
	especies_al_resolver = ["monarca", "carpintero"]


func _ready() -> void:
	super()
	lienzo.draw.connect(_dibujar_bosque)


func _dibujar_bosque() -> void:
	var tam := lienzo.size
	lienzo.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.6, 0.82, 0.9))
	lienzo.draw_rect(Rect2(0, tam.y - 110, tam.x, 110), Color(0.36, 0.52, 0.26))
	# El oyamel grande, al centro-derecha.
	var alto := tam.y - 30
	var ancho := alto * ARBOL.get_width() / ARBOL.get_height()
	lienzo.draw_texture_rect(ARBOL, Rect2(Vector2(tam.x * 0.744 - ancho / 2.0, 10), Vector2(ancho, alto)), false)

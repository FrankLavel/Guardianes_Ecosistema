class_name Terrenos
extends Node2D
## Cuadrícula de terrenos del valle (ver Granja.terreno_abierto). Solo se ve en el modo decorar: los
## terrenos de la granja con su cuadrícula para acomodar, y en azul los que se pueden comprar (clic
## para expandir).

const LINEA := Color(1, 1, 1, 0.13)
const ORILLA := Color(1, 0.95, 0.75, 0.5)
const AZUL := Color(0.25, 0.85, 0.85, 0.28)
const AZUL_LINEA := Color(0.55, 1, 1, 0.45)
## Tamaño de los cuadritos de la cuadrícula dentro de cada terreno.
const CUADRITO := 50.0

var decorador: Decorador


func _ready() -> void:
	z_index = 1
	visible = false
	Granja.terrenos_cambio.connect(queue_redraw)


func _process(_delta: float) -> void:
	var ver := decorador != null and decorador.activo
	if ver != visible:
		visible = ver
		queue_redraw()


func _draw() -> void:
	for c in Granja.COLUMNAS_TERRENO:
		for f in Granja.FILAS_TERRENO:
			var celda := Vector2i(c, f)
			var r := Granja.rect_de_terreno(celda)
			if Granja.terreno_abierto(celda):
				_cuadricula(r, LINEA)
			elif Granja.se_puede_expandir(celda):
				draw_rect(r.grow(-3), AZUL)
				_cuadricula(r.grow(-3), AZUL_LINEA)
				draw_rect(r.grow(-3), AZUL_LINEA, false, 3.0)
				# Letrero: un "+" en un círculo, como para decir "aquí se puede crecer".
				var centro := r.get_center()
				draw_circle(centro, 34, Color(0.1, 0.45, 0.45, 0.85))
				draw_rect(Rect2(centro - Vector2(18, 5), Vector2(36, 10)), Color.WHITE)
				draw_rect(Rect2(centro - Vector2(5, 18), Vector2(10, 36)), Color.WHITE)
	# La orilla de la granja, para que se vea hasta dónde se puede acomodar.
	for c in Granja.COLUMNAS_TERRENO:
		for f in Granja.FILAS_TERRENO:
			var celda := Vector2i(c, f)
			if not Granja.terreno_abierto(celda):
				continue
			var r := Granja.rect_de_terreno(celda)
			for lado in [[Vector2i(0, -1), r.position, Vector2(r.end.x, r.position.y)], [Vector2i(0, 1), Vector2(r.position.x, r.end.y), r.end],
					[Vector2i(-1, 0), r.position, Vector2(r.position.x, r.end.y)], [Vector2i(1, 0), Vector2(r.end.x, r.position.y), r.end]]:
				if not Granja.terreno_abierto(celda + lado[0]):
					draw_line(lado[1], lado[2], ORILLA, 4.0)


func _cuadricula(r: Rect2, color: Color) -> void:
	var x := r.position.x + CUADRITO
	while x < r.end.x:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), color, 1.5)
		x += CUADRITO
	var y := r.position.y + CUADRITO
	while y < r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), color, 1.5)
		y += CUADRITO

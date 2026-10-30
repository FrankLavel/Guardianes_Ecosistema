class_name MilpaSuelo
extends Node2D
## Tierra arada de la milpa: un solo campo con orilla de madera, partido en cuadros pegados (uno
## por surco) con su lomo y sus surcos. Los cuadros que faltan por desbloquear se ven como tierra
## sin arar. Va debajo de todo (no entra al orden por altura). Regada se ve más oscura.

## Tamaño de cada cuadro (igual a la separación entre surcos, así quedan pegados).
var tam := Vector2(146, 102)
## Centro de cada cuadro del campo completo, en el mismo orden que las parcelas.
var posiciones: Array[Vector2] = []
## Cuántos de esos cuadros ya están arados (los primeros).
var abiertos := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Granja.parcelas_cambio.connect(queue_redraw)


func _draw() -> void:
	if posiciones.is_empty():
		return
	var campo := Rect2(posiciones[0] - tam / 2.0, tam)
	for centro in posiciones:
		campo = campo.expand(centro + tam / 2.0)
	_orilla(campo)
	for i in posiciones.size():
		var caja := Rect2(posiciones[i] - tam / 2.0, tam).grow(-3)
		if i < abiertos:
			_cuadro(caja, bool(Granja.parcela(i)["regada"]))
		else:
			_sin_arar(caja)


## Sombra sobre el pasto, marco de tablas y el fondo oscuro que se ve entre cuadro y cuadro.
func _orilla(campo: Rect2) -> void:
	draw_rect(Rect2(campo.position + Vector2(6, 10), campo.size + Vector2(8, 8)), Color(0, 0, 0, 0.25))
	var madera := campo.grow(14)
	draw_rect(madera, Color8(92, 58, 30))
	draw_rect(Rect2(madera.position, Vector2(madera.size.x, 4)), Color8(150, 104, 58))
	draw_rect(Rect2(madera.position + Vector2(0, madera.size.y - 5), Vector2(madera.size.x, 5)), Color8(58, 34, 16))
	# Vetas y clavos en las tablas.
	var x := madera.position.x + 30.0
	while x < madera.end.x - 10:
		for y: float in [madera.position.y + 7, madera.end.y - 7]:
			draw_rect(Rect2(x, y - 1, 3, 3), Color8(48, 30, 14))
		x += 70.0
	draw_rect(campo.grow(2), Color8(46, 30, 17))
	draw_rect(campo, Color8(62, 40, 22))


## Cuadro arado: tres lomos de tierra (con luz arriba y sombra abajo) separados por el surco.
func _cuadro(caja: Rect2, regada: bool) -> void:
	var base := Color8(110, 70, 40) if regada else Color8(150, 98, 54)
	var luz := Color8(132, 88, 54) if regada else Color8(184, 126, 74)
	var sombra := Color8(60, 38, 22) if regada else Color8(92, 58, 31)
	draw_rect(caja, sombra)
	var fila := (caja.size.y - 6) / 3.0
	for k in 3:
		var lomo := Rect2(caja.position.x + 6, caja.position.y + 4 + k * fila, caja.size.x - 12, fila * 0.72)
		# Puntas redondeadas: dos rectángulos cruzados.
		draw_rect(lomo.grow_individual(-3, 0, -3, 0), base)
		draw_rect(lomo.grow_individual(0, -3, 0, -3), base)
		draw_rect(Rect2(lomo.position.x + 3, lomo.position.y, lomo.size.x - 6, 4), luz)
		draw_rect(Rect2(lomo.position.x + 3, lomo.end.y - 4, lomo.size.x - 6, 4), sombra.lightened(0.12))
	_terrones(caja, luz.lightened(0.12))


## Tierra apisonada, sin surcos, con matitas: lo que se ara al subir de nivel.
func _sin_arar(caja: Rect2) -> void:
	draw_rect(caja, Color8(140, 112, 70))
	draw_rect(Rect2(caja.position.x, caja.end.y - 5, caja.size.x, 5), Color8(112, 88, 52))
	_terrones(caja, Color8(164, 136, 90))
	var semilla := int(caja.position.x * 3 + caja.position.y * 11)
	for k in 4:
		var x := caja.position.x + 12 + (semilla * (k + 2) * 29) % int(caja.size.x - 28)
		var y := caja.position.y + 14 + (semilla * (k + 7) * 41) % int(caja.size.y - 30)
		draw_rect(Rect2(x, y, 3, 8), Color8(92, 130, 52))
		draw_rect(Rect2(x - 4, y + 3, 3, 5), Color8(110, 150, 60))
		draw_rect(Rect2(x + 4, y + 2, 3, 6), Color8(80, 116, 44))


## Terrones sueltos, siempre en el mismo lugar para cada cuadro.
func _terrones(caja: Rect2, color: Color) -> void:
	var semilla := int(caja.position.x * 7 + caja.position.y * 13)
	for k in 5:
		var x := caja.position.x + 10 + (semilla * (k + 3) * 37) % int(caja.size.x - 22)
		var y := caja.position.y + 8 + (semilla * (k + 5) * 53) % int(caja.size.y - 18)
		draw_rect(Rect2(x, y, 4, 3), color)

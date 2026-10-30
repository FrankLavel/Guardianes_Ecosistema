class_name MilpaSuelo
extends Node2D
## Tierra arada de la milpa: un cuadro por surco con su orilla y tres surcos marcados. Va debajo
## de todo (no entra al orden por altura), así el guardián camina encima. Regada se ve más oscura.

const TAM := Vector2(132, 88)

## Centro de cada cuadro, en el mismo orden que las parcelas.
var posiciones: Array[Vector2] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Granja.parcelas_cambio.connect(queue_redraw)


func _draw() -> void:
	for i in posiciones.size():
		_cama(posiciones[i], bool(Granja.parcela(i)["regada"]))


func _cama(centro: Vector2, regada: bool) -> void:
	var caja := Rect2(centro - TAM / 2.0, TAM)
	var base := Color8(78, 52, 32) if regada else Color8(112, 74, 42)
	var cresta := Color8(98, 66, 42) if regada else Color8(140, 94, 54)
	var surco := Color8(56, 37, 23) if regada else Color8(82, 52, 30)
	# Sombra sobre el pasto, orilla oscura y la tierra.
	draw_rect(Rect2(caja.position + Vector2(4, 6), caja.size), Color(0, 0, 0, 0.22))
	draw_rect(caja.grow(4), Color8(54, 34, 18))
	draw_rect(caja, base)
	# Tres surcos: cresta clara arriba y canal oscuro abajo.
	var alto := TAM.y / 3.0
	for k in 3:
		var y := caja.position.y + k * alto
		draw_rect(Rect2(caja.position.x + 4, y + 6, TAM.x - 8, alto * 0.42), cresta)
		draw_rect(Rect2(caja.position.x + 4, y + 6 + alto * 0.42, TAM.x - 8, 4), cresta.lightened(0.12))
		draw_rect(Rect2(caja.position.x + 4, y + alto - 6, TAM.x - 8, 5), surco)
	# Terrones sueltos (siempre en el mismo lugar para cada cuadro).
	var semilla := int(centro.x * 7 + centro.y * 13)
	for k in 6:
		var x := caja.position.x + 8 + (semilla * (k + 3) * 37) % int(TAM.x - 18)
		var y := caja.position.y + 6 + (semilla * (k + 5) * 53) % int(TAM.y - 14)
		draw_rect(Rect2(x, y, 4, 4), cresta.lightened(0.2))
	# Borde de arriba con luz y el de abajo más oscuro: da volumen.
	draw_rect(Rect2(caja.position, Vector2(TAM.x, 3)), cresta.lightened(0.25))
	draw_rect(Rect2(caja.position + Vector2(0, TAM.y - 3), Vector2(TAM.x, 3)), surco.darkened(0.25))

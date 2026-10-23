class_name Estanque
extends Node2D
## Estanque del valle (donde vive Achi): agua con la textura del río, orilla de lodo, piedras y
## tule. No se puede caminar sobre el agua.

const AGUA := preload("res://assets/maps/valle/texturas/agua.png")
const PIEDRAS := preload("res://assets/maps/valle/objetos/piedras.png")
const TULE := preload("res://assets/objects/zona3/tule.png")
const LADOS := 40

## Radios del óvalo de agua.
@export var radios := Vector2(150, 85)


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var cuerpo := StaticBody2D.new()
	var forma := CollisionPolygon2D.new()
	forma.polygon = _ovalo(radios * 0.85)
	cuerpo.add_child(forma)
	add_child(cuerpo)
	# Piedras y tule en la orilla (ángulo en la orilla, tamaño en px).
	for datos in [[PIEDRAS, 2.7, 70.0], [PIEDRAS, 0.35, 56.0], [TULE, 3.6, 110.0], [TULE, 5.6, 90.0], [TULE, 1.2, 80.0]]:
		var adorno := Sprite2D.new()
		var textura: Texture2D = datos[0]
		adorno.texture = textura
		adorno.scale = Vector2.ONE * datos[2] / textura.get_width()
		adorno.offset = Vector2(0, -textura.get_height() / 2.0)
		adorno.position = Vector2(cos(datos[1]), sin(datos[1])) * (radios + Vector2(6, 6))
		adorno.z_index = 1 if adorno.position.y > 0 else 0
		add_child(adorno)


func _ovalo(r: Vector2) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in LADOS:
		var a := TAU * i / LADOS
		# Un poco irregular para que no parezca un óvalo perfecto.
		var bulto := 1.0 + 0.06 * sin(a * 3.0) + 0.04 * cos(a * 5.0)
		puntos.append(Vector2(cos(a) * r.x, sin(a) * r.y) * bulto)
	return puntos


func _draw() -> void:
	draw_colored_polygon(_ovalo(radios + Vector2(18, 14)), Color(0.33, 0.25, 0.14))
	draw_colored_polygon(_ovalo(radios + Vector2(8, 6)), Color(0.45, 0.35, 0.2))
	var agua := _ovalo(radios)
	var uvs := PackedVector2Array()
	for p in agua:
		uvs.append(p / AGUA.get_size())
	draw_polygon(agua, PackedColorArray([Color(0.85, 0.95, 1.0)]), uvs, AGUA)
	# Orilla más oscura (profundidad) y algunos brillos.
	draw_polyline(agua + PackedVector2Array([agua[0]]), Color(0.05, 0.15, 0.3, 0.45), 10.0, true)
	for brillo in [Vector2(-60, -30), Vector2(50, 20), Vector2(-10, 45)]:
		draw_line(brillo, brillo + Vector2(26, 0), Color(1, 1, 1, 0.5), 3.0)

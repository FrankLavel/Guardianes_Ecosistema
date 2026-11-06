class_name Decoracion
extends Node2D
## Una decoración que el jugador puso en la granja (se pone y se mueve en el modo decorar, ver
## Decorador). El farol además alumbra de noche.

const DIBUJO := "res://assets/maps/valle/decoraciones/%s.png"

var id := "cempasuchil"
## Lo que quedó guardado en Juego.decoraciones["puestas"] ({} mientras todavía está en la mano).
var puesta: Dictionary = {}

## Volteada como en un espejo (botón GIRAR del modo decorar).
var girada := false:
	set(valor):
		girada = valor
		if _dibujo:
			_dibujo.flip_h = valor

var _dibujo: Sprite2D
var _luz: PointLight2D


func _ready() -> void:
	add_to_group(&"movible")
	_dibujo = Sprite2D.new()
	_dibujo.texture = load(DIBUJO % id)
	_dibujo.scale = Vector2.ONE * _ancho() / _dibujo.texture.get_width()
	_dibujo.offset = Vector2(0, -_dibujo.texture.get_height() / 2.0)
	add_child(_dibujo)
	girada = bool(puesta.get("girada", girada))
	if id == "farol":
		var degradado := Gradient.new()
		degradado.set_color(0, Color(1, 0.85, 0.5, 1))
		degradado.set_color(1, Color(1, 0.7, 0.3, 0))
		var textura := GradientTexture2D.new()
		textura.gradient = degradado
		textura.fill = GradientTexture2D.FILL_RADIAL
		textura.fill_from = Vector2(0.5, 0.5)
		textura.fill_to = Vector2(1.0, 0.5)
		textura.width = 256
		textura.height = 256
		_luz = PointLight2D.new()
		_luz.texture = textura
		_luz.energy = 0.9
		_luz.texture_scale = 1.3
		_luz.position = Vector2(0, -100)
		add_child(_luz)


func _process(_delta: float) -> void:
	if _luz:
		_luz.enabled = Juego.hora >= 19.0 or Juego.hora < 6.0


func _ancho() -> float:
	return float(Granja.datos["decoraciones"][id]["ancho"])


## Lo que ocupa en el piso (para que nada se le encime).
func huella() -> Rect2:
	return Rect2(global_position + Vector2(-_ancho() / 2.0, -18), Vector2(_ancho(), 26))


## Si el mouse está sobre el dibujo (para agarrarla).
func contiene(punto: Vector2) -> bool:
	var alto := _dibujo.texture.get_height() * _dibujo.scale.y
	return Rect2(global_position + Vector2(-_ancho() / 2.0, -alto), Vector2(_ancho(), alto)).has_point(punto)

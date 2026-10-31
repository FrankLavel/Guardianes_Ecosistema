class_name LugarDecorar
extends ZonaInteraccion
## Un lugar de la granja para poner una decoración (ver Granja.abrir_decorar). Vacío se ve como un
## cuadrito de tierra; el farol además alumbra de noche.

const DIBUJO := "res://assets/maps/valle/decoraciones/%s.png"

@export var indice := 0

var _dibujo: Sprite2D
var _luz: PointLight2D


func _ready() -> void:
	_dibujo = Sprite2D.new()
	add_child(_dibujo)
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1, 0.85, 0.5, 1))
	degradado.set_color(1, Color(1, 0.7, 0.3, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	_luz = PointLight2D.new()
	_luz.texture = textura
	_luz.energy = 0.8
	_luz.position = Vector2(0, -70)
	add_child(_luz)
	super()
	actualizar()
	Granja.decoraciones_cambio.connect(actualizar)


func _process(_delta: float) -> void:
	_luz.enabled = Granja.decoracion_en(indice) == "farol" and (Juego.hora >= 19.0 or Juego.hora < 6.0)


func actualizar() -> void:
	var id := Granja.decoracion_en(indice)
	_dibujo.texture = load(DIBUJO % id) if not id.is_empty() and ResourceLoader.exists(DIBUJO % id) else null
	if _dibujo.texture:
		_dibujo.scale = Vector2.ONE * float(Granja.datos["decoraciones"][id]["ancho"]) / _dibujo.texture.get_width()
		_dibujo.offset = Vector2(0, -_dibujo.texture.get_height() / 2.0)
	_aviso.text = "E  Decorar" if id.is_empty() else "E  " + Granja.datos["decoraciones"][id]["nombre"]
	queue_redraw()


## El lugar vacío: un cuadrito de tierra con orilla, para que se vea que ahí se puede poner algo.
func _draw() -> void:
	if not Granja.decoracion_en(indice).is_empty():
		return
	var cuadro := Rect2(-26, -14, 52, 28)
	draw_rect(cuadro, Color(0.42, 0.29, 0.17, 0.55))
	draw_rect(cuadro, Color(0.85, 0.72, 0.45, 0.7), false, 2.0)


func _al_interactuar(_jugador: Node2D) -> void:
	Granja.abrir_decorar(indice)

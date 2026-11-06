class_name CapaFondo
extends Control
## Una capa del fondo con profundidad (paralaje). Se repite en horizontal y se mueve más lento
## que la cámara. Tiene versión limpia y contaminada: `limpieza` mezcla entre las dos.

## Qué tanto se mueve con la cámara (0 = fija, 1 = igual que el mundo).
@export_range(0.0, 1.0) var factor := 0.3
## Alto de la capa en pantalla (px de la resolución base 1920x1080).
@export var alto_en_pantalla := 600.0
## Distancia desde el borde inferior de la pantalla.
@export var separacion_abajo := 0.0
@export var textura_limpia: Texture2D
@export var textura_contaminada: Texture2D

var limpieza := 0.0:
	set(valor):
		limpieza = clampf(valor, 0.0, 1.0)
		if _contaminada:
			_contaminada.modulate.a = 1.0 - limpieza

var _limpia: TextureRect
var _contaminada: TextureRect
var _escala := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_limpia = _crear(textura_limpia)
	_contaminada = _crear(textura_contaminada)
	limpieza = limpieza
	_ajustar()
	get_viewport().size_changed.connect(_ajustar)


func _crear(textura: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = textura
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(rect)
	return rect


func _ajustar() -> void:
	if textura_limpia == null:
		return
	var pantalla := get_viewport_rect().size
	_escala = alto_en_pantalla / textura_limpia.get_height()
	scale = Vector2(_escala, _escala)
	position.y = pantalla.y - separacion_abajo - alto_en_pantalla
	var ancho := pantalla.x / _escala + textura_limpia.get_width() * 2
	for rect in [_limpia, _contaminada]:
		if rect and rect.texture:
			# La contaminada puede ser más alta; se alinea por abajo con la limpia.
			var alto := float(rect.texture.get_height())
			rect.position = Vector2(0, textura_limpia.get_height() - alto)
			rect.size = Vector2(ancho, alto)


func desplazar(camara_x: float) -> void:
	if textura_limpia == null:
		return
	var ancho_tile := textura_limpia.get_width() * _escala
	position.x = -fposmod(camara_x * factor, ancho_tile)

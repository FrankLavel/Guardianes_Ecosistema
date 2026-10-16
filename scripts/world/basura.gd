class_name Basura
extends Area2D
## Basura que el guardián puede recoger con la acción "interactuar".

signal recogida(basura: Basura)

## Clave en data/basura.json y nombre del SVG en assets/objects/basura/.
@export_enum("botella", "lata", "bolsa", "pila", "unicel") var tipo := "botella"

## Alto de la basura en el mundo (Gara mide ~53).
const ALTO_EN_JUEGO := 26.0

var fue_recogida := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _aviso: Label = $Aviso


func _ready() -> void:
	add_to_group(&"basura")
	_sprite.texture = load("res://assets/objects/basura/%s.png" % tipo)
	# Todas las basuras miden lo mismo en el juego, sin importar el tamaño de su imagen.
	var escala := ALTO_EN_JUEGO / _sprite.texture.get_height()
	_sprite.scale = Vector2(escala, escala)
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func datos() -> Dictionary:
	return DatosBasura.obtener(tipo)


func interactuar(guardian: Guardian) -> void:
	if fue_recogida:
		return
	fue_recogida = true
	guardian.quitar_interactuable(self)
	_aviso.visible = false
	set_deferred("monitoring", false)
	recogida.emit(self)
	var animacion := create_tween().set_parallel()
	animacion.tween_property(_sprite, "position:y", _sprite.position.y - 24.0, 0.3)
	animacion.tween_property(_sprite, "modulate:a", 0.0, 0.3)
	animacion.chain().tween_callback(queue_free)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not fue_recogida:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

class_name Lirio
extends Area2D
## Lirio acuático: planta invasora que cubre el lago y tapa la luz. Se quita nadando cerca de
## la superficie y presionando E.

signal quitado

var esta_quitado := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	# Se mece con el agua.
	var vaiven := create_tween().set_loops()
	vaiven.tween_property(_sprite, "position:y", _sprite.position.y + 3.0, 1.2).set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(_sprite, "position:y", _sprite.position.y, 1.2).set_trans(Tween.TRANS_SINE)


func interactuar(guardian: Node) -> void:
	if esta_quitado:
		return
	esta_quitado = true
	_aviso.visible = false
	if guardian.has_method("quitar_interactuable"):
		guardian.quitar_interactuable(self)
	Sonido.efecto("recoger")
	quitado.emit()
	var salida := create_tween().set_parallel()
	salida.tween_property(_sprite, "position:y", _sprite.position.y - 30.0, 0.4)
	salida.tween_property(_sprite, "modulate:a", 0.0, 0.4)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not esta_quitado:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

class_name Fogata
extends Area2D
## Fogata mal apagada que cierra el paso. Se apaga echándole tierra (interactuar).

signal apagada

var esta_apagada := false

@onready var _fuego: CPUParticles2D = $Fuego
@onready var _humo: CPUParticles2D = $Humo
@onready var _luz: Sprite2D = $Luz
@onready var _imagen: Sprite2D = $Imagen
@onready var _bloqueo: CollisionShape2D = $Bloqueo/CollisionShape2D
@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var parpadeo := create_tween().set_loops()
	parpadeo.tween_property(_luz, "modulate:a", 0.6, 0.15)
	parpadeo.tween_property(_luz, "modulate:a", 1.0, 0.2)


func interactuar(guardian: Node) -> void:
	if esta_apagada:
		return
	esta_apagada = true
	_aviso.visible = false
	if guardian.has_method("quitar_interactuable"):
		guardian.quitar_interactuable(self)
	_fuego.emitting = false
	_imagen.texture = preload("res://assets/objects/zona2/fogata_apagada.png")
	_humo.amount = 30
	_humo.emitting = true
	create_tween().tween_property(_luz, "modulate:a", 0.0, 0.6)
	_bloqueo.set_deferred("disabled", true)
	Sonido.efecto("chapoteo")
	apagada.emit()
	await get_tree().create_timer(2.5).timeout
	_humo.emitting = false


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not esta_apagada:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

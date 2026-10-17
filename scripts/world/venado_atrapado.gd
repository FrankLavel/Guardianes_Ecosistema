class_name VenadoAtrapado
extends Area2D
## Venado atorado entre alambre de púas viejo. Al liberarlo corre hacia el bosque.

signal liberado

var esta_libre := false

@onready var _venado: Sprite2D = $Venado
@onready var _alambre: Line2D = $Alambre
@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	# Forcejea para soltarse.
	var forcejeo := create_tween().set_loops()
	forcejeo.tween_property(_venado, "rotation", 0.06, 0.25)
	forcejeo.tween_property(_venado, "rotation", -0.06, 0.25)


func interactuar(guardian: Node) -> void:
	if esta_libre:
		return
	esta_libre = true
	_aviso.visible = false
	if guardian.has_method("quitar_interactuable"):
		guardian.quitar_interactuable(self)
	Sonido.efecto("correcto")
	_alambre.visible = false
	liberado.emit()
	var huida := create_tween()
	huida.tween_property(_venado, "rotation", 0.0, 0.1)
	huida.tween_property(_venado, "position:x", _venado.position.x + 420.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	huida.parallel().tween_property(_venado, "modulate:a", 0.0, 1.6)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not esta_libre:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

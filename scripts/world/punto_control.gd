class_name PuntoControl
extends Area2D
## Al pasar por aquí, el guardián reaparecerá en este punto si cae al río.


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.punto_reaparicion = global_position

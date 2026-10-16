class_name PuntoControl
extends Area2D
## Al pasar por aquí, el guardián reaparecerá en este punto si cae al río.


func _ready() -> void:
	body_entered.connect(_al_entrar)
	var brillo := get_node_or_null("Brillo")
	if brillo:
		var pulso := create_tween().set_loops()
		pulso.tween_property(brillo, "modulate:a", 0.45, 1.1).set_trans(Tween.TRANS_SINE)
		pulso.tween_property(brillo, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.punto_reaparicion = global_position

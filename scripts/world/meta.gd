class_name Meta
extends Area2D
## Final del nivel: avisa cuando el guardián llega.

signal guardian_llego(guardian: Guardian)


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		guardian_llego.emit(cuerpo)

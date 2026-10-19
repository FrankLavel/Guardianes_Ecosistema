class_name HuevoAchoque
extends Area2D
## Huevo de achoque en el fondo del lago. Se rescata al tocarlo nadando.

signal rescatado

var esta_rescatado := false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _brillo: Sprite2D = $Brillo


func _ready() -> void:
	body_entered.connect(_al_entrar)
	var pulso := create_tween().set_loops()
	pulso.tween_property(_brillo, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(_brillo, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)


func _al_entrar(cuerpo: Node2D) -> void:
	if not cuerpo is Guardian or esta_rescatado:
		return
	esta_rescatado = true
	Sonido.efecto("punto_control")
	rescatado.emit()
	var salida := create_tween().set_parallel()
	salida.tween_property(self, "position:y", position.y - 40.0, 0.5)
	salida.tween_property(self, "modulate:a", 0.0, 0.5)
	salida.chain().tween_callback(func(): visible = false)

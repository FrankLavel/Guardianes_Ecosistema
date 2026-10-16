extends CanvasLayer
## Cambio de escena con fundido a negro (autoload "Transicion").

signal termino

const DURACION := 0.35

var en_curso := false

@onready var _cortina: ColorRect = $Cortina


func _ready() -> void:
	_cortina.modulate.a = 0.0
	_cortina.visible = false


func ir_a(ruta: String) -> void:
	if en_curso:
		return
	en_curso = true
	_cortina.visible = true
	var fundido := create_tween()
	fundido.tween_property(_cortina, "modulate:a", 1.0, DURACION)
	await fundido.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame
	fundido = create_tween()
	fundido.tween_property(_cortina, "modulate:a", 0.0, DURACION)
	await fundido.finished
	_cortina.visible = false
	en_curso = false
	termino.emit()

extends Control

const ESCENA_NIVEL1 := "res://scenes/world/Nivel1.tscn"
const ESCENA_OPCIONES := "res://scenes/ui/Opciones.tscn"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_salir_pressed() -> void:
	get_tree().quit()


func _on_btn_jugar_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_NIVEL1)


func _on_btn_opciones_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_OPCIONES)

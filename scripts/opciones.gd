extends Control

const ESCENA_MENU := "res://scenes/menu/menu_principal.tscn"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_check_pantalla_completa_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_slider_volumen_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
	AudioServer.get_bus_index("Master"),
	linear_to_db(value / 100.0)
)


func _on_btn_volver_pressed() -> void:
	Transicion.ir_a(ESCENA_MENU)

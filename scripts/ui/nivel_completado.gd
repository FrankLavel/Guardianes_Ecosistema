class_name NivelCompletado
extends CanvasLayer
## Pantalla final del nivel: refuerza lo aprendido y regresa al menú.

const ESCENA_MENU := "res://scenes/menu/menu_principal.tscn"

@onready var _boton_menu: Button = %BtnMenu


func _ready() -> void:
	visible = false
	_boton_menu.pressed.connect(_al_volver_al_menu)


func mostrar() -> void:
	visible = true
	get_tree().paused = true
	_boton_menu.grab_focus()


func _al_volver_al_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)

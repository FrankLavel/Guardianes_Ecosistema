class_name MenuPausa
extends CanvasLayer
## Menú de pausa (Esc / Start). Se agrega a las escenas jugables: el valle y las zonas.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_MENU := "res://scenes/menu/menu_principal.tscn"

## Mostrar "Volver al valle" (solo dentro de una zona).
@export var permitir_volver_al_valle := true

@onready var _boton_continuar: Button = %BtnContinuar
@onready var _boton_valle: Button = %BtnValle
@onready var _boton_menu: Button = %BtnMenu


func _ready() -> void:
	visible = false
	_boton_valle.visible = permitir_volver_al_valle
	_boton_continuar.pressed.connect(cerrar)
	_boton_valle.pressed.connect(_ir.bind(ESCENA_VALLE))
	_boton_menu.pressed.connect(_ir.bind(ESCENA_MENU))


func _unhandled_input(evento: InputEvent) -> void:
	if not evento.is_action_pressed("pausa"):
		return
	if visible:
		cerrar()
	elif not Dialogo.activo and not Transicion.en_curso and not get_tree().paused:
		abrir()
	else:
		return
	get_viewport().set_input_as_handled()


func abrir() -> void:
	visible = true
	get_tree().paused = true
	_boton_continuar.grab_focus()


func cerrar() -> void:
	visible = false
	get_tree().paused = false


func _ir(ruta: String) -> void:
	Juego.guardar()
	Transicion.ir_a(ruta)

class_name NivelCompletado
extends CanvasLayer
## Pantalla final del nivel: refuerza lo aprendido y regresa al menú.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"

## Meta que se cumple al terminar el nivel. La zona se restaura después, en el valle
## (por ejemplo, el río necesita además el filtro de Don Chucho).
@export var marca := "rio_nivel"

@onready var _boton_menu: Button = %BtnMenu


func _ready() -> void:
	visible = false
	_boton_menu.pressed.connect(_al_volver_al_menu)


func mostrar() -> void:
	Juego.marcar(marca)
	Juego.guardar()
	for etiqueta in [%Titulo, %Aprendizaje]:
		etiqueta.text = Juego.reemplazar(etiqueta.text)
	visible = true
	Sonido.efecto("zona_restaurada")
	get_tree().paused = true
	_boton_menu.grab_focus()


func _al_volver_al_menu() -> void:
	Transicion.ir_a(ESCENA_VALLE)

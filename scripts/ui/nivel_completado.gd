class_name NivelCompletado
extends CanvasLayer
## Pantalla final del nivel: refuerza lo aprendido y regresa al menú.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"

## Zona que se marca como restaurada al mostrar esta pantalla.
@export_enum("rio", "bosque", "lago") var zona := "rio"

@onready var _boton_menu: Button = %BtnMenu


func _ready() -> void:
	visible = false
	_boton_menu.pressed.connect(_al_volver_al_menu)


func mostrar() -> void:
	Juego.completar_zona(zona)
	for etiqueta in [%Titulo, %Aprendizaje]:
		etiqueta.text = Juego.reemplazar(etiqueta.text)
	visible = true
	get_tree().paused = true
	_boton_menu.grab_focus()


func _al_volver_al_menu() -> void:
	Transicion.ir_a(ESCENA_VALLE)

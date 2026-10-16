extends Control

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_NIVEL1 := "res://scenes/world/Nivel1.tscn"
const ESCENA_OPCIONES := "res://scenes/ui/Opciones.tscn"

@onready var _boton_continuar: Button = %BtnContinuar
@onready var _boton_nueva: Button = %BtnJugar
@onready var _logo: TextureRect = %Logo


func _ready() -> void:
	_boton_continuar.visible = Juego.existe_partida()
	(_boton_continuar if _boton_continuar.visible else _boton_nueva).grab_focus()
	# El logo "respira" un poco para que el menú no se sienta estático.
	var animacion := create_tween().set_loops()
	animacion.tween_property(_logo, "scale", Vector2(1.03, 1.03), 1.6).set_trans(Tween.TRANS_SINE)
	animacion.tween_property(_logo, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)


func _on_btn_continuar_pressed() -> void:
	if Juego.cargar():
		Transicion.ir_a(ESCENA_VALLE)


func _on_btn_jugar_pressed() -> void:
	Juego.nueva_partida()
	Juego.guardar()
	Transicion.ir_a(ESCENA_VALLE)


func _on_btn_opciones_pressed() -> void:
	Transicion.ir_a(ESCENA_OPCIONES)


func _on_btn_salir_pressed() -> void:
	get_tree().quit()

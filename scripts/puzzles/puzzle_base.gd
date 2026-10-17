class_name PuzzleBase
extends CanvasLayer
## Base de los puzzles en pantalla: pausa el juego mientras está abierto, se cierra con Esc
## y avisa con `resuelto` cuando el jugador lo completa.

signal resuelto
signal cerrado

var esta_resuelto := false
var _musica_anterior := ""

@onready var mensaje: Label = %Mensaje
@onready var boton_cerrar: Button = %BtnCerrar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	visible = false
	boton_cerrar.pressed.connect(cerrar)


func abrir() -> void:
	visible = true
	get_tree().paused = true
	Juego.entrada_bloqueada = true
	_musica_anterior = Sonido.musica_actual
	Sonido.musica("puzzle")
	_al_abrir()


func cerrar() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	if _musica_anterior != "":
		Sonido.musica(_musica_anterior)
	# Un cuadro de espera para que la tecla que cerró el puzzle no active nada más.
	await get_tree().process_frame
	Juego.entrada_bloqueada = false
	cerrado.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()


func decir(texto: String, color := Color(1, 0.97, 0.88)) -> void:
	mensaje.text = Juego.reemplazar(texto)
	mensaje.modulate = color


func resolver() -> void:
	if esta_resuelto:
		return
	esta_resuelto = true
	Sonido.efecto("correcto")
	resuelto.emit()
	boton_cerrar.text = "CONTINUAR"
	boton_cerrar.grab_focus()


func fallar(texto: String) -> void:
	Sonido.efecto("incorrecto")
	decir(texto, Color(1, 0.75, 0.6))


## Para cada puzzle.
func _al_abrir() -> void:
	pass

extends Control
## Opciones: volumen general, de música y de efectos, y pantalla completa.
## Se guardan en user://opciones.cfg (las aplica el autoload Sonido al iniciar el juego).

const ESCENA_MENU := "res://scenes/menu/menu_principal.tscn"

@onready var _general: HSlider = %SliderVolumen
@onready var _musica: HSlider = %SliderMusica
@onready var _efectos: HSlider = %SliderEfectos
@onready var _pantalla: CheckButton = %CheckPantallaCompleta


func _ready() -> void:
	Sonido.musica("valle")
	_general.set_value_no_signal(Sonido.opciones["Master"] * 100.0)
	_musica.set_value_no_signal(Sonido.opciones["Musica"] * 100.0)
	_efectos.set_value_no_signal(Sonido.opciones["Efectos"] * 100.0)
	_pantalla.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	_musica.value_changed.connect(func(v): _cambiar("Musica", v))
	_efectos.value_changed.connect(func(v):
		_cambiar("Efectos", v)
		Sonido.efecto("recoger"))
	_general.grab_focus()


func _cambiar(bus: String, valor: float) -> void:
	Sonido.fijar_volumen(bus, valor / 100.0)
	Sonido.guardar_opciones()


func _on_check_pantalla_completa_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_slider_volumen_value_changed(value: float) -> void:
	_cambiar("Master", value)


func _on_btn_volver_pressed() -> void:
	Transicion.ir_a(ESCENA_MENU)

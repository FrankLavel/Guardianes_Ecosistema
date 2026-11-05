extends CanvasLayer
## Controles táctiles (autoload "Tactil"): en pantallas táctiles (Android) aparece un joystick a la
## izquierda para caminar y botones a la derecha para las teclas del juego (E, saltar, mochila,
## bitácora y pausa). Cada botón presiona la misma acción que su tecla, así el juego no distingue
## entre teclado y pantalla. Se pueden usar varios dedos a la vez (caminar y saltar).
## Se esconden en los menús, diálogos y minijuegos, que se usan tocando sus botones.

## Para probar en la computadora: TACTIL=1 en el entorno.
var activo := false

## Radio del joystick y cuánto hay que moverlo para que cuente.
const RADIO := 110.0
const ZONA_MUERTA := 0.22
const COLOR_BASE := Color(0.1, 0.07, 0.04, 0.45)
const COLOR_BORDE := Color(1, 0.95, 0.8, 0.55)

var _joystick: Control
var _palanca := Vector2.ZERO
var _dedo := -1
var _centro := Vector2.ZERO
var _botones: Dictionary = {}


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	activo = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.get_environment("TACTIL") == "1"
	if not activo:
		return
	_joystick = Control.new()
	_joystick.name = "Joystick"
	# Detiene el "clic" que el toque simula, para que el dedo del joystick no toque nada del mundo.
	_joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	_joystick.draw.connect(_dibujar_joystick)
	add_child(_joystick)
	for datos in [
		["interactuar", "E", 78.0],
		["saltar", "SALTAR", 78.0],
		["mochila", "MOCHILA", 60.0],
		["bitacora", "BITÁCORA", 60.0],
		["pausa", "PAUSA", 60.0],
	]:
		_botones[datos[0]] = _boton(datos[0], datos[1], datos[2])
	get_viewport().size_changed.connect(_acomodar)
	_acomodar()


## Botón redondo que presiona una acción mientras el dedo está encima.
func _boton(accion: String, texto: String, radio: float) -> TouchScreenButton:
	var boton := TouchScreenButton.new()
	boton.name = "Boton_" + accion
	boton.action = accion
	boton.texture_normal = _circulo(radio, Color(0.16, 0.38, 0.14, 0.7), Color(0.75, 1, 0.6, 0.85))
	boton.texture_pressed = _circulo(radio, Color(0.3, 0.6, 0.22, 0.85), Color(1, 1, 0.8, 1))
	boton.passby_press = true
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 34 if radio > 70.0 else 19)
	etiqueta.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
	etiqueta.add_theme_constant_override("outline_size", 6)
	etiqueta.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04))
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.size = Vector2(radio * 2, radio * 2)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton.add_child(etiqueta)
	add_child(boton)
	return boton


func _circulo(radio: float, relleno: Color, borde: Color) -> ImageTexture:
	var lado := int(radio * 2)
	var imagen := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var centro := Vector2(radio, radio)
	for y in lado:
		for x in lado:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(centro)
			if d <= radio:
				imagen.set_pixel(x, y, borde if d > radio - 5.0 else relleno)
	return ImageTexture.create_from_image(imagen)


## Abajo a la izquierda el joystick; abajo a la derecha E y saltar; arriba de ellos, en columna, pausa,
## bitácora y mochila (debajo del letrero del objetivo).
func _acomodar() -> void:
	var tam := get_viewport().get_visible_rect().size
	_centro = Vector2(70 + RADIO, tam.y - 70 - RADIO)
	_joystick.position = _centro - Vector2.ONE * RADIO * 1.6
	_joystick.size = Vector2.ONE * RADIO * 3.2
	_poner("interactuar", Vector2(tam.x - 120, tam.y - 260))
	_poner("saltar", Vector2(tam.x - 290, tam.y - 130))
	_poner("pausa", Vector2(tam.x - 80, 230))
	_poner("bitacora", Vector2(tam.x - 80, 370))
	_poner("mochila", Vector2(tam.x - 80, 510))


func _poner(accion: String, centro: Vector2) -> void:
	var boton: TouchScreenButton = _botones[accion]
	var radio := boton.texture_normal.get_width() / 2.0
	boton.position = centro - Vector2(radio, radio)


func _process(_delta: float) -> void:
	if not activo:
		return
	var escena := get_tree().current_scene
	var jugando := escena != null and escena.is_in_group(&"jugable") and not get_tree().paused \
		and not Juego.entrada_bloqueada and not Dialogo.activo and not Transicion.en_curso
	var en_valle := jugando and escena.is_in_group(&"con_reloj")
	_joystick.visible = jugando
	_botones["interactuar"].visible = jugando
	_botones["saltar"].visible = jugando and not en_valle
	_botones["mochila"].visible = en_valle and Juego.zona_esta_completa("rio")
	_botones["bitacora"].visible = jugando
	_botones["pausa"].visible = jugando
	if not jugando and _dedo >= 0:
		_soltar_joystick()
	# Los letreros de teclas no sirven en el celular.
	if escena:
		var ayuda := escena.find_child("Ayuda", true, false)
		if ayuda is Label:
			ayuda.visible = false


func _input(evento: InputEvent) -> void:
	if not activo or not _joystick.visible:
		return
	if evento is InputEventScreenTouch:
		if evento.pressed and _dedo < 0 and evento.position.distance_to(_centro) < RADIO * 1.6:
			_dedo = evento.index
			_mover_palanca(evento.position)
			get_viewport().set_input_as_handled()
		elif not evento.pressed and evento.index == _dedo:
			_soltar_joystick()
			get_viewport().set_input_as_handled()
	elif evento is InputEventScreenDrag and evento.index == _dedo:
		_mover_palanca(evento.position)
		get_viewport().set_input_as_handled()


func _mover_palanca(punto: Vector2) -> void:
	_palanca = (punto - _centro).limit_length(RADIO) / RADIO
	var dir := _palanca if _palanca.length() > ZONA_MUERTA else Vector2.ZERO
	_presionar("mover_derecha", maxf(dir.x, 0.0))
	_presionar("mover_izquierda", maxf(-dir.x, 0.0))
	_presionar("mover_abajo", maxf(dir.y, 0.0))
	_presionar("mover_arriba", maxf(-dir.y, 0.0))
	_joystick.queue_redraw()


func _presionar(accion: String, fuerza: float) -> void:
	if fuerza > 0.0:
		Input.action_press(accion, fuerza)
	else:
		Input.action_release(accion)


func _soltar_joystick() -> void:
	_dedo = -1
	_palanca = Vector2.ZERO
	for accion in ["mover_derecha", "mover_izquierda", "mover_abajo", "mover_arriba"]:
		Input.action_release(accion)
	_joystick.queue_redraw()


func _dibujar_joystick() -> void:
	var c := _centro - _joystick.position
	_joystick.draw_circle(c, RADIO, COLOR_BASE)
	_joystick.draw_arc(c, RADIO, 0, TAU, 64, COLOR_BORDE, 4.0)
	_joystick.draw_circle(c + _palanca * RADIO, RADIO * 0.45, Color(0.75, 1, 0.6, 0.75))
	_joystick.draw_arc(c + _palanca * RADIO, RADIO * 0.45, 0, TAU, 48, Color(1, 1, 0.85, 0.9), 3.0)

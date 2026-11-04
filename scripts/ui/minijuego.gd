class_name Minijuego
extends Control
## Minijuego corto para preparar algo de la granja (ver Granja.jugar). Tres formas de jugar:
##   "machacar": presionar E (o hacer clic) muchas veces, como moler o palmear masa.
##   "revolver": alternar ← y → (A y D, o clic a cada lado), como revolver la olla.
##   "atinar":   presionar E (o clic) cuando la marca pasa por lo verde, como jalar la caña.
## "escena" dice qué se dibuja: "molino", "olla", "leche", "comal", "agua" o "panal".

signal terminado(exito: bool)

var tipo := "machacar"
var escena := "molino"
var titulo := ""
var instruccion := ""
## Lo que entra y lo que sale (texturas; la segunda puede faltar).
var iconos: Array = []
var meta := 10
## Cuántas veces se puede fallar al atinar (0 = sin límite).
var fallas_max := 0

var progreso := 0
var fallas := 0
var _lado := -1
var _marca := 0.0
var _sentido := 1.0
var _zona := Vector2(0.4, 0.62)
var _tiempo := 0.0
var _golpe := 0.0
var _error := 0.0
var _giro := 0.0
var _listo := false
var _dibujo: Control
var _barra: Control
var _estado: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.gui_input.connect(_al_clic)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.14, 0.08, 0.97)
	estilo.border_color = Color(0.55, 0.38, 0.18)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(14)
	estilo.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", estilo)
	panel.custom_minimum_size = Vector2(860, 0)
	panel.gui_input.connect(_al_clic)
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	panel.add_child(columna)
	columna.add_child(_texto(titulo, 36, Color(0.99, 0.86, 0.45)))
	columna.add_child(_texto(instruccion, 24, Color(0.85, 0.95, 0.8)))
	_dibujo = Control.new()
	_dibujo.custom_minimum_size = Vector2(800, 300)
	_dibujo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dibujo.draw.connect(_dibujar_escena)
	columna.add_child(_dibujo)
	_barra = Control.new()
	_barra.custom_minimum_size = Vector2(800, 44)
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra.draw.connect(_dibujar_barra)
	columna.add_child(_barra)
	_estado = _texto("", 26, Color(1, 0.96, 0.86))
	columna.add_child(_estado)
	var salir := Button.new()
	salir.text = "SALIR"
	salir.add_theme_font_size_override("font_size", 22)
	salir.custom_minimum_size = Vector2(160, 46)
	salir.focus_mode = Control.FOCUS_NONE
	salir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	salir.pressed.connect(_terminar.bind(false))
	columna.add_child(salir)
	if tipo == "atinar":
		_nueva_zona()
	_actualizar_estado()


func _texto(texto: String, tam: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta


func _input(evento: InputEvent) -> void:
	if _listo:
		return
	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		_terminar(false)
	elif tipo == "revolver" and evento.is_action_pressed("mover_izquierda"):
		revolver(-1)
	elif tipo == "revolver" and evento.is_action_pressed("mover_derecha"):
		revolver(1)
	elif tipo != "revolver" and (evento.is_action_pressed("interactuar") or evento.is_action_pressed("ui_accept")):
		accion()
	else:
		return
	get_viewport().set_input_as_handled()


func _al_clic(evento: InputEvent) -> void:
	if _listo or not (evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT):
		return
	if tipo == "revolver":
		revolver(-1 if get_global_mouse_position().x < _dibujo.get_global_rect().get_center().x else 1)
	else:
		accion()


func _process(delta: float) -> void:
	_tiempo += delta
	_golpe = move_toward(_golpe, 0.0, delta * 3.0)
	_error = move_toward(_error, 0.0, delta * 2.5)
	if tipo == "atinar" and not _listo:
		# Cada acierto la marca va un poquito más rápido.
		_marca += _sentido * delta * (0.55 + 0.12 * progreso)
		if _marca >= 1.0 or _marca <= 0.0:
			_marca = clampf(_marca, 0.0, 1.0)
			_sentido = -_sentido
	_dibujo.queue_redraw()
	_barra.queue_redraw()


## Machacar: un golpe más. Atinar: acierta si la marca está en lo verde.
func accion() -> void:
	if _listo:
		return
	if tipo == "machacar":
		progreso += 1
		_golpe = 1.0
		_giro += 0.9
		Sonido.efecto("boton", 0.15)
	elif _zona.x <= _marca and _marca <= _zona.y:
		progreso += 1
		_golpe = 1.0
		Sonido.efecto("correcto")
		_nueva_zona()
	else:
		fallas += 1
		_error = 1.0
		Sonido.efecto("incorrecto")
		if fallas_max > 0 and fallas >= fallas_max:
			_actualizar_estado()
			_terminar(false)
			return
	_actualizar_estado()
	if progreso >= meta:
		_ganar()


## Revolver: cuenta solo si se presiona el lado que toca (izquierda, derecha, izquierda...).
func revolver(lado: int) -> void:
	if _listo:
		return
	if lado != _lado:
		_error = 0.6
		return
	_lado = -_lado
	progreso += 1
	_golpe = 1.0
	_giro += 0.8
	Sonido.efecto("boton", 0.15)
	_actualizar_estado()
	if progreso >= meta:
		_ganar()


func _nueva_zona() -> void:
	var centro := randf_range(0.2, 0.8)
	_zona = Vector2(centro - 0.11, centro + 0.11)


func _actualizar_estado() -> void:
	var texto := "%d / %d" % [mini(progreso, meta), meta]
	if tipo == "atinar" and fallas_max > 0:
		texto += "   ·   Intentos que te quedan: %d" % maxi(fallas_max - fallas, 0)
	_estado.text = texto


func _ganar() -> void:
	_listo = true
	_estado.text = "¡Listo!"
	Sonido.efecto("zona_restaurada")
	await get_tree().create_timer(0.7).timeout
	terminado.emit(true)


func _terminar(exito: bool) -> void:
	if _listo and not exito:
		return
	_listo = true
	terminado.emit(exito)


# ---------------------------------------------------------------- Dibujo

func _dibujar_barra() -> void:
	var r := Rect2(Vector2(40, 6), _barra.size - Vector2(80, 12))
	_barra.draw_rect(r, Color(0.1, 0.07, 0.04))
	if tipo == "atinar":
		_barra.draw_rect(Rect2(r.position + Vector2(r.size.x * _zona.x, 0), Vector2(r.size.x * (_zona.y - _zona.x), r.size.y)),
			Color(0.35, 0.8, 0.3))
		var x := r.position.x + r.size.x * _marca
		var color := Color(1, 0.4, 0.35) if _error > 0.0 else Color(1, 0.97, 0.85)
		_barra.draw_rect(Rect2(x - 4, r.position.y - 6, 8, r.size.y + 12), color)
	else:
		_barra.draw_rect(Rect2(r.position, Vector2(r.size.x * minf(float(progreso) / meta, 1.0), r.size.y)), Color(0.35, 0.8, 0.3))
	_barra.draw_rect(r, Color(0.55, 0.38, 0.18), false, 3.0)


func _dibujar_escena() -> void:
	var c := _dibujo.size / 2.0
	match escena:
		"molino":
			_molino(c)
		"olla", "leche":
			_olla(c)
		"comal":
			_comal(c)
		"agua":
			_agua(c)
		"panal":
			_panal(c)
	if tipo == "revolver":
		# Flechas: la que toca presionar se ilumina.
		for lado in [-1, 1]:
			var x: float = c.x + lado * 330.0
			var color := Color(0.99, 0.86, 0.45) if lado == _lado else Color(0.45, 0.35, 0.25)
			if lado == _lado and _error > 0.0:
				color = Color(1, 0.55, 0.4)
			_dibujo.draw_colored_polygon(PackedVector2Array([Vector2(x + lado * 34, c.y), Vector2(x - lado * 10, c.y - 34),
				Vector2(x - lado * 10, c.y + 34)]), color)


func _icono(i: int, centro: Vector2, alto: float) -> void:
	if i >= iconos.size() or iconos[i] == null:
		return
	var textura: Texture2D = iconos[i]
	var tam := Vector2(textura.get_width() * alto / textura.get_height(), alto)
	_dibujo.draw_texture_rect(textura, Rect2(centro - tam / 2.0, tam), false)


func _elipse(centro: Vector2, radio: Vector2, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		puntos.append(centro + Vector2(cos(a) * radio.x, sin(a) * radio.y))
	_dibujo.draw_colored_polygon(puntos, color)


## Molino de piedra con manivela: cada golpe la gira; entra maíz y sale masa.
func _molino(c: Vector2) -> void:
	var centro := c + Vector2(0, 30)
	_elipse(centro + Vector2(0, 70), Vector2(150, 34), Color(0, 0, 0, 0.3))
	_dibujo.draw_rect(Rect2(centro + Vector2(-120, 0), Vector2(240, 70)), Color(0.45, 0.43, 0.42))
	_elipse(centro + Vector2(0, 70), Vector2(120, 26), Color(0.38, 0.36, 0.35))
	_elipse(centro, Vector2(120, 40), Color(0.62, 0.6, 0.58))
	_elipse(centro, Vector2(26, 9), Color(0.3, 0.28, 0.27))
	var punta := centro + Vector2(cos(_giro) * 100.0, sin(_giro) * 34.0)
	_dibujo.draw_line(centro, punta, Color(0.45, 0.28, 0.13), 12.0)
	_dibujo.draw_line(punta, punta + Vector2(0, -50), Color(0.55, 0.35, 0.17), 14.0)
	_elipse(punta + Vector2(0, -52), Vector2(10, 8), Color(0.65, 0.42, 0.2))
	_icono(0, c + Vector2(-280, -40 - _golpe * 18.0), 90.0)
	_icono(1, c + Vector2(280, 40), 50.0 + 60.0 * minf(float(progreso) / meta, 1.0))


## Olla de barro sobre el fuego con su cuchara: los ingredientes dan vueltas.
func _olla(c: Vector2) -> void:
	_fuego(c + Vector2(0, 120))
	var centro := c + Vector2(0, 30)
	_elipse(centro + Vector2(0, 30), Vector2(170, 95), Color(0.55, 0.27, 0.13))
	_elipse(centro + Vector2(0, 20), Vector2(150, 70), Color(0.66, 0.34, 0.17))
	_elipse(centro + Vector2(0, -40), Vector2(160, 40), Color(0.4, 0.2, 0.09))
	var caldo := Color(0.97, 0.95, 0.88) if escena == "leche" else Color(0.75, 0.45, 0.2)
	_elipse(centro + Vector2(0, -38), Vector2(140, 30), caldo)
	for i in 2:
		var a := _giro + i * PI
		_icono(i, centro + Vector2(cos(a) * 70.0, -40 + sin(a) * 14.0), 54.0)
	var hacia := float(-_lado)
	var mango := centro + Vector2(hacia * 50.0, -40)
	_dibujo.draw_line(mango, mango + Vector2(hacia * 70.0, -150), Color(0.55, 0.35, 0.17), 12.0)
	_elipse(mango, Vector2(22, 9), Color(0.5, 0.32, 0.15))


## Comal sobre el fuego: lo de arriba brinca y se voltea en cada acierto.
func _comal(c: Vector2) -> void:
	_fuego(c + Vector2(0, 110))
	_elipse(c + Vector2(0, 60), Vector2(210, 46), Color(0.2, 0.18, 0.17))
	_elipse(c + Vector2(0, 54), Vector2(196, 38), Color(0.32, 0.3, 0.28))
	if iconos.size() > 0 and iconos[0] != null:
		var textura: Texture2D = iconos[0]
		var alto := 110.0
		var tam := Vector2(textura.get_width() * alto / textura.get_height(), alto)
		var vuelta := cos(_golpe * PI)
		var centro := c + Vector2(0, 10 - sin(_golpe * PI) * 80.0)
		_dibujo.draw_set_transform(centro, 0.0, Vector2(1.0, vuelta))
		_dibujo.draw_texture_rect(textura, Rect2(-tam / 2.0, tam), false)
		_dibujo.draw_set_transform(Vector2.ZERO)


## Agua del lago con el corcho de la caña; al acertar salta el pez.
func _agua(c: Vector2) -> void:
	_dibujo.draw_rect(Rect2(Vector2(20, 40), _dibujo.size - Vector2(40, 60)), Color(0.13, 0.36, 0.55))
	for fila in 5:
		var y := 80.0 + fila * 45.0
		var puntos := PackedVector2Array()
		for i in 30:
			var x := 30.0 + i * (_dibujo.size.x - 60.0) / 29.0
			puntos.append(Vector2(x, y + sin(x * 0.03 + _tiempo * 2.0 + fila) * 5.0))
		_dibujo.draw_polyline(puntos, Color(0.4, 0.65, 0.85, 0.6), 3.0)
	var corcho := c + Vector2(0, sin(_tiempo * 6.0) * (4.0 + _error * 10.0))
	_dibujo.draw_line(Vector2(c.x + 260, 0), corcho, Color(0.9, 0.9, 0.85), 2.0)
	_elipse(corcho, Vector2(16, 16), Color(0.9, 0.2, 0.15))
	_elipse(corcho + Vector2(0, -6), Vector2(16, 8), Color(0.97, 0.97, 0.95))
	if _golpe > 0.0:
		_icono(0, c + Vector2(-90, 10 - sin(_golpe * PI) * 90.0), 80.0)


## Panal con abejas meliponas volando; en cada acierto se saca una parte de miel.
func _panal(c: Vector2) -> void:
	var quedan := meta - progreso
	for i in 12:
		var fila := i / 4
		var col := i % 4
		var centro := c + Vector2((col - 1.5) * 64.0 + (fila % 2) * 32.0, (fila - 1) * 56.0 + 10)
		var puntos := PackedVector2Array()
		for k in 6:
			var a := TAU * k / 6.0 + PI / 6.0
			puntos.append(centro + Vector2(cos(a), sin(a)) * 32.0)
		var llena := i < 12 * quedan / maxi(meta, 1)
		_dibujo.draw_colored_polygon(puntos, Color(0.95, 0.7, 0.15) if llena else Color(0.55, 0.42, 0.2))
		_dibujo.draw_polyline(puntos + PackedVector2Array([puntos[0]]), Color(0.45, 0.3, 0.1), 3.0)
	for i in 6:
		var a := _tiempo * (1.2 + i * 0.2) + i
		var abeja := c + Vector2(cos(a) * (170.0 + i * 12.0), sin(a * 1.3) * 110.0)
		_elipse(abeja, Vector2(9, 7), Color(0.2, 0.15, 0.1))
		_elipse(abeja + Vector2(-2, -1), Vector2(4, 5), Color(0.95, 0.75, 0.2))
	_icono(0, c + Vector2(300, 60 - _golpe * 30.0), 70.0)


func _fuego(base: Vector2) -> void:
	for i in 5:
		var x := (i - 2) * 40.0
		var alto := 46.0 + sin(_tiempo * 9.0 + i * 1.7) * 12.0
		_dibujo.draw_colored_polygon(PackedVector2Array([base + Vector2(x - 18, 0), base + Vector2(x + 18, 0),
			base + Vector2(x, -alto)]), Color(1, 0.55, 0.12))
		_dibujo.draw_colored_polygon(PackedVector2Array([base + Vector2(x - 9, 0), base + Vector2(x + 9, 0),
			base + Vector2(x, -alto * 0.55)]), Color(1, 0.86, 0.3))

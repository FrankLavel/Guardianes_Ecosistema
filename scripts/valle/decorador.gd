class_name Decorador
extends Node2D
## Modo decorar de la granja (botón DECORAR del HUD o tecla C): comprar decoraciones y ponerlas donde
## el jugador quiera, y mover con el mouse las decoraciones, el corral y los talleres. Solo se suelta
## algo donde cabe: dentro del valle, sin encimarse con otra cosa de la granja, los árboles, el río,
## la casa, la milpa ni las entradas a las zonas.

## Algo de la granja cambió de lugar (para que los animales y las plantas lo respeten).
signal movido(nodo: Node2D)

const VERDE := Color(0.7, 1, 0.7, 0.85)
const ROJO := Color(1, 0.45, 0.4, 0.8)

## El valle: da los avisos, el tamaño del mapa, los lugares fijos y dónde van los objetos.
var valle: Node2D
var activo := false
## Tamaño del mapa (no se puede poner nada en la orilla).
var tamano := Vector2(2800, 1800)

var _cargando: Node2D
var _nueva := false
var _origen := Vector2.ZERO
var _agarre := Vector2.ZERO
var _cabe := false
var _capa: CanvasLayer
var _texto: Label
var _guardar: Button
var _girar: Button


func _ready() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 41
	_capa.visible = false
	add_child(_capa)
	var barra := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.14, 0.08, 0.92)
	estilo.border_color = Color(0.55, 0.38, 0.18)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(12)
	barra.add_theme_stylebox_override("panel", estilo)
	barra.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	barra.grow_horizontal = Control.GROW_DIRECTION_BOTH
	barra.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_capa.add_child(barra)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	barra.add_child(fila)
	_texto = Label.new()
	_texto.add_theme_font_size_override("font_size", 24)
	_texto.add_theme_color_override("font_color", Color(0.99, 0.86, 0.45))
	_texto.custom_minimum_size = Vector2(620, 0)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_texto)
	fila.add_child(_boton("TIENDA", _abrir_tienda))
	_girar = _boton("GIRAR (R)", girar)
	fila.add_child(_girar)
	_guardar = _boton("GUARDAR", _guardar_cargada)
	fila.add_child(_guardar)
	fila.add_child(_boton("LISTO", salir))


func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(150, 52)
	# Que E o Enter no lo aprieten sin querer.
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(accion)
	return b


func puede_abrir() -> bool:
	return Juego.zona_esta_completa("rio") and Granja.abierto.is_empty() and not Dialogo.activo \
		and not get_tree().paused and not Juego.entrada_bloqueada


func entrar() -> void:
	if activo or not puede_abrir():
		return
	activo = true
	_capa.visible = true
	_actualizar_barra()


func salir() -> void:
	if _cargando:
		_cancelar()
	activo = false
	_capa.visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if not activo:
		if evento.is_action_pressed("decorar") and puede_abrir():
			entrar()
			get_viewport().set_input_as_handled()
		return
	if not Granja.abierto.is_empty():
		return
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_LEFT:
			if _cargando:
				_soltar()
			else:
				_agarrar(get_global_mouse_position())
		elif evento.button_index == MOUSE_BUTTON_RIGHT and _cargando:
			_cancelar()
		get_viewport().set_input_as_handled()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_R:
		girar()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("decorar"):
		if _cargando:
			_cancelar()
		else:
			salir()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _cargando == null:
		return
	_mover(_cargando, get_global_mouse_position() + _agarre)
	_cabe = cabe(_cargando)
	_cargando.modulate = VERDE if _cabe else ROJO


## Entra al modo decorar con `nodo` (que ya está en el valle) en la mano, para que el jugador elija dónde va.
func acomodar(nodo: Node2D) -> void:
	entrar()
	if activo:
		_tomar(nodo, false)


## Pone en la mano una decoración nueva (de la tienda) para soltarla donde se quiera.
func empezar_nueva(id: String) -> void:
	if _cargando:
		_cancelar()
	var decoracion := Decoracion.new()
	decoracion.id = id
	decoracion.global_position = get_global_mouse_position()
	valle.get_node("Objetos").add_child(decoracion)
	_tomar(decoracion, true)


func _agarrar(punto: Vector2) -> void:
	var elegido: Node2D
	for nodo in get_tree().get_nodes_in_group(&"movible"):
		# Si hay varias cosas bajo el mouse se agarra la más chica (la decoración, no el corral). Los
		# árboles y rocas de fuera de la granja no se tocan.
		if nodo.contiene(punto) and Granja.en_la_granja(nodo.huella()) \
				and (elegido == null or nodo.huella().get_area() < elegido.huella().get_area()):
			elegido = nodo
	if elegido:
		_tomar(elegido, false)
		_agarre = elegido.global_position - punto
	elif Granja.se_puede_expandir(Granja.celda_de(punto)):
		Sonido.efecto("boton")
		Granja.abrir_expandir(Granja.celda_de(punto))


func _tomar(nodo: Node2D, nueva: bool) -> void:
	_cargando = nodo
	_nueva = nueva
	# Lo que va en la mano se ve encima de todo, aunque pase detrás de la casa.
	nodo.z_index = 10
	_origen = nodo.global_position
	_agarre = Vector2.ZERO
	Sonido.efecto("boton")
	_actualizar_barra()


func _soltar() -> void:
	if not _cabe:
		Sonido.efecto("incorrecto")
		valle.avisar("Aquí no cabe. Búscale un lugar libre en el pasto.")
		return
	var nodo := _cargando
	var pos := nodo.global_position
	if nodo is Decoracion:
		if _nueva:
			nodo.puesta = Granja.poner_decoracion(nodo.id, pos)
		else:
			nodo.puesta["x"] = pos.x
			nodo.puesta["y"] = pos.y
		nodo.puesta["girada"] = nodo.girada
	else:
		Granja.fijar_posicion(nodo.clave, pos)
	Sonido.efecto("correcto")
	_soltar_de_la_mano()
	movido.emit(nodo)


func _cancelar() -> void:
	if _nueva:
		# La comprada sigue guardada: se puede poner después.
		_cargando.queue_free()
	else:
		_mover(_cargando, _origen)
	_soltar_de_la_mano()


## Voltea la decoración que va en la mano (como en un espejo).
func girar() -> void:
	if _cargando is Decoracion:
		_cargando.girada = not _cargando.girada
		Sonido.efecto("boton")


func _guardar_cargada() -> void:
	if not _cargando is Decoracion:
		return
	if not _nueva:
		Granja.guardar_decoracion(_cargando.puesta)
	_cargando.queue_free()
	_cargando = null
	valle.avisar("La guardaste. Está en la tienda para ponerla otra vez.")
	_actualizar_barra()


func _soltar_de_la_mano() -> void:
	if is_instance_valid(_cargando):
		_cargando.modulate = Color.WHITE
		_cargando.z_index = 0
	_cargando = null
	_actualizar_barra()


func _abrir_tienda() -> void:
	if _cargando:
		_cancelar()
	Granja.abrir_tienda_decoraciones(empezar_nueva)


func _mover(nodo: Node2D, destino: Vector2) -> void:
	if nodo.has_method("mover_a"):
		nodo.mover_a(destino)
	else:
		nodo.global_position = destino


func _actualizar_barra() -> void:
	_guardar.visible = _cargando is Decoracion
	_girar.visible = _cargando is Decoracion
	if _cargando:
		_texto.text = "Clic para soltar donde esté verde.  Clic derecho o Esc: regresar."
	else:
		_texto.text = "Modo decorar: haz clic en una decoración, el corral o un taller para moverlo, o en un terreno azul para expandir la granja."


## Si `nodo` cabe donde está ahora. `ignorar`: adornos del valle (por nombre, p. ej. "Tocon") que no
## estorban porque se pueden quitar.
func cabe(nodo: Node2D, ignorar: Array = []) -> bool:
	var huella: Rect2 = nodo.huella()
	if not Rect2(Vector2(60, 60), tamano - Vector2(120, 120)).encloses(huella) or not Granja.en_la_granja(huella):
		return false
	for zona in valle.lugares_fijos():
		if zona.intersects(huella):
			return false
	for otro in get_tree().get_nodes_in_group(&"movible"):
		if otro != nodo and otro.huella().intersects(huella) and not _ignorado(otro, ignorar):
			return false
	# Los árboles, las rocas, el río y la casa tienen cuerpo; los animales y el guardián no estorban.
	var forma := RectangleShape2D.new()
	forma.size = huella.size
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, huella.get_center())
	if nodo is StaticBody2D:
		consulta.exclude.append(nodo.get_rid())
	for cuerpo in nodo.find_children("*", "StaticBody2D", true, false):
		consulta.exclude.append(cuerpo.get_rid())
	for choque in get_world_2d().direct_space_state.intersect_shape(consulta, 16):
		if not choque["collider"] is CharacterBody2D and not _ignorado(choque["collider"], ignorar):
			return false
	return true


func _ignorado(nodo: Node, ignorar: Array) -> bool:
	return String(nodo.name).rstrip("0123456789") in ignorar

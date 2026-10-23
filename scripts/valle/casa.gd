extends Node2D
## Casa del guardián (la base): cama para descansar y guardar (cambia entre día y noche),
## repisa de trofeos, tablero con el pedido de ayuda en curso y baúl para comprar muebles con
## las hojas que regalan los animales.
##
## shortcut: el cuarto y los muebles se dibujan con código hasta que haya arte del interior;
## al llegar el arte, cambiar _draw por sprites y dejar las posiciones de MUEBLES.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_ZONA := preload("res://scenes/valle/ZonaInteraccion.tscn")
const RUTA_PEDIDOS := "res://data/pedidos.json"
const TAMANO := Vector2(1600, 900)
## Alto de la pared del fondo; el piso empieza aquí.
const PARED := 300.0
const COLOR_NOCHE := Color(0.5, 0.55, 0.8)

## Muebles que se compran con hojas. Se dibujan en el cuarto cuando ya son tuyos.
const MUEBLES := {
	"maceta": {"nombre": "Maceta con brote", "costo": 4, "icono": "res://assets/objects/zona1/brote_control.png"},
	"tule": {"nombre": "Tule en maceta", "costo": 5, "icono": "res://assets/objects/zona3/tule.png"},
	"alfombra": {"nombre": "Alfombra tejida", "costo": 6, "icono": ""},
	"lampara": {"nombre": "Lámpara de barro", "costo": 7, "icono": ""},
	"cuadro": {"nombre": "Cuadro de la mariposa monarca", "costo": 8, "icono": "res://assets/ui/bitacora/monarca.png"},
	"pecera": {"nombre": "Pecera con achoque", "costo": 12, "icono": "res://assets/objects/zona3/achoque.png"},
}
## Insignias por tipo de ayuda y cuántas ayudas pide cada nivel.
const INSIGNIAS := {"basura": "Limpiador del valle", "cria": "Rescatista de crías", "plantar": "Sembrador"}
const NIVELES := [[6, "Oro"], [3, "Plata"], [1, "Bronce"]]
const ZONAS := {
	"rio": ["Río Cupatitzio", "res://assets/maps/valle/entradas/entrada_rio.png"],
	"bosque": ["Bosque de oyamel", "res://assets/maps/valle/entradas/entrada_bosque.png"],
	"lago": ["Lago de Pátzcuaro", "res://assets/maps/valle/entradas/entrada_lago.png"],
}

var panel_abierto := ""

@onready var gara: GaraAerea = $Objetos/Gara
@onready var hud: CanvasLayer = $HUD
@onready var _fondo_panel: Control = %Fondo
@onready var _titulo: Label = %Titulo
@onready var _contenido: VBoxContainer = %Contenido
@onready var _negro: ColorRect = %Negro

var _noche: CanvasModulate
var _pedidos: Dictionary = {}
## Texturas del cuarto cargadas antes de dibujar (cargarlas dentro de _draw las pintaba en blanco
## el primer cuadro).
var _texturas: Dictionary = {}


func _ready() -> void:
	add_to_group(&"jugable")
	Sonido.musica("valle")
	_pedidos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_PEDIDOS))
	_noche = CanvasModulate.new()
	add_child(_noche)
	var rutas := ["res://assets/ui/bitacora/monarca.png", "res://assets/objects/zona1/brote_control.png",
		"res://assets/objects/zona3/tule.png", "res://assets/objects/zona3/achoque.png"]
	for zona in ZONAS:
		rutas.append(ZONAS[zona][1])
	for id in Bitacora.especies:
		rutas.append(Bitacora.RUTA_IMAGEN % id)
	for ruta in rutas:
		if ResourceLoader.exists(ruta):
			_texturas[ruta] = load(ruta)
	_fondo_panel.visible = false
	_negro.modulate.a = 0.0
	%BtnCerrar.pressed.connect(cerrar_panel)
	var camara := gara.camara
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = int(TAMANO.x)
	camara.limit_bottom = int(TAMANO.y)
	_crear_paredes()
	_crear_zona("Cama", Vector2(240, 580), "E  Descansar y guardar", func(_j): descansar())
	_crear_zona("Repisa", Vector2(750, 370), "E  Ver trofeos", func(_j): abrir_panel("trofeos"))
	_crear_zona("Tablero", Vector2(1120, 370), "E  Tablero de pedidos", func(_j): abrir_panel("tablero"))
	_crear_zona("Baul", Vector2(1465, 660), "E  Muebles", func(_j): abrir_panel("muebles"))
	_crear_zona("Puerta", Vector2(800, 860), "E  Salir al valle", func(_j): salir())
	hud.get_node("PanelLugar/HBox/VBox/Lugar").text = "Tu casa"
	_actualizar()
	hud.mostrar_objetivo("Esta es tu casa. Descansa en la cama, mira tus trofeos o compra muebles.")


func _crear_paredes() -> void:
	var paredes := StaticBody2D.new()
	for caja in [Rect2(0, -60, TAMANO.x, PARED + 90), Rect2(-60, 0, 60, TAMANO.y), Rect2(TAMANO.x, 0, 60, TAMANO.y),
			Rect2(0, TAMANO.y - 20, TAMANO.x, 80), Rect2(90, PARED, 300, 240), Rect2(1390, 530, 150, 90)]:
		var forma := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = caja.size
		forma.shape = rect
		forma.position = caja.get_center()
		paredes.add_child(forma)
	add_child(paredes)


func _crear_zona(nombre: String, lugar: Vector2, aviso: String, accion: Callable) -> void:
	var zona: ZonaInteraccion = ESCENA_ZONA.instantiate()
	zona.name = nombre
	zona.texto_aviso = aviso
	zona.position = lugar
	zona.activada.connect(accion)
	$Objetos.add_child(zona)


func _actualizar() -> void:
	_noche.color = COLOR_NOCHE if Juego.es_de_noche else Color.WHITE
	hud.actualizar_progreso(Juego.zonas_completadas.size(), Juego.ZONAS.size(), Juego.hojas)
	queue_redraw()


func _unhandled_input(evento: InputEvent) -> void:
	if not panel_abierto.is_empty() and evento.is_action_pressed("ui_cancel"):
		cerrar_panel()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- Acciones

## Duerme un rato: guarda la partida y cambia entre día y noche.
func descansar() -> void:
	if Dialogo.activo:
		return
	await Dialogo.mostrar_lineas("_cama", [{"quien": "jugador", "texto": "Voy a descansar un rato..."}])
	Juego.entrada_bloqueada = true
	var fundido := create_tween()
	fundido.tween_property(_negro, "modulate:a", 1.0, 0.6)
	await fundido.finished
	Juego.es_de_noche = not Juego.es_de_noche
	Juego.guardar()
	_actualizar()
	await get_tree().create_timer(0.5).timeout
	fundido = create_tween()
	fundido.tween_property(_negro, "modulate:a", 0.0, 0.6)
	await fundido.finished
	Juego.entrada_bloqueada = false
	hud.mostrar_objetivo("Partida guardada. Ya es de %s." % ("noche" if Juego.es_de_noche else "día"))


func salir() -> void:
	if Transicion.en_curso:
		return
	gara.leer_entrada_del_jugador = false
	gara.entrada_direccion = Vector2.ZERO
	Juego.guardar()
	Transicion.ir_a(ESCENA_VALLE)


## Devuelve false si ya lo tienes o no alcanzan las hojas.
func comprar(id: String) -> bool:
	if id in Juego.muebles or not MUEBLES.has(id):
		return false
	if not Juego.gastar_hojas(int(MUEBLES[id]["costo"])):
		return false
	Juego.muebles.append(id)
	Juego.guardar()
	Sonido.efecto("correcto")
	_actualizar()
	if panel_abierto == "muebles":
		abrir_panel("muebles")
	return true


# ---------------------------------------------------------------- Paneles

func abrir_panel(tipo: String) -> void:
	panel_abierto = tipo
	for hijo in _contenido.get_children():
		hijo.queue_free()
	match tipo:
		"trofeos":
			_llenar_trofeos()
		"tablero":
			_llenar_tablero()
		"muebles":
			_llenar_muebles()
	_fondo_panel.visible = true
	Juego.entrada_bloqueada = true
	Sonido.efecto("boton")
	%BtnCerrar.grab_focus()


func cerrar_panel() -> void:
	if panel_abierto.is_empty():
		return
	panel_abierto = ""
	_fondo_panel.visible = false
	await get_tree().process_frame
	Juego.entrada_bloqueada = false


func _texto(texto: String, tam := 28, color := Color(1, 0.96, 0.86)) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return etiqueta


func _icono(ruta: String, lado: float, apagado := false) -> TextureRect:
	var imagen := TextureRect.new()
	imagen.custom_minimum_size = Vector2(lado, lado)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not ruta.is_empty():
		imagen.texture = load(ruta)
	if apagado:
		imagen.modulate = Color(0.15, 0.12, 0.1, 0.8)
	return imagen


func _llenar_trofeos() -> void:
	_titulo.text = "Sala de trofeos"
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 40)
	for zona in ZONAS:
		var hecha := Juego.zona_esta_completa(zona)
		var columna := VBoxContainer.new()
		columna.add_child(_icono(ZONAS[zona][1], 150, not hecha))
		var nombre := _texto(ZONAS[zona][0], 26)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		columna.add_child(nombre)
		var estado := _texto("Restaurado" if hecha else "Pendiente", 24, Color(0.7, 1, 0.6) if hecha else Color(1, 0.75, 0.6))
		estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		columna.add_child(estado)
		fila.add_child(columna)
	_contenido.add_child(fila)
	_contenido.add_child(_texto("Especies en tu bitácora: %d de %d" % [Bitacora.descubiertas(), Bitacora.total()], 30, Color(0.8, 1, 0.7)))
	_contenido.add_child(_texto("Insignias por ayudar a los animales (%d ayudas):" % Juego.total_ayudas(), 30, Color(0.99, 0.86, 0.45)))
	for tipo in INSIGNIAS:
		var veces := int(Juego.ayudas.get(tipo, 0))
		var nivel := "Aún no la tienes"
		for n in NIVELES:
			if veces >= n[0]:
				nivel = n[1]
				break
		_contenido.add_child(_texto("•  %s: %s  (%d)" % [INSIGNIAS[tipo], nivel, veces], 26))
	_contenido.add_child(_texto("Hojas: %d" % Juego.hojas, 28, Color(0.8, 1, 0.7)))


func _llenar_tablero() -> void:
	_titulo.text = "Tablero de pedidos"
	if not Juego.juego_terminado():
		_contenido.add_child(_texto("Primero restaura el río, el bosque y el lago. Después, los animales del valle te buscarán cuando necesiten ayuda."))
	elif Juego.pedido.is_empty():
		_contenido.add_child(_texto("No hay pedidos por ahora. Pasea por el valle: cuando un animal necesite ayuda irá a buscarte (verás un ! sobre él)."))
	elif Juego.pedido.get("estado") == "aviso":
		_contenido.add_child(_texto("¡Un animal te está buscando en el valle! Sal y habla con él.", 30, Color(0.99, 0.86, 0.45)))
	else:
		var def: Dictionary = _pedidos["pedidos"].get(Juego.pedido["tipo"], {})
		var texto: String = def.get("objetivo", "").replace("{del_animal}", _pedidos["nombres"].get(Juego.pedido.get("especie", ""), ""))
		_contenido.add_child(_texto("Pedido en curso:", 30, Color(0.99, 0.86, 0.45)))
		_contenido.add_child(_texto("%s  (%d/%d)" % [texto, int(Juego.pedido["progreso"]), int(def.get("meta", 1))], 30))
		if int(Juego.pedido["progreso"]) >= int(def.get("meta", 1)):
			_contenido.add_child(_texto("¡Ya terminaste! Regresa a hablar con el animal.", 28, Color(0.7, 1, 0.6)))
		_contenido.add_child(_texto("Recompensa: %d hojas" % int(def.get("recompensa", 0)), 28, Color(0.8, 1, 0.7)))
	_contenido.add_child(_texto("Los animales pueden pedirte:", 28, Color(0.99, 0.86, 0.45)))
	for linea in ["•  Recoger basura donde buscan comida.", "•  Encontrar a una cría perdida y llevarla con su mamá.", "•  Plantar arbolitos para que haya sombra y comida."]:
		_contenido.add_child(_texto(linea, 26))
	_contenido.add_child(_texto("Ayudas completadas: %d" % Juego.total_ayudas(), 28, Color(0.8, 1, 0.7)))


func _llenar_muebles() -> void:
	_titulo.text = "Muebles para tu casa"
	_contenido.add_child(_texto("Tienes %d hojas. Los animales te regalan hojas cuando los ayudas." % Juego.hojas, 28, Color(0.8, 1, 0.7)))
	for id in MUEBLES:
		var datos: Dictionary = MUEBLES[id]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 20)
		fila.add_child(_icono(datos["icono"], 64))
		var nombre := _texto(datos["nombre"], 28)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(nombre)
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(300, 60)
		if id in Juego.muebles:
			boton.text = "YA ES TUYO"
			boton.disabled = true
		else:
			boton.text = "COMPRAR (%d hojas)" % int(datos["costo"])
			boton.disabled = Juego.hojas < int(datos["costo"])
			boton.pressed.connect(comprar.bind(id))
		fila.add_child(boton)
		_contenido.add_child(fila)


# ---------------------------------------------------------------- Dibujo del cuarto

func _draw() -> void:
	_dibujar_pared()
	_dibujar_piso()
	if "alfombra" in Juego.muebles:
		_caja(Rect2(560, 500, 480, 260), Color(0.68, 0.2, 0.16), 26)
		_caja(Rect2(580, 520, 440, 220), Color(0.88, 0.55, 0.2), 20)
		for i in 9:
			var y := 540.0 + i * 22.0
			draw_line(Vector2(600, y), Vector2(1000, y), [Color(0.7, 0.22, 0.2), Color(0.2, 0.45, 0.4), Color(0.95, 0.85, 0.5)][i % 3], 6.0)
	_dibujar_cama()
	_dibujar_repisa()
	_dibujar_tablero()
	_dibujar_baul()
	_dibujar_puerta()
	if "cuadro" in Juego.muebles:
		_caja(Rect2(440, 70, 130, 150), Color(0.36, 0.22, 0.1), 6)
		_caja(Rect2(452, 82, 106, 126), Color(0.92, 0.88, 0.76), 4)
		_textura("res://assets/ui/bitacora/monarca.png", Rect2(456, 90, 98, 110))
	if "maceta" in Juego.muebles:
		_maceta(Vector2(530, PARED + 70), "res://assets/objects/zona1/brote_control.png", 90.0)
	if "tule" in Juego.muebles:
		_maceta(Vector2(1300, PARED + 70), "res://assets/objects/zona3/tule.png", 130.0)
	if "lampara" in Juego.muebles:
		var centro := Vector2(960, PARED + 40)
		if Juego.es_de_noche:
			for r in [160.0, 110.0, 70.0]:
				draw_circle(centro + Vector2(0, -40), r, Color(1, 0.8, 0.4, 0.12), true, -1.0, true)
		draw_colored_polygon(PackedVector2Array([centro + Vector2(-22, 30), centro + Vector2(22, 30), centro + Vector2(12, -10), centro + Vector2(-12, -10)]), Color(0.66, 0.36, 0.2))
		draw_colored_polygon(PackedVector2Array([centro + Vector2(-34, -10), centro + Vector2(34, -10), centro + Vector2(20, -60), centro + Vector2(-20, -60)]), Color(0.98, 0.85, 0.55))
	if "pecera" in Juego.muebles:
		_caja(Rect2(120, 740, 200, 26), Color(0.42, 0.26, 0.12), 4)
		draw_rect(Rect2(135, 766, 14, 50), Color(0.36, 0.22, 0.1))
		draw_rect(Rect2(291, 766, 14, 50), Color(0.36, 0.22, 0.1))
		_caja(Rect2(135, 630, 170, 110), Color(0.55, 0.8, 0.95, 0.75), 8)
		draw_rect(Rect2(140, 712, 160, 24), Color(0.75, 0.66, 0.45))
		_textura("res://assets/objects/zona3/achoque.png", Rect2(170, 660, 100, 70))


func _caja(rect: Rect2, color: Color, radio: int) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(radio)
	draw_style_box(estilo, rect)


## Dibuja la textura dentro de `rect` sin deformarla, apoyada abajo.
func _textura(ruta: String, rect: Rect2, color := Color.WHITE) -> void:
	var textura: Texture2D = _texturas.get(ruta)
	if textura == null:
		return
	var escala := minf(rect.size.x / textura.get_width(), rect.size.y / textura.get_height())
	var tam := textura.get_size() * escala
	draw_texture_rect(textura, Rect2(Vector2(rect.get_center().x - tam.x / 2.0, rect.end.y - tam.y), tam), false, color)


func _maceta(base: Vector2, ruta: String, alto: float) -> void:
	_textura(ruta, Rect2(base + Vector2(-alto * 0.4, -alto - 30), Vector2(alto * 0.8, alto)))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-36, -34), base + Vector2(36, -34), base + Vector2(26, 10), base + Vector2(-26, 10)]), Color(0.72, 0.38, 0.2))
	draw_rect(Rect2(base + Vector2(-40, -40), Vector2(80, 12)), Color(0.6, 0.3, 0.16))


func _dibujar_pared() -> void:
	draw_rect(Rect2(0, 0, TAMANO.x, PARED), Color(0.87, 0.73, 0.56))
	# Bloques de adobe.
	for fila in 6:
		var y := 30.0 + fila * 45.0
		var corrido := 0.0 if fila % 2 == 0 else 60.0
		draw_line(Vector2(0, y), Vector2(TAMANO.x, y), Color(0.6, 0.45, 0.3, 0.25), 2.0)
		var x := corrido
		while x < TAMANO.x:
			draw_line(Vector2(x, y), Vector2(x, y + 45), Color(0.6, 0.45, 0.3, 0.2), 2.0)
			x += 120.0
	# Vigas del techo.
	draw_rect(Rect2(0, 0, TAMANO.x, 26), Color(0.36, 0.22, 0.1))
	var v := 40.0
	while v < TAMANO.x:
		_caja(Rect2(v, 18, 28, 26), Color(0.42, 0.26, 0.12), 4)
		v += 170.0
	# Zoclo y sombra al pie de la pared.
	draw_rect(Rect2(0, PARED - 16, TAMANO.x, 16), Color(0.45, 0.28, 0.13))
	for ventana in [Rect2(240, 70, 160, 140), Rect2(1290, 70, 160, 140)]:
		_caja(ventana.grow(12), Color(0.42, 0.26, 0.12), 6)
		var cielo := Color(0.12, 0.16, 0.36) if Juego.es_de_noche else Color(0.6, 0.82, 0.95)
		draw_rect(ventana, cielo)
		if Juego.es_de_noche:
			for i in 6:
				draw_circle(ventana.position + Vector2(20 + i * 24, 20 + (i * 37) % 90), 2.5, Color(1, 1, 0.85))
		else:
			draw_circle(ventana.position + Vector2(110, 40), 18, Color(1, 0.95, 0.7))
			draw_rect(Rect2(ventana.position + Vector2(0, 100), Vector2(ventana.size.x, 40)), Color(0.4, 0.62, 0.35))
		draw_line(ventana.position + Vector2(ventana.size.x / 2.0, 0), ventana.position + Vector2(ventana.size.x / 2.0, ventana.size.y), Color(0.42, 0.26, 0.12), 8.0)
		draw_line(ventana.position + Vector2(0, ventana.size.y / 2.0), ventana.position + Vector2(ventana.size.x, ventana.size.y / 2.0), Color(0.42, 0.26, 0.12), 8.0)


func _dibujar_piso() -> void:
	var tabla := 0
	var y := PARED
	while y < TAMANO.y:
		var color := Color(0.56, 0.36, 0.2) if tabla % 2 == 0 else Color(0.6, 0.4, 0.23)
		draw_rect(Rect2(0, y, TAMANO.x, 50), color)
		draw_line(Vector2(0, y), Vector2(TAMANO.x, y), Color(0.35, 0.2, 0.1, 0.6), 2.0)
		var x := 90.0 + (tabla * 137) % 260
		while x < TAMANO.x:
			draw_line(Vector2(x, y), Vector2(x, y + 50), Color(0.35, 0.2, 0.1, 0.5), 2.0)
			x += 260.0
		y += 50.0
		tabla += 1
	draw_rect(Rect2(0, PARED, TAMANO.x, 24), Color(0, 0, 0, 0.16))


func _dibujar_cama() -> void:
	_caja(Rect2(84, PARED - 50, 312, 70), Color(0.36, 0.22, 0.1), 10)
	_caja(Rect2(90, PARED, 300, 240), Color(0.42, 0.26, 0.12), 10)
	_caja(Rect2(102, PARED + 8, 276, 222), Color(0.95, 0.93, 0.86), 8)
	_caja(Rect2(130, PARED + 18, 220, 50), Color(1, 1, 0.97), 16)
	# Cobija verde con bordado de colores.
	_caja(Rect2(102, PARED + 90, 276, 140), Color(0.18, 0.48, 0.3), 8)
	for i in 3:
		var y := PARED + 115.0 + i * 40.0
		for j in 9:
			var x := 120.0 + j * 30.0
			var color: Color = [Color(0.92, 0.3, 0.35), Color(0.98, 0.82, 0.3), Color(0.95, 0.5, 0.7)][(i + j) % 3]
			draw_colored_polygon(PackedVector2Array([Vector2(x, y - 8), Vector2(x + 8, y), Vector2(x, y + 8), Vector2(x - 8, y)]), color)


func _dibujar_repisa() -> void:
	_caja(Rect2(600, 50, 300, 230), Color(0.4, 0.25, 0.12), 8)
	_caja(Rect2(612, 62, 276, 206), Color(0.3, 0.18, 0.09), 6)
	draw_rect(Rect2(600, 158, 300, 14), Color(0.52, 0.33, 0.16))
	draw_rect(Rect2(600, 266, 300, 14), Color(0.52, 0.33, 0.16))
	var x := 625.0
	for zona in ZONAS:
		var color := Color.WHITE if Juego.zona_esta_completa(zona) else Color(0.1, 0.08, 0.06, 0.7)
		_textura(ZONAS[zona][1], Rect2(x, 70, 84, 88), color)
		x += 88.0
	# Especies descubiertas (las primeras 5) en la repisa de abajo.
	var y_especies := 0
	for id in Bitacora.especies:
		if id in Juego.especies_descubiertas and y_especies < 5:
			_textura(Bitacora.RUTA_IMAGEN % id, Rect2(620 + y_especies * 54, 206, 52, 60))
			y_especies += 1


func _dibujar_tablero() -> void:
	_caja(Rect2(1000, 60, 250, 190), Color(0.42, 0.26, 0.12), 8)
	_caja(Rect2(1012, 72, 226, 166), Color(0.78, 0.6, 0.4), 4)
	for i in 30:
		draw_circle(Vector2(1020 + (i * 53) % 210, 80 + (i * 31) % 150), 2.0, Color(0.6, 0.44, 0.28))
	var notas := [[Vector2(1030, 90), Color(1, 0.98, 0.85)], [Vector2(1140, 100), Color(0.85, 0.95, 1)], [Vector2(1060, 160), Color(0.9, 1, 0.85)]]
	for nota in notas:
		draw_rect(Rect2(nota[0], Vector2(70, 58)), nota[1])
		for k in 3:
			draw_line(nota[0] + Vector2(8, 16 + k * 12), nota[0] + Vector2(60, 16 + k * 12), Color(0.5, 0.5, 0.55), 2.0)
		draw_circle(nota[0] + Vector2(35, 4), 5, Color(0.85, 0.2, 0.2))
	if not Juego.pedido.is_empty():
		_caja(Rect2(1160, 160, 64, 66), Color(0.98, 0.85, 0.3), 4)
		draw_string(ThemeDB.fallback_font, Vector2(1180, 212), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(0.6, 0.15, 0.1))


func _dibujar_baul() -> void:
	var r := Rect2(1390, 530, 150, 90)
	_caja(r, Color(0.48, 0.3, 0.14), 8)
	_caja(Rect2(r.position + Vector2(0, -24), Vector2(r.size.x, 40)), Color(0.55, 0.35, 0.17), 12)
	for x in [1412.0, 1508.0]:
		draw_rect(Rect2(x, r.position.y - 22, 12, r.size.y + 22), Color(0.35, 0.33, 0.3))
	_caja(Rect2(1454, 540, 22, 26), Color(0.95, 0.8, 0.3), 4)


func _dibujar_puerta() -> void:
	_caja(Rect2(710, TAMANO.y - 26, 180, 30), Color(0.36, 0.22, 0.1), 4)
	draw_rect(Rect2(722, TAMANO.y - 20, 156, 20), Color(0.12, 0.08, 0.05))
	_caja(Rect2(730, TAMANO.y - 74, 140, 44), Color(0.62, 0.48, 0.3), 8)
	for i in 5:
		draw_line(Vector2(742 + i * 28, TAMANO.y - 70), Vector2(742 + i * 28, TAMANO.y - 34), Color(0.5, 0.36, 0.2), 3.0)

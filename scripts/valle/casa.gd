extends Node2D
## Casa del guardián (la base): cama para descansar y guardar (cambia entre día y noche),
## repisa de trofeos, tablero con el pedido de ayuda en curso y baúl para comprar muebles con
## las hojas que regalan los animales.
##
## El cuarto es la imagen assets/maps/casa/interior.png ampliada (ESCALA_CUARTO). Lo que va en
## la pared (repisa, tablero, cuadro) y la alfombra se dibujan en _draw; lo que está en el piso son
## sprites dentro de Objetos para que el guardián pueda pasar por delante o por detrás.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_ZONA := preload("res://scenes/valle/ZonaInteraccion.tscn")
const RUTA_PEDIDOS := "res://data/pedidos.json"
const INTERIOR := preload("res://assets/maps/casa/interior.png")
const ESCALA_CUARTO := 1.6
const TAMANO := Vector2(1760, 1034)
## Piso donde se puede caminar (trapecio de la imagen): arriba y abajo, con sus orillas.
const PISO_ARRIBA := 630.0
const PISO_ABAJO := 1005.0
## Dentro de la casa el guardián se ve más grande: con el tamaño del valle quedaba diminuto
## junto a los muebles.
const ESCALA_GUARDIAN := 1.7
## Franja oscura arriba del cuarto, para que la interfaz no tape las ventanas.
const MARGEN_ARRIBA := 150.0
## Salida: luz de la puerta a media orilla de abajo.
const PUERTA := Vector2(893, 1034)
const COLOR_NOCHE := Color(0.5, 0.55, 0.8)

## Muebles que se compran con hojas. Se dibujan en el cuarto cuando ya son tuyos.
const MUEBLES := {
	"maceta": {"nombre": "Maceta con brote", "costo": 4, "icono": "res://assets/objects/zona1/brote_control.png"},
	"tule": {"nombre": "Tule en maceta", "costo": 5, "icono": "res://assets/objects/zona3/tule.png"},
	"alfombra": {"nombre": "Alfombra tejida", "costo": 6, "icono": "res://assets/maps/casa/alfombra.png"},
	"lampara": {"nombre": "Lámpara de barro", "costo": 7, "icono": "res://assets/maps/casa/lampara.png"},
	"cuadro": {"nombre": "Cuadro de la mariposa monarca", "costo": 8, "icono": "res://assets/ui/bitacora/monarca.png"},
	"pecera": {"nombre": "Pecera con achoque", "costo": 12, "icono": "res://assets/maps/casa/pecera.png"},
}
## Insignias por tipo de ayuda y cuántas ayudas pide cada nivel.
const INSIGNIAS := {"basura": "Limpieza del valle", "cria": "Rescate de crías", "plantar": "Siembra de árboles",
	"flores": "Jardín de mariposas"}
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

	_pedidos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_PEDIDOS))
	_noche = CanvasModulate.new()
	add_child(_noche)
	var rutas := ["res://assets/ui/bitacora/monarca.png", "res://assets/objects/zona1/brote_control.png",
		"res://assets/objects/zona3/tule.png", "res://assets/objects/zona3/achoque.png"]
	for mueble in ["repisa", "tablero", "alfombra"]:
		rutas.append("res://assets/maps/casa/%s.png" % mueble)
	for zona in ZONAS:
		rutas.append(ZONAS[zona][1])
	for id in Bitacora.especies:
		rutas.append(Bitacora.RUTA_IMAGEN % id)
	for ruta in rutas:
		if ResourceLoader.exists(ruta):
			_texturas[ruta] = load(ruta)
	# Las imágenes de la bitácora traen margen vacío: se recortan para que se apoyen en la repisa.
	for id in Bitacora.especies:
		var ruta: String = Bitacora.RUTA_IMAGEN % id
		if _texturas.has(ruta):
			var recorte := AtlasTexture.new()
			recorte.atlas = _texturas[ruta]
			recorte.region = Rect2(_texturas[ruta].get_image().get_used_rect())
			_texturas[ruta] = recorte
	_fondo_panel.visible = false
	_negro.modulate.a = 0.0
	%BtnCerrar.pressed.connect(cerrar_panel)
	var camara := gara.camara
	camara.limit_left = 0
	camara.limit_top = int(-MARGEN_ARRIBA)
	camara.limit_right = int(TAMANO.x)
	camara.limit_bottom = int(TAMANO.y)
	for parte in ["Sprite", "Sombra", "CollisionShape2D"]:
		(gara.get_node(parte) as Node2D).scale *= ESCALA_GUARDIAN
	_crear_paredes()
	_crear_zona("Cama", Vector2(500, 830), "E  Descansar y guardar", func(_j): descansar())
	_crear_zona("Repisa", Vector2(880, 660), "E  Ver trofeos", func(_j): abrir_panel("trofeos"))
	_crear_zona("Tablero", Vector2(1480, 660), "E  Tablero de pedidos", func(_j): abrir_panel("tablero"))
	_crear_zona("Baul", Vector2(1480, 850), "E  Muebles", func(_j): abrir_panel("muebles"))
	_crear_zona("Puerta", PUERTA + Vector2(0, -50), "E  Salir al valle", func(_j): salir())
	hud.get_node("PanelLugar/HBox/VBox/Lugar").text = "Tu casa"
	_actualizar()
	hud.mostrar_objetivo("Esta es tu casa. Descansa en la cama, mira tus trofeos o compra muebles.", 6.0)


func _crear_paredes() -> void:
	var paredes := StaticBody2D.new()
	# Orillas del piso (los muros de los lados van en diagonal), pared del fondo y abajo.
	for poligono in [
		[Vector2(-60, -60), Vector2(200, -60), Vector2(190, PISO_ARRIBA), Vector2(50, PISO_ABAJO + 20), Vector2(-60, PISO_ABAJO + 20)],
		[Vector2(1560, -60), Vector2(1820, -60), Vector2(1820, PISO_ABAJO + 20), Vector2(1710, PISO_ABAJO + 20), Vector2(1570, PISO_ARRIBA)],
		[Vector2(-60, -60), Vector2(1820, -60), Vector2(1820, PISO_ARRIBA), Vector2(-60, PISO_ARRIBA)],
		[Vector2(-60, PISO_ABAJO), Vector2(1820, PISO_ABAJO), Vector2(1820, TAMANO.y + 60), Vector2(-60, TAMANO.y + 60)],
	]:
		var forma := CollisionPolygon2D.new()
		forma.polygon = PackedVector2Array(poligono)
		paredes.add_child(forma)
	# Cama y baúl (solo la base, por donde pisan).
	for caja in [Rect2(235, 700, 190, 220), Rect2(1405, 700, 150, 60)]:
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
	# Bajo los pies del guardián (aquí se ve más grande): arriba tapaba la repisa y el tablero.
	var etiqueta: Label = zona.get_node("Aviso")
	etiqueta.position.y = 25.0
	etiqueta.z_index = 5


func _actualizar() -> void:
	_noche.color = COLOR_NOCHE if Juego.es_de_noche else Color.WHITE
	Sonido.musica("casa_noche" if Juego.es_de_noche else "casa")
	_poner_muebles()
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
	hud.mostrar_objetivo("Partida guardada. Ya es de %s." % ("noche" if Juego.es_de_noche else "día"), 4.0)


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
	for linea in ["•  Recoger basura donde buscan comida.", "•  Encontrar a una cría perdida y llevarla con su mamá.", "•  Plantar arbolitos para que haya sombra y comida.",
			"•  Plantar flores con néctar para las mariposas."]:
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

## Muebles del piso: [imagen, pie (abajo al centro), ancho en el cuarto, mueble que hay que comprar].
const EN_EL_PISO := [
	["cama", Vector2(330, 925), 200.0, ""],
	["baul", Vector2(1480, 760), 150.0, ""],
	["lampara", Vector2(570, 700), 64.0, "lampara"],
	["pecera", Vector2(600, 985), 150.0, "pecera"],
	["maceta", Vector2(650, 668), 66.0, "maceta"],
	["maceta", Vector2(1610, 960), 70.0, "tule"],
]


func _poner_muebles() -> void:
	for hijo in $Objetos.get_children():
		if hijo.is_in_group(&"mueble"):
			hijo.queue_free()
	for datos in EN_EL_PISO:
		if not datos[3].is_empty() and datos[3] not in Juego.muebles:
			continue
		var mueble := Sprite2D.new()
		mueble.add_to_group(&"mueble")
		mueble.texture = load("res://assets/maps/casa/%s.png" % datos[0])
		mueble.scale = Vector2.ONE * datos[2] / mueble.texture.get_width()
		mueble.offset = Vector2(0, -mueble.texture.get_height() / 2.0)
		mueble.position = datos[1]
		$Objetos.add_child(mueble)
		# Lo que lleva cada maceta y lo que nada en la pecera.
		var dentro := {"maceta": "res://assets/objects/zona1/brote_control.png", "tule": "res://assets/objects/zona3/tule.png"}
		if dentro.has(datos[3]):
			var planta := Sprite2D.new()
			planta.texture = load(dentro[datos[3]])
			var alto_mueble: float = mueble.texture.get_height()
			planta.scale = Vector2.ONE * 1.1 * mueble.texture.get_width() / planta.texture.get_width()
			planta.position = Vector2(0, -alto_mueble * 0.75)
			planta.offset = Vector2(0, -planta.texture.get_height() / 2.0)
			planta.show_behind_parent = true
			mueble.add_child(planta)


func _draw() -> void:
	draw_rect(Rect2(-100, -MARGEN_ARRIBA - 100, TAMANO.x + 200, MARGEN_ARRIBA + 100), Color(0.17, 0.1, 0.05))
	draw_texture_rect(INTERIOR, Rect2(Vector2.ZERO, INTERIOR.get_size() * ESCALA_CUARTO), false)
	# Luz de día (o de noche, más tenue) que entra por la puerta de abajo.
	var luz := Color(1, 0.93, 0.7, 0.16 if Juego.es_de_noche else 0.3)
	draw_polygon(PackedVector2Array([PUERTA + Vector2(-85, 0), PUERTA + Vector2(85, 0), PUERTA + Vector2(130, -170), PUERTA + Vector2(-130, -170)]),
		PackedColorArray([luz, luz, Color(luz, 0.0), Color(luz, 0.0)]))
	if "alfombra" in Juego.muebles:
		_textura("res://assets/maps/casa/alfombra.png", Rect2(1040, 690, 330, 220))
	# Sombras bajo los muebles del piso, para que se vean apoyados.
	for datos in EN_EL_PISO:
		if datos[3].is_empty() or datos[3] in Juego.muebles:
			_sombra(datos[1], datos[2] * 0.5)
	# Cuadro sobre la cama, repisa de trofeos entre las ventanas y tablero junto a la ventana.
	if "cuadro" in Juego.muebles:
		var marco := StyleBoxTexture.new()
		marco.texture = _texturas["res://assets/maps/casa/tablero.png"]
		marco.set_texture_margin_all(16)
		draw_style_box(marco, Rect2(206, 326, 148, 168))
		draw_rect(Rect2(226, 346, 108, 128), Color(0.93, 0.89, 0.77))
		_textura("res://assets/ui/bitacora/monarca.png", Rect2(232, 360, 96, 100))
	_textura("res://assets/maps/casa/repisa.png", Rect2(742, 330, 276, 226))
	var x := 768.0
	for zona in ZONAS:
		var color := Color.WHITE if Juego.zona_esta_completa(zona) else Color(0.1, 0.08, 0.06, 0.7)
		_textura(ZONAS[zona][1], Rect2(x, 262, 76, 82), color)
		x += 76.0
	var en_repisa := 0
	for id in Bitacora.especies:
		if id in Juego.especies_descubiertas and en_repisa < 5:
			_textura(Bitacora.RUTA_IMAGEN % id, Rect2(758 + en_repisa * 50, 430, 46, 42))
			en_repisa += 1
	_textura("res://assets/maps/casa/tablero.png", Rect2(1390, 330, 170, 130))
	if not Juego.pedido.is_empty():
		var fuente := _titulo.get_theme_default_font()
		draw_string_outline(fuente, Vector2(1532, 372), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, 12, Color(0.2, 0.12, 0.04))
		draw_string(fuente, Vector2(1532, 372), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0.99, 0.86, 0.3))
	if "lampara" in Juego.muebles and Juego.es_de_noche:
		for r in [180.0, 120.0, 70.0]:
			draw_circle(Vector2(570, 640), r, Color(1, 0.8, 0.4, 0.1), true, -1.0, true)


func _sombra(pie: Vector2, radio: float) -> void:
	var puntos := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		puntos.append(pie + Vector2(cos(a) * radio, sin(a) * radio * 0.18))
	draw_colored_polygon(puntos, Color(0.1, 0.05, 0.02, 0.35))


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

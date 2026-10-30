extends CanvasLayer
## Granja del guardián (autoload "Granja"): milpa, corral, recolección, pesca, cocina y energía.
## El estado vive en Juego (inventario, parcelas, corral...) para que se guarde con la partida.
## Los datos (objetos, cultivos, recetas) están en data/granja.json.
##
##     Granja.dar("maiz", 2)       Granja.plantar(0, "maiz")      Granja.cocinar("atole")
##
## También es el menú de la mochila (tecla I) y de la cocina.

signal inventario_cambio
signal energia_cambio(valor: float)

const RUTA := "res://data/granja.json"
const ICONO := "res://assets/ui/granja/%s.png"
const PLANTA := "res://assets/objects/granja/%s_%d.png"
const PARCELAS := 6
## Etapa final de un cultivo (0 sembrado, 1 y 2 creciendo, 3 listo para cosechar).
const LISTO := 3
const PESCA_POR_DIA := 3
## Probabilidad de que lo que pica sea una cría (se regresa al agua).
const PROB_CRIA := 0.3
const SILVESTRES_POR_DIA := 6

var datos: Dictionary = {}
var abierto := ""

var _fondo: Control
var _titulo: Label
var _contenido: VBoxContainer
var _cerrar: Button


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	_construir_panel()
	Juego.dia_cambio.connect(func(_d): nuevo_dia())
	Juego.zona_completada.connect(_al_completar_zona)


# ---------------------------------------------------------------- Inventario

func cantidad(id: String) -> int:
	return int(Juego.inventario.get(id, 0))


func dar(id: String, n := 1) -> void:
	Juego.inventario[id] = cantidad(id) + n
	inventario_cambio.emit()


## Devuelve false (y no quita nada) si no alcanza.
func quitar(id: String, n := 1) -> bool:
	if cantidad(id) < n:
		return false
	Juego.inventario[id] = cantidad(id) - n
	if Juego.inventario[id] == 0:
		Juego.inventario.erase(id)
	inventario_cambio.emit()
	return true


func nombre(id: String) -> String:
	return datos["objetos"].get(id, {}).get("nombre", id)


func icono(id: String) -> Texture2D:
	var ruta: String = ICONO % datos["objetos"].get(id, {}).get("icono", id)
	return load(ruta) if ResourceLoader.exists(ruta) else null


## Al restaurar cada zona te regalan semillas de la milpa (y las partidas viejas las reciben al cargar).
func _al_completar_zona(zona: String) -> void:
	dar_semillas_de(zona)


func dar_semillas_de(zona: String) -> void:
	if Juego.tiene_marca("semillas_" + zona) or not datos["zonas_semillas"].has(zona):
		return
	Juego.marcar("semillas_" + zona)
	for id in datos["zonas_semillas"][zona]:
		dar(id, int(datos["zonas_semillas"][zona][id]))


# ---------------------------------------------------------------- Energía

func fijar_energia(valor: float) -> void:
	Juego.energia = clampf(valor, 0.0, 100.0)
	energia_cambio.emit(Juego.energia)


## Con poca energía el guardián camina más despacio (nunca se pierde ni se muere).
func factor_velocidad() -> float:
	return 0.65 if Juego.juego_terminado() and Juego.energia < 25.0 else 1.0


func comer(id: String) -> bool:
	var energia := int(datos["objetos"].get(id, {}).get("energia", 0))
	if energia <= 0 or not quitar(id):
		return false
	fijar_energia(Juego.energia + energia)
	Sonido.efecto("correcto")
	return true


# ---------------------------------------------------------------- Milpa

func parcela(i: int) -> Dictionary:
	while Juego.parcelas.size() < PARCELAS:
		Juego.parcelas.append({"cultivo": "", "etapa": 0, "regada": false})
	return Juego.parcelas[i]


func plantar(i: int, cultivo: String) -> bool:
	var p := parcela(i)
	if not p["cultivo"].is_empty() or not quitar(datos["cultivos"][cultivo]["semilla"]):
		return false
	p["cultivo"] = cultivo
	p["etapa"] = 0
	p["regada"] = false
	Sonido.efecto("correcto")
	return true


func regar(i: int) -> bool:
	var p := parcela(i)
	if p["cultivo"].is_empty() or p["regada"] or int(p["etapa"]) >= LISTO:
		return false
	p["regada"] = true
	Sonido.efecto("chapoteo")
	return true


## Devuelve lo que se cosechó ({objeto: cantidad}) o {} si aún no está lista.
func cosechar(i: int) -> Dictionary:
	var p := parcela(i)
	if p["cultivo"].is_empty() or int(p["etapa"]) < LISTO:
		return {}
	var cosecha: Dictionary = datos["cultivos"][p["cultivo"]]["cosecha"]
	for id in cosecha:
		dar(id, int(cosecha[id]))
	p["cultivo"] = ""
	p["etapa"] = 0
	p["regada"] = false
	Sonido.efecto("recoger")
	return cosecha


func textura_planta(i: int) -> Texture2D:
	var p := parcela(i)
	if p["cultivo"].is_empty():
		return null
	return load(PLANTA % [p["cultivo"], int(p["etapa"])])


## Cada mañana: lo regado crece una etapa, el corral da huevos y leche y salen plantas silvestres.
func nuevo_dia() -> void:
	for i in PARCELAS:
		var p := parcela(i)
		if not p["cultivo"].is_empty() and p["regada"]:
			p["etapa"] = mini(int(p["etapa"]) + 1, LISTO)
			p["regada"] = false
	for animal in Juego.corral:
		if int(Juego.corral[animal].get("comio", -1)) == Juego.dia - 1:
			Juego.corral[animal]["listo"] = true


# ---------------------------------------------------------------- Corral

## Hablar con la gallina o la cabra: si tiene huevo o leche se recoge; si no ha comido hoy se le da
## de comer (al día siguiente tendrá). Devuelve el texto que se le muestra al jugador.
func atender(animal: String) -> String:
	var estado: Dictionary = Juego.corral.get(animal, {"comio": -1, "listo": false})
	Juego.corral[animal] = estado
	var producto: String = datos["corral"][animal]["producto"]
	if estado["listo"]:
		estado["listo"] = false
		dar(producto)
		Sonido.efecto("recoger")
		return "¡Recogiste %s!" % nombre(producto).to_lower()
	if int(estado["comio"]) == Juego.dia:
		return "Ya comió hoy. Mañana tendrá %s." % nombre(producto).to_lower()
	estado["comio"] = Juego.dia
	Sonido.efecto("correcto")
	return "Le diste de comer. Mañana tendrá %s." % nombre(producto).to_lower()


# ---------------------------------------------------------------- Pesca

func pescas_de_hoy() -> int:
	return int(Juego.pesca.get("veces", 0)) if int(Juego.pesca.get("dia", 0)) == Juego.dia else 0


func puede_pescar() -> bool:
	return pescas_de_hoy() < PESCA_POR_DIA


## Resultado de una pesca que salió bien: "pescado" o "cria" (la cría se regresa al agua y no cuenta).
func sacar_pez(es_cria: bool) -> String:
	if es_cria:
		return "cria"
	Juego.pesca = {"dia": Juego.dia, "veces": pescas_de_hoy() + 1}
	dar("pescado")
	return "pescado"


# ---------------------------------------------------------------- Recolección

## Plantas silvestres y leña de hoy (dentro de `area`, fuera de `prohibido`); cambian cada día.
func silvestres_de_hoy(area: Rect2, prohibido: Array[Rect2] = []) -> Array:
	if Juego.silvestres_dia != Juego.dia:
		Juego.silvestres_dia = Juego.dia
		Juego.silvestres.clear()
		for i in SILVESTRES_POR_DIA:
			var pos := Vector2.ZERO
			for intento in 20:
				pos = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
				if not prohibido.any(func(r: Rect2): return r.has_point(pos)):
					break
			Juego.silvestres.append({"tipo": datos["silvestres"].pick_random(), "pos": pos})
	return Juego.silvestres


func recolectar(dato: Dictionary) -> void:
	Juego.silvestres.erase(dato)
	dar(dato["tipo"])
	Sonido.efecto("recoger")


# ---------------------------------------------------------------- Cocina

func puede_cocinar(receta: Dictionary) -> bool:
	for id in receta["ingredientes"]:
		if cantidad(id) < int(receta["ingredientes"][id]):
			return false
	return true


func cocinar(id_receta: String) -> bool:
	var receta: Dictionary = {}
	for r in datos["recetas"]:
		if r["id"] == id_receta:
			receta = r
	if receta.is_empty() or not puede_cocinar(receta):
		return false
	for id in receta["ingredientes"]:
		quitar(id, int(receta["ingredientes"][id]))
	dar(id_receta)
	if id_receta not in Juego.recetario:
		Juego.recetario.append(id_receta)
	Sonido.efecto("zona_restaurada")
	return true


# ---------------------------------------------------------------- Menús (mochila, semillas, cocina)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("mochila"):
		if abierto == "mochila":
			cerrar()
		elif abierto.is_empty() and _se_puede_abrir():
			abrir_mochila()
		else:
			return
		get_viewport().set_input_as_handled()
	elif not abierto.is_empty() and evento.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func _se_puede_abrir() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.is_in_group(&"con_reloj") and not Dialogo.activo \
		and not Juego.entrada_bloqueada and not get_tree().paused


func abrir_mochila() -> void:
	_abrir("mochila", "Mochila")
	_contenido.add_child(_texto("Energía: %d / 100" % int(Juego.energia), 28, Color(0.8, 1, 0.7)))
	if Juego.inventario.is_empty():
		_contenido.add_child(_texto("Tu mochila está vacía. Siembra, recolecta plantas en el valle o pesca en el muelle del río."))
		return
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 40)
	rejilla.add_theme_constant_override("v_separation", 8)
	for id in Juego.inventario:
		var energia := int(datos["objetos"].get(id, {}).get("energia", 0))
		rejilla.add_child(_fila(id, "%s  x%d" % [nombre(id), cantidad(id)],
			"COMER (+%d)" % energia if energia > 0 else "", func(): comer(id); abrir_mochila()))
	_contenido.add_child(rejilla)


## Elegir qué sembrar en la parcela `i`. `al_plantar` se llama después de sembrar.
func abrir_semillas(i: int, al_plantar: Callable) -> void:
	_abrir("semillas", "¿Qué siembras?")
	_contenido.add_child(_texto(datos["milpa"], 24, Color(0.85, 0.95, 0.8)))
	var alguna := false
	for cultivo in datos["cultivos"]:
		var semilla: String = datos["cultivos"][cultivo]["semilla"]
		if cantidad(semilla) == 0:
			continue
		alguna = true
		_contenido.add_child(_fila(semilla, "%s  x%d" % [nombre(semilla), cantidad(semilla)], "SEMBRAR",
			func(): plantar(i, cultivo); cerrar(); al_plantar.call()))
	if not alguna:
		_contenido.add_child(_texto("No tienes semillas. Cosecha lo que sembraste: cada cosecha te da una semilla nueva."))


func abrir_cocina() -> void:
	_abrir("cocina", "Fogón")
	_contenido.add_child(_texto("Cada platillo necesita leña para el fuego. Recoge ramas en el valle.", 24, Color(0.85, 0.95, 0.8)))
	for receta in datos["recetas"]:
		var partes := []
		for id in receta["ingredientes"]:
			partes.append("%d %s" % [int(receta["ingredientes"][id]), nombre(id).to_lower()])
		var conocida: bool = receta["id"] in Juego.recetario
		var texto := "%s%s\n%s" % [nombre(receta["id"]), "  ★" if conocida else "", ", ".join(partes)]
		var boton := "COCINAR" if puede_cocinar(receta) else ""
		_contenido.add_child(_fila(receta["id"], texto, boton, func():
			if cocinar(receta["id"]):
				abrir_cocina()
				_contenido.add_child(_texto("¡Cocinaste %s! %s" % [nombre(receta["id"]).to_lower(), receta["dato"]], 24, Color(0.99, 0.86, 0.45)))))


func cerrar() -> void:
	if abierto.is_empty():
		return
	abierto = ""
	_fondo.visible = false
	await get_tree().process_frame
	Juego.entrada_bloqueada = false


func _abrir(tipo: String, titulo: String) -> void:
	abierto = tipo
	_titulo.text = titulo
	for hijo in _contenido.get_children():
		hijo.queue_free()
	_fondo.visible = true
	Juego.entrada_bloqueada = true
	_cerrar.grab_focus()


func _fila(id: String, texto: String, boton: String, accion: Callable) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	var imagen := TextureRect.new()
	imagen.custom_minimum_size = Vector2(56, 56)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture = icono(id)
	fila.add_child(imagen)
	var etiqueta := _texto(texto, 24)
	etiqueta.custom_minimum_size.x = 300
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(etiqueta)
	if not boton.is_empty():
		var b := Button.new()
		b.text = boton
		b.custom_minimum_size = Vector2(200, 52)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(accion)
		fila.add_child(b)
	return fila


func _texto(texto: String, tam := 26, color := Color(1, 0.96, 0.86)) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return etiqueta


func _construir_panel() -> void:
	_fondo = ColorRect.new()
	(_fondo as ColorRect).color = Color(0, 0, 0, 0.55)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.visible = false
	add_child(_fondo)
	var caja := PanelContainer.new()
	caja.theme = load("res://assets/ui/tema.tres")
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.offset_left = -700
	caja.offset_right = 700
	caja.offset_top = -470
	caja.offset_bottom = 470
	# Que crezca hacia los dos lados si el contenido es más grande (si no, se sale por la derecha).
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	_fondo.add_child(caja)
	var margen := MarginContainer.new()
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 80)
	margen.add_theme_constant_override("margin_top", 60)
	margen.add_theme_constant_override("margin_bottom", 46)
	caja.add_child(margen)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margen.add_child(vbox)
	_titulo = _texto("", 44, Color(0.99, 0.86, 0.45))
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_titulo)
	var desplazar := ScrollContainer.new()
	desplazar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desplazar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(desplazar)
	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 10)
	desplazar.add_child(_contenido)
	_cerrar = Button.new()
	_cerrar.text = "CERRAR"
	_cerrar.custom_minimum_size = Vector2(300, 66)
	_cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cerrar.pressed.connect(cerrar)
	vbox.add_child(_cerrar)

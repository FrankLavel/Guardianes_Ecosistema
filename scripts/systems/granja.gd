extends CanvasLayer
## Granja del guardián (autoload "Granja"): milpa, corral, recolección, pesca, cocina y energía.
## El estado vive en Juego (inventario, parcelas, corral...) para que se guarde con la partida.
## Los datos (objetos, cultivos, recetas) están en data/granja.json.
##
##     Granja.dar("maiz", 2)       Granja.plantar(0, "maiz")      Granja.cocinar("atole")
##
## También es el menú de la mochila (tecla I), de la cocina y del tianguis.
##
## Niveles: todo lo que se hace en la granja da experiencia (datos["xp"]); al subir de nivel se
## desbloquean surcos, la cabra, recetas y más pedidos del tianguis (datos["niveles"]).

signal inventario_cambio
signal energia_cambio(valor: float)
signal nivel_subio(nivel: int, texto: String)
signal parcelas_cambio

const RUTA := "res://data/granja.json"
const ICONO := "res://assets/ui/granja/%s.png"
const PLANTA := "res://assets/objects/granja/%s_%d.png"
## Surcos de la milpa: se empieza con 6 y se desbloquean más al subir de nivel.
const PARCELAS_MAX := 12
## Etapa final de un cultivo (0 sembrado, 1 y 2 creciendo, 3 listo para cosechar).
const LISTO := 3
const PESCA_POR_DIA := 3
## Probabilidad de que lo que pica sea una cría (se regresa al agua).
const PROB_CRIA := 0.3
const SILVESTRES_POR_DIA := 6

var datos: Dictionary = {}
var abierto := ""

## Donde vuelan los productos recogidos (esquina del panel del valle, junto a "Hojas").
const DESTINO_RECOGIDOS := Vector2(140, 90)

var _efectos: Node2D
var _fondo: Control
var _titulo: Label
var _contenido: VBoxContainer
var _cerrar: Button


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	_efectos = Node2D.new()
	add_child(_efectos)
	_construir_panel()
	Juego.dia_cambio.connect(func(_d): nuevo_dia())
	Juego.zona_completada.connect(_al_completar_zona)


func _process(delta: float) -> void:
	if Juego.reloj_corre():
		crecer(delta / Juego.SEGUNDOS_POR_HORA)


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


## Lo recogido se ve: los íconos saltan desde donde salieron (en el mundo) y vuelan a la esquina
## de la pantalla, con un "+3 Maíz" que sube y se desvanece.
## `fila`: si salen varias cosas a la vez, cada etiqueta va un renglón más arriba.
func mostrar_recogida(id: String, n: int, en_mundo: Vector2, fila := 0) -> void:
	var textura := icono(id)
	if textura == null or not is_inside_tree():
		return
	var inicio: Vector2 = get_viewport().get_canvas_transform() * en_mundo
	for k in mini(n, 5):
		var pieza := Sprite2D.new()
		pieza.texture = textura
		var lado := 64.0 / maxf(textura.get_width(), textura.get_height())
		pieza.position = inicio
		pieza.scale = Vector2.ZERO
		_efectos.add_child(pieza)
		var salto := inicio + Vector2(randf_range(-50, 50) + (k - n / 2.0) * 22.0, randf_range(-110, -80))
		var vuelo := pieza.create_tween()
		vuelo.tween_interval(k * 0.08)
		vuelo.tween_property(pieza, "scale", Vector2.ONE * lado, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		vuelo.parallel().tween_property(pieza, "position", salto, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		vuelo.tween_interval(0.3)
		vuelo.tween_property(pieza, "position", DESTINO_RECOGIDOS, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		vuelo.parallel().tween_property(pieza, "scale", Vector2.ONE * lado * 0.5, 0.55)
		vuelo.tween_callback(pieza.queue_free)
	var etiqueta := _texto("+%d %s" % [n, nombre(id)], 30, Color(0.99, 0.95, 0.6))
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	etiqueta.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	etiqueta.add_theme_constant_override("outline_size", 10)
	etiqueta.position = inicio + Vector2(-80, -170 - fila * 40)
	_efectos.add_child(etiqueta)
	var subir := etiqueta.create_tween()
	subir.tween_property(etiqueta, "position:y", etiqueta.position.y - 50, 1.2)
	subir.parallel().tween_property(etiqueta, "modulate:a", 0.0, 1.2).set_delay(0.6)
	subir.tween_callback(etiqueta.queue_free)


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
	while Juego.parcelas.size() < PARCELAS_MAX:
		Juego.parcelas.append({"cultivo": "", "etapa": 0, "regada": false, "horas": 0.0})
	return Juego.parcelas[i]


func surcos() -> int:
	return int(desbloqueado("surcos", 6))


func plantar(i: int, cultivo: String) -> bool:
	var p := parcela(i)
	if not p["cultivo"].is_empty() or not quitar(datos["cultivos"][cultivo]["semilla"]):
		return false
	p["cultivo"] = cultivo
	p["etapa"] = 0
	p["regada"] = false
	p["horas"] = 0.0
	Sonido.efecto("correcto")
	parcelas_cambio.emit()
	return true


func regar(i: int) -> bool:
	var p := parcela(i)
	if p["cultivo"].is_empty() or p["regada"] or int(p["etapa"]) >= LISTO:
		return false
	p["regada"] = true
	Sonido.efecto("chapoteo")
	parcelas_cambio.emit()
	return true


## Lo que se sembró y se regó crece con el tiempo (en horas del juego: 1 hora = 30 s).
func crecer(horas: float) -> void:
	var cambio := false
	for p in Juego.parcelas:
		if p["cultivo"].is_empty() or not p["regada"] or int(p["etapa"]) >= LISTO:
			continue
		p["horas"] = float(p.get("horas", 0.0)) + horas
		var etapa := mini(int(p["horas"] * LISTO / float(datos["cultivos"][p["cultivo"]]["horas"])), LISTO)
		if etapa != int(p["etapa"]):
			p["etapa"] = etapa
			cambio = true
	if cambio:
		parcelas_cambio.emit()


## Minutos reales que faltan para cosechar la parcela `i` (0 si no está creciendo).
func minutos_restantes(i: int) -> int:
	var p := parcela(i)
	if p["cultivo"].is_empty() or not p["regada"]:
		return 0
	var falta: float = float(datos["cultivos"][p["cultivo"]]["horas"]) - float(p.get("horas", 0.0))
	return maxi(ceili(falta * Juego.SEGUNDOS_POR_HORA / 60.0), 0)


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
	p["horas"] = 0.0
	Sonido.efecto("recoger")
	dar_xp(int(datos["xp"]["cosechar"]))
	parcelas_cambio.emit()
	return cosecha


func textura_planta(i: int) -> Texture2D:
	var p := parcela(i)
	if p["cultivo"].is_empty():
		return null
	return load(PLANTA % [p["cultivo"], int(p["etapa"])])


## Cada mañana el corral da huevos y leche (las plantas silvestres cambian solas al pedirlas).
func nuevo_dia() -> void:
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
		dar_xp(int(datos["xp"]["corral"]))
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
	dar_xp(int(datos["xp"]["pescar"]))
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
	dar_xp(int(datos["xp"]["recolectar"]))


# ---------------------------------------------------------------- Cocina

func puede_cocinar(receta: Dictionary) -> bool:
	if nivel() < int(receta.get("nivel", 1)):
		return false
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
	dar_xp(int(datos["xp"]["cocinar"]))
	return true


# ---------------------------------------------------------------- Niveles

func nivel() -> int:
	var n := 0
	for minimo in datos["niveles"]["xp"]:
		if Juego.xp >= int(minimo):
			n += 1
	return n


## Experiencia que falta para el siguiente nivel ([actual dentro del nivel, total del nivel]).
func progreso_nivel() -> Array:
	var tabla: Array = datos["niveles"]["xp"]
	var n := nivel()
	if n >= tabla.size():
		return [1, 1]
	var desde := int(tabla[n - 1])
	return [Juego.xp - desde, int(tabla[n]) - desde]


func dar_xp(n: int) -> void:
	var antes := nivel()
	Juego.xp += n
	for nuevo in range(antes + 1, nivel() + 1):
		var desbloqueo: Dictionary = datos["niveles"]["desbloqueos"].get(str(nuevo), {})
		Sonido.efecto("zona_restaurada")
		nivel_subio.emit(nuevo, desbloqueo.get("texto", ""))


## Valor de `clave` según lo que ya se desbloqueó (el del nivel más alto alcanzado).
func desbloqueado(clave: String, por_omision: Variant) -> Variant:
	var valor: Variant = por_omision
	for n in range(2, nivel() + 1):
		var desbloqueo: Dictionary = datos["niveles"]["desbloqueos"].get(str(n), {})
		if desbloqueo.has(clave):
			valor = desbloqueo[clave]
	return valor


# ---------------------------------------------------------------- Tianguis

## Pedidos que se pueden entregar en el tianguis; siempre hay tantos como permite el nivel.
func pedidos_tianguis() -> Array:
	while Juego.tianguis.size() < int(desbloqueado("pedidos", 3)):
		Juego.tianguis.append(nuevo_pedido())
	return Juego.tianguis


## Pide de 1 a 2 cosas que el guardián ya puede conseguir.
func nuevo_pedido() -> Dictionary:
	var posibles := ["huevo", "pescado"]
	for zona_cultivo in [["rio", "frijol"], ["bosque", "maiz"], ["lago", "calabaza"]]:
		if Juego.zona_esta_completa(zona_cultivo[0]):
			posibles.append(zona_cultivo[1])
	if desbloqueado("cabra", false):
		posibles.append("leche")
	for receta in Juego.recetario:
		posibles.append(receta)
	posibles.shuffle()
	var cosas := {}
	var valor := 0
	for id in posibles.slice(0, randi_range(1, 2)):
		var es_platillo: bool = id in Juego.recetario
		var n := randi_range(1, 2) if es_platillo else randi_range(1, 3)
		cosas[id] = n
		valor += n * int(datos["objetos"][id].get("valor", 1))
	return {"cosas": cosas, "hojas": valor + 1, "xp": valor * 3}


func puede_entregar(pedido: Dictionary) -> bool:
	for id in pedido["cosas"]:
		if cantidad(id) < int(pedido["cosas"][id]):
			return false
	return true


func entregar(i: int) -> bool:
	var pedido: Dictionary = pedidos_tianguis()[i]
	if not puede_entregar(pedido):
		return false
	for id in pedido["cosas"]:
		quitar(id, int(pedido["cosas"][id]))
	Juego.dar_hojas(int(pedido["hojas"]))
	Juego.tianguis[i] = nuevo_pedido()
	Sonido.efecto("correcto")
	dar_xp(int(pedido["xp"]))
	return true


## Cambia un pedido difícil por otro (gratis: solo es para no atorarse).
func cambiar_pedido(i: int) -> void:
	pedidos_tianguis()[i] = nuevo_pedido()


func comprar_semilla(id: String) -> bool:
	if not Juego.gastar_hojas(int(datos["semillas_tianguis"][id])):
		return false
	dar(id)
	Sonido.efecto("recoger")
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
		var bloqueada := nivel() < int(receta.get("nivel", 1))
		var texto := "%s%s\n%s" % [nombre(receta["id"]), "  ★" if conocida else "",
			"Se desbloquea en el nivel %d" % int(receta["nivel"]) if bloqueada else ", ".join(partes)]
		var boton := "COCINAR" if puede_cocinar(receta) else ""
		_contenido.add_child(_fila(receta["id"], texto, boton, func():
			if cocinar(receta["id"]):
				abrir_cocina()
				_contenido.add_child(_texto("¡Cocinaste %s! %s" % [nombre(receta["id"]).to_lower(), receta["dato"]], 24, Color(0.99, 0.86, 0.45)))))


func abrir_tianguis() -> void:
	_abrir("tianguis", "Tianguis del valle")
	var avance := progreso_nivel()
	_contenido.add_child(_texto("Nivel %d  ·  %d / %d de experiencia  ·  Tienes %d hojas" % [nivel(), avance[0], avance[1], Juego.hojas],
		26, Color(0.8, 1, 0.7)))
	_contenido.add_child(_texto("Pedidos de la gente del valle:", 28, Color(0.99, 0.86, 0.45)))
	var pedidos := pedidos_tianguis()
	for i in pedidos.size():
		_contenido.add_child(_fila_pedido(i, pedidos[i]))
	_contenido.add_child(_texto("Semillas:", 28, Color(0.99, 0.86, 0.45)))
	for id in datos["semillas_tianguis"]:
		var precio := int(datos["semillas_tianguis"][id])
		_contenido.add_child(_fila(id, "%s  (tienes %d)" % [nombre(id), cantidad(id)],
			"COMPRAR (%d hojas)" % precio if Juego.hojas >= precio else "", func(): comprar_semilla(id); abrir_tianguis()))


func _fila_pedido(i: int, pedido: Dictionary) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	for id in pedido["cosas"]:
		var imagen := TextureRect.new()
		imagen.custom_minimum_size = Vector2(52, 52)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.texture = icono(id)
		fila.add_child(imagen)
		var falta := cantidad(id) < int(pedido["cosas"][id])
		var cuenta := _texto("%d/%d" % [mini(cantidad(id), int(pedido["cosas"][id])), int(pedido["cosas"][id])], 26,
			Color(1, 0.7, 0.6) if falta else Color(0.7, 1, 0.6))
		cuenta.autowrap_mode = TextServer.AUTOWRAP_OFF
		cuenta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(cuenta)
	var premio := _texto("→  %d hojas, %d exp." % [int(pedido["hojas"]), int(pedido["xp"])], 24)
	premio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	premio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(premio)
	var boton := Button.new()
	boton.custom_minimum_size = Vector2(200, 52)
	boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if puede_entregar(pedido):
		boton.text = "ENTREGAR"
		boton.pressed.connect(func(): entregar(i); abrir_tianguis())
	else:
		boton.text = "CAMBIAR"
		boton.tooltip_text = "Cambiar por otro pedido"
		boton.pressed.connect(func(): cambiar_pedido(i); abrir_tianguis())
	fila.add_child(boton)
	return fila


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

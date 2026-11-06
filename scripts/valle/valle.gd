extends Node2D
## Valle de Tzintzun (mapa aéreo): conecta las zonas y cambia según el progreso de la partida.

const TAMANO := Vector2(2800, 1800)
## Gris del mundo cuando nada está restaurado (0 = colores normales).
const DESATURACION_INICIAL := 0.55
const ESCENA_FINAL := "res://scenes/ui/Final.tscn"
const ESCENA_CASA := "res://scenes/valle/Casa.tscn"
const ESCENA_ANIMAL := preload("res://scenes/valle/AnimalValle.tscn")
const ESCENA_PUERTA := preload("res://scenes/valle/ZonaInteraccion.tscn")
## Frente a la puerta de la casa de adobe (dónde se entra y dónde se aparece al salir).
const PUERTA_CASA := Vector2(1615, 905)

## Granja (aparece cuando las tres zonas están restauradas): milpa (ver Granja.celdas_milpa), corrales,
## muelle para pescar y zona donde salen plantas silvestres y leña.
## Centro del corral de las gallinas si el jugador no lo ha movido; los corrales de las otras especies
## buscan un lugar libre cerca de aquí (ver Corral).
const CORRAL := Vector2(1375, 1195)
const ADORNOS_MOVIBLES := ["ArbustoFlores", "Encino", "Oyamel", "Piedras", "RocaGrande", "Sabino", "Tocon"]
## Lo que se puede quitar para hacerle lugar a un corral nuevo (los árboles y las rocas grandes no).
const ADORNOS_CHICOS := ["ArbustoFlores", "Piedras", "Tocon"]
const ADORNO := preload("res://scripts/valle/adorno.gd")
const MUELLE := Vector2(800, 760)
## Puesto del tianguis, junto al cruce de caminos.
const TIANGUIS := Vector2(1690, 1075)
const PUESTO := preload("res://assets/maps/valle/objetos/tianguis.png")
const AREA_SILVESTRES := Rect2(900, 300, 1700, 1300)
## Talleres de la granja (se ven desde el principio; cada uno se abre en su nivel). Ahí van si el
## jugador no los ha movido.
const TALLERES := {"molino": Vector2(1250, 330), "queseria": Vector2(1250, 610), "colmena": Vector2(2150, 420)}

## Animales que pasean por el valle. Cada uno aparece cuando su zona ya está restaurada.
const VENADO := "res://assets/characters/animales/valle/venado_frames.tres"
const GARZA := "res://assets/characters/animales/valle/garza_frames.tres"
const PATO := "res://assets/characters/animales/valle/pato_frames.tres"
const MONARCA := "res://assets/characters/animales/valle/monarca_frames.tres"
const ANIMALES := [
	{"nombre": "Venado1", "especie": "venado", "zona": "bosque", "pos": Vector2(2300, 250), "paseo": Rect2(2240, 160, 140, 180),
		"cuadros": VENADO, "escala": 0.3, "velocidad": 70.0},
	{"nombre": "Venado2", "especie": "venado", "zona": "bosque", "pos": Vector2(1100, 1450), "paseo": Rect2(950, 1350, 450, 250),
		"cuadros": VENADO, "escala": 0.3, "velocidad": 70.0},
	{"nombre": "Garza1", "especie": "garza", "zona": "rio", "pos": Vector2(850, 640), "paseo": Rect2(800, 560, 90, 360),
		"cuadros": GARZA, "escala": 0.27, "velocidad": 40.0},
	{"nombre": "Garza2", "especie": "garza", "zona": "rio", "pos": Vector2(800, 1250), "paseo": Rect2(770, 1150, 100, 250),
		"cuadros": GARZA, "escala": 0.27, "velocidad": 40.0},
	{"nombre": "Pato1", "especie": "pato_mexicano", "zona": "lago", "pos": Vector2(2050, 1400), "paseo": Rect2(1900, 1320, 300, 200),
		"cuadros": PATO, "escala": 0.22, "velocidad": 50.0},
	{"nombre": "Pato2", "especie": "pato_mexicano", "zona": "lago", "pos": Vector2(1950, 1700), "paseo": Rect2(1850, 1690, 200, 70),
		"cuadros": PATO, "escala": 0.22, "velocidad": 50.0},
	{"nombre": "Monarca1", "especie": "monarca", "zona": "bosque", "pos": Vector2(1500, 450), "paseo": Rect2(1300, 300, 500, 300),
		"cuadros": MONARCA, "escala": 0.1, "velocidad": 60.0, "vuela": true},
	{"nombre": "Monarca2", "especie": "monarca", "zona": "bosque", "pos": Vector2(2150, 800), "paseo": Rect2(2000, 700, 400, 300),
		"cuadros": MONARCA, "escala": 0.1, "velocidad": 60.0, "vuela": true},
]

@onready var gara: GaraAerea = $Objetos/Gara
@onready var rio: Line2D = $Rio
@onready var filtro_restauracion: ColorRect = $Restauracion/Filtro
@onready var hud: CanvasLayer = $HUD
@onready var puzzle_filtro: PuzzleFiltro = $PuzzleFiltro
@onready var puzzle_habitat: PuzzleHabitat = $PuzzleHabitat
@onready var puzzle_residuos: PuzzleResiduos = $PuzzleResiduos

var pedidos: PedidosAyuda
var animales: Array[AnimalValle] = []
var _noche: CanvasModulate
var _luz_casa: PointLight2D
var _aviso_hambre := false
var _suelo_milpa: MilpaSuelo
## Un corral por especie (especie -> Corral).
var corrales: Dictionary = {}
var decorador: Decorador


func _ready() -> void:
	add_to_group(&"jugable")
	add_to_group(&"con_reloj")
	_al_cambiar_noche(Juego.es_de_noche)
	Juego.noche_cambio.connect(_al_cambiar_noche)
	Juego.hora_cambio.connect(_al_cambiar_hora)
	var camara := gara.camara
	camara.limit_left = 0
	camara.limit_top = 0
	camara.limit_right = int(TAMANO.x)
	camara.limit_bottom = int(TAMANO.y)
	if Juego.tiene_posicion_valle:
		gara.global_position = Juego.posicion_valle
		gara.reset_physics_interpolation()
		camara.reset_smoothing()
	Juego.zona_completada.connect(func(_z): actualizar_mundo())
	puzzle_filtro.resuelto.connect(_al_resolver_filtro)
	puzzle_filtro.cerrado.connect(_al_cerrar_filtro)
	puzzle_habitat.resuelto.connect(_al_resolver_habitat)
	puzzle_habitat.cerrado.connect(_al_cerrar_habitat)
	puzzle_residuos.resuelto.connect(_al_resolver_residuos)
	puzzle_residuos.cerrado.connect(_al_cerrar_residuos)
	_especies_de_zonas_terminadas()
	_noche = CanvasModulate.new()
	add_child(_noche)
	# De noche las ventanas de la casa dan una luz cálida.
	var degradado := Gradient.new()
	degradado.set_color(0, Color(1, 0.8, 0.45, 1))
	degradado.set_color(1, Color(1, 0.6, 0.25, 0))
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 256
	textura.height = 256
	_luz_casa = PointLight2D.new()
	_luz_casa.texture = textura
	_luz_casa.texture_scale = 1.6
	_luz_casa.energy = 0.9
	_luz_casa.position = PUERTA_CASA + Vector2(40, -90)
	add_child(_luz_casa)
	_crear_animales()
	# Achi vive en un estanque (los achoques solo viven en el agua).
	var estanque := Estanque.new()
	estanque.name = "Estanque"
	estanque.position = $Objetos/Achi.position + Vector2(0, -15)
	add_child(estanque)
	move_child(estanque, $Objetos.get_index())
	var puerta: ZonaInteraccion = ESCENA_PUERTA.instantiate()
	puerta.texto_aviso = "E  Entrar a tu casa"
	puerta.position = PUERTA_CASA
	puerta.activada.connect(_entrar_a_casa)
	$Objetos.add_child(puerta)
	pedidos = PedidosAyuda.new()
	pedidos.name = "Pedidos"
	add_child(pedidos)
	pedidos.configurar(animales, gara, hud, $Objetos)
	_crear_granja()
	pedidos.pedido_cambio.connect(func(): actualizar_mundo())
	Juego.hojas_cambiaron.connect(func(_h): actualizar_mundo())
	actualizar_mundo()
	hud.mostrar_objetivo(objetivo_actual())
	Dialogo.terminado.connect(_al_terminar_dialogo)


func _crear_granja() -> void:
	if not Granja.granja_abierta():
		return
	# Los árboles, arbustos y rocas del valle se pueden mover en el modo decorar (dentro de la granja).
	for nodo in $Objetos.get_children():
		if nodo is StaticBody2D and String(nodo.name).rstrip("0123456789") in ADORNOS_MOVIBLES:
			nodo.position = Granja.posicion("adorno:" + nodo.name, nodo.position)
			nodo.set_script(ADORNO)
			nodo.add_to_group(&"movible")
	# Partidas de antes de la granja: se les dan las semillas de las zonas que ya restauraron.
	for zona in Juego.zonas_completadas:
		Granja.dar_semillas_de(zona)
	# Los adornos del valle que caen en la milpa se quitan (los cuadros nuevos ya no se encima con nada).
	for celda in Granja.celdas_milpa():
		_quitar_adornos(Granja.rect_de_milpa(celda).grow(40))
	_poner_parcelas()
	Granja.milpa_cambio.connect(_al_cambiar_milpa)
	var muelle: ZonaInteraccion = ESCENA_PUERTA.instantiate()
	muelle.name = "Pescar"
	muelle.texto_aviso = "E  Pescar"
	muelle.position = MUELLE
	muelle.activada.connect(func(_j): pescar())
	$Objetos.add_child(muelle)
	# Tianguis: pedidos de la gente del valle y venta de semillas.
	var tianguis: ZonaInteraccion = ESCENA_PUERTA.instantiate()
	tianguis.name = "Tianguis"
	tianguis.texto_aviso = "E  Tianguis"
	tianguis.position = TIANGUIS
	tianguis.activada.connect(func(_j): Granja.abrir_tianguis())
	for nodo in $Objetos.get_children():
		if nodo is StaticBody2D and Rect2(TIANGUIS - Vector2(150, 140), Vector2(300, 200)).has_point(nodo.position):
			nodo.queue_free()
	var puesto := Sprite2D.new()
	puesto.texture = PUESTO
	puesto.scale = Vector2(0.22, 0.22)
	puesto.offset = Vector2(0, -PUESTO.get_height() / 2.0 + 30)
	tianguis.add_child(puesto)
	# No se puede atravesar la mesa del puesto.
	var mesa := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(180, 36)
	forma.shape = rect
	forma.position = Vector2(0, -20)
	mesa.add_child(forma)
	tianguis.add_child(mesa)
	$Objetos.add_child(tianguis)
	for id in TALLERES:
		var pos := Granja.posicion(id, TALLERES[id])
		_quitar_adornos(Rect2(pos - Vector2(150, 200), Vector2(300, 260)))
		var taller := Taller.new()
		taller.name = "Taller_" + id
		taller.id = id
		taller.position = pos
		_zona_de(taller, 95.0)
		$Objetos.add_child(taller)
	for arbol in Juego.frutales:
		nuevo_frutal(arbol["id"], arbol)
	for puesta in Juego.decoraciones["puestas"]:
		var decoracion := Decoracion.new()
		decoracion.id = puesta["id"]
		decoracion.puesta = puesta
		decoracion.position = Vector2(float(puesta["x"]), float(puesta["y"]))
		$Objetos.add_child(decoracion)
	# Modo decorar: con el botón del HUD o la tecla C.
	decorador = Decorador.new()
	decorador.name = "Decorador"
	decorador.valle = self
	decorador.tamano = TAMANO
	add_child(decorador)
	decorador.movido.connect(_al_mover_en_granja)
	var boton := Button.new()
	boton.text = "DECORAR" if Tactil.activo else "DECORAR (C)"
	boton.add_theme_font_size_override("font_size", 24)
	boton.focus_mode = Control.FOCUS_NONE
	# En el celular, lejos de la orilla (la funda del teléfono estorba en las esquinas).
	boton.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 80 if Tactil.activo else 24)
	boton.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	boton.grow_vertical = Control.GROW_DIRECTION_BEGIN
	boton.pressed.connect(func(): decorador.salir() if decorador.activo else decorador.entrar())
	hud.add_child(boton)
	# Caminos rectos: los que pinta el jugador. La primera vez se ponen unos que unen la casa con el
	# tianguis, el muelle y la milpa (en lugar de los caminos chuecos de antes).
	if not Juego.caminos_listos:
		Juego.caminos_listos = true
		Granja.trazar_camino(Vector2i(16, 19), Vector2i(44, 19))
		Granja.trazar_camino(Vector2i(32, 18), Vector2i(32, 19))
		Granja.trazar_camino(Vector2i(17, 15), Vector2i(17, 19))
		Granja.trazar_camino(Vector2i(29, 11), Vector2i(29, 19))
	var caminos := CaminosSuelo.new()
	caminos.name = "CaminosGranja"
	add_child(caminos)
	move_child(caminos, $Caminos.get_index() + 1)
	_actualizar_caminos_viejos()
	# Terrenos: la cuadrícula del modo decorar y los que se pueden comprar.
	var terrenos := Terrenos.new()
	terrenos.name = "Terrenos"
	terrenos.decorador = decorador
	add_child(terrenos)
	move_child(terrenos, $Objetos.get_index())
	_poner_corral()
	_actualizar_prohibido()
	_poner_silvestres()
	Granja.corral_cambio.connect(_poner_corral)
	Juego.noche_cambio.connect(_dormir_aves)
	_bienvenida_granja()
	_crecer_milpa()
	Juego.dia_cambio.connect(_al_cambiar_dia)
	Granja.nivel_subio.connect(_al_subir_nivel)


## La primera vez que aparece la granja, Don Chucho explica cómo funciona.
func _bienvenida_granja() -> void:
	if "don_chucho_granja" in Juego.dialogos_vistos:
		return
	await get_tree().create_timer(1.2).timeout
	while Dialogo.activo or Transicion.en_curso:
		await get_tree().process_frame
	if "don_chucho_granja" not in Juego.dialogos_vistos and is_inside_tree():
		await Dialogo.mostrar("don_chucho_granja")
		hud.mostrar_objetivo("Siembra en tu milpa y alimenta a tus animales en el comedero.", 6.0)


## Un surco por cada cuadro de la milpa que puso el jugador (ver Granja.celdas_milpa).
func _poner_parcelas() -> void:
	if _suelo_milpa == null:
		_suelo_milpa = MilpaSuelo.new()
		_suelo_milpa.name = "SueloMilpa"
		add_child(_suelo_milpa)
		move_child(_suelo_milpa, $Objetos.get_index())
	_suelo_milpa.queue_redraw()
	for nodo in $Objetos.get_children():
		if nodo is Parcela:
			gara.quitar_interactuable(nodo)
			$Objetos.remove_child(nodo)
			nodo.queue_free()
	var celdas := Granja.celdas_milpa()
	for i in celdas.size():
		var parcela := Parcela.new()
		parcela.name = "Parcela%d" % i
		parcela.indice = i
		parcela.position = Granja.centro_de_milpa(celdas[i])
		_zona_de(parcela, 55.0)
		parcela.aviso.connect(avisar)
		$Objetos.add_child(parcela)


func _al_cambiar_milpa() -> void:
	_poner_parcelas()
	_actualizar_prohibido()
	for planta in get_tree().get_nodes_in_group(&"silvestre"):
		if Granja.milpa_toca(Rect2(planta.position - Vector2(20, 20), Vector2(40, 40))):
			Juego.silvestres.erase(planta.get_meta(&"dato"))
			planta.queue_free()


## Un árbol frutal en el valle (ya plantado o, con `puesta` vacía, en la mano del modo decorar).
func nuevo_frutal(id: String, puesta: Dictionary = {}) -> Frutal:
	var arbol := Frutal.new()
	arbol.id = id
	arbol.puesta = puesta
	if not puesta.is_empty():
		arbol.position = Vector2(float(puesta["x"]), float(puesta["y"]))
	_zona_de(arbol, 70.0)
	$Objetos.add_child(arbol)
	return arbol


## Los animales de la granja (ver Granja.animales_del_corral): los regalados al subir de nivel y los
## que se compran en el tianguis. Cada especie tiene su corral; el de una especie nueva busca solo un
## lugar libre dentro de la granja.
func _poner_corral() -> void:
	var lista := Granja.animales_del_corral()
	for especie in Granja.datos["corral"]:
		var ids := lista.filter(func(id): return Granja.especie_de(id) == especie)
		if ids.is_empty() or not ResourceLoader.exists(Granja.CUADROS_ANIMAL % especie):
			continue
		var corral: Corral = corrales.get(especie)
		if corral == null:
			corral = Corral.new()
			corral.especie = especie
			corral.name = "Corral_" + especie
			corral.base = float(Granja.datos["corral"][especie].get("corral", 1.0))
			corral.con_gallinero = especie in ["gallina", "guajolote"]
			var comedero := Comedero.new()
			comedero.name = "Comedero"
			_zona_de(comedero, 60.0)
			comedero.usado.connect(func(_c): _atender_corral_entero(corral))
			corral.comedero = comedero
			corral.ajustar(ids.size())
			corrales[especie] = corral
			var guardado := Juego.posiciones.has(corral.clave)
			corral.position = Granja.posicion(corral.clave, CORRAL)
			$Objetos.add_child(corral)
			if not guardado and especie != "gallina":
				await _buscar_lugar(corral)
				_quitar_adornos(corral.huella(), ADORNOS_CHICOS)
			else:
				_quitar_adornos(corral.huella().grow(30))
			_al_mover_en_granja(corral)
		var antes := corral.huella()
		corral.ajustar(ids.size())
		for i in ids.size():
			_poner_animal(ids[i], corral)
		if corral.huella() != antes:
			_quitar_adornos(corral.huella().grow(30))
			_al_mover_en_granja(corral)
			_avisar_si_no_cabe(corral)
	_actualizar_corral()
	_dormir_aves(Juego.es_de_noche, true)


func _poner_animal(id: String, corral: Corral) -> void:
	if $Objetos.has_node(id.to_pascal_case()):
		return
	var especie := Granja.especie_de(id)
	var dato: Dictionary = Granja.datos["corral"][especie]
	var animal: AnimalValle = ESCENA_ANIMAL.instantiate()
	animal.name = id.to_pascal_case()
	animal.set_meta(&"corral", id)
	animal.especie = especie
	animal.cuadros = load(Granja.CUADROS_ANIMAL % especie)
	animal.anim_quieto = &"idle"
	animal.anim_caminar = &"caminar"
	animal.escala = float(dato["escala"])
	animal.velocidad = 30.0
	# Cada uno empieza en otro lugar del corral para que no se encimen.
	var paseo := corral.paseo()
	animal.position = paseo.position + paseo.size * Vector2(randf_range(0.1, 0.9), randf_range(0.15, 0.85))
	animal.texto_aviso = "E  " + dato["nombre"]
	animal.hablaron.connect(_atender_corral)
	corral.agregar(animal)
	$Objetos.add_child(animal)


## Busca en toda la granja, empezando cerca del corral de las gallinas, el primer lugar donde cabe un
## corral nuevo.
func _buscar_lugar(corral: Corral) -> void:
	await get_tree().physics_frame
	var lugares: Array[Vector2] = []
	for x in range(0, int(TAMANO.x), 50):
		for y in range(0, int(TAMANO.y), 50):
			lugares.append(Vector2(x, y))
	lugares.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(CORRAL) < b.distance_squared_to(CORRAL))
	# Primero donde no hay nada; si no, donde solo estorban arbustos, tocones o piedras chicas.
	for ignorar in [[], ADORNOS_CHICOS]:
		for lugar in lugares:
			corral.mover_a(lugar)
			if decorador.cabe(corral, ignorar):
				Granja.fijar_posicion(corral.clave, corral.global_position)
				return
	corral.mover_a(CORRAL + Vector2(0, 280))
	avisar("Ya no hay lugar libre en tu granja: elige dónde va el corral nuevo, o expande tu granja.")
	decorador.acomodar(corral)


## De noche las aves se meten a su gallinero y en la mañana salen (los demás se quedan en su corral).
func _dormir_aves(es_noche: bool, al_instante := false) -> void:
	for corral: Corral in corrales.values():
		if not corral.con_gallinero:
			continue
		var puerta := corral.global_position + corral.puerta_local()
		for animal in corral.animales:
			if es_noche == not animal.visible:
				continue
			if es_noche:
				animal.esperar()
				animal.monitoring = false
				gara.quitar_interactuable(animal)
				if al_instante:
					animal.visible = false
					continue
				var entrar := animal.create_tween()
				entrar.tween_property(animal, "global_position", puerta, randf_range(1.2, 2.2))
				entrar.tween_callback(func(): animal.visible = false)
			else:
				animal.global_position = puerta
				animal.visible = true
				animal.monitoring = true
				animal.volver_a_pasear()


## Los árboles que quitó el corral al crecer desaparecen hasta el siguiente cuadro de física.
func _avisar_si_no_cabe(corral: Corral) -> void:
	await get_tree().physics_frame
	if decorador and not decorador.cabe(corral):
		avisar("¡Tu corral creció! Si quedó encimado con algo, muévelo con el modo decorar (C).")


func _al_subir_nivel(nivel: int, texto: String) -> void:
	if decorador:
		_poner_corral()
	var nuevos: int = await _crecer_milpa()
	var extra := ""
	if nuevos > 0:
		extra = "  Tu milpa creció %d cuadros: muévelos en DECORAR → MILPA." % nuevos
	elif Granja.celdas_milpa().size() < Granja.surcos():
		extra = "  Agrega tus cuadros nuevos en DECORAR → MILPA."
	hud.mostrar_objetivo("¡Subiste al nivel %d!%s%s" % [nivel, "  Desbloqueaste: " + texto if not texto.is_empty() else "", extra], 8.0)


## Pone los cuadros de milpa que da el nivel y todavía no están, pegados a la milpa que ya hay, donde no
## estorben nada. Devuelve cuántos puso.
func _crecer_milpa() -> int:
	if decorador == null:
		return 0
	await get_tree().physics_frame
	var puestos := 0
	var antes := decorador.pintar
	decorador.pintar = "milpa"
	var vueltas := 0
	while Granja.celdas_milpa().size() < Granja.surcos() and vueltas < 12:
		vueltas += 1
		var elegido := Vector2i(-999, -999)
		var celdas := Granja.celdas_milpa()
		for celda in celdas:
			for lado in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				if elegido == Vector2i(-999, -999) and decorador.se_puede_arar(celda + lado):
					elegido = celda + lado
		if elegido == Vector2i(-999, -999) or not Granja.poner_milpa(elegido):
			break
		puestos += 1
	decorador.pintar = antes
	return puestos


## Quita los adornos del valle (árboles, arbustos, rocas) cuyo pie cae en `zona`; con `solo`, nada más
## los de esos tipos.
func _quitar_adornos(zona: Rect2, solo: Array = []) -> void:
	for nodo in $Objetos.get_children():
		if nodo is StaticBody2D and not nodo.name.begins_with("Casa") and zona.has_point(nodo.position) 				and (solo.is_empty() or String(nodo.name).rstrip("0123456789") in solo):
			nodo.queue_free()


## Donde no se puede poner nada en el modo decorar: la milpa, el pasillo frente a la puerta de la casa,
## el frente del tianguis y del muelle, el estanque de Achi y el pie de las entradas a las zonas. Solo
## cuenta la base de cada cosa (lo que pisa), no su dibujo completo: el techo o un arco pueden tapar
## algo que está detrás sin estorbarle. La casa y el puesto ya chocan con su propia base.
func lugares_fijos(con_milpa := true) -> Array[Rect2]:
	var lugares: Array[Rect2] = [Rect2(PUERTA_CASA - Vector2(55, 20), Vector2(110, 90)),
		Rect2(TIANGUIS - Vector2(110, 30), Vector2(220, 80)), Rect2(MUELLE - Vector2(80, 50), Vector2(160, 100)),
		Rect2($Objetos/Achi.position - Vector2(170, 110), Vector2(340, 200))]
	for entrada in entradas():
		if entrada.visible:
			lugares.append(Rect2(entrada.position - Vector2(100, 50), Vector2(200, 100)))
	if con_milpa:
		for celda in Granja.celdas_milpa():
			lugares.append(Granja.rect_de_milpa(celda).grow(10))
	return lugares


func _animales_de_corral() -> Array[AnimalValle]:
	var lista: Array[AnimalValle] = []
	for corral: Corral in corrales.values():
		lista.append_array(corral.animales)
	return lista


## Los animales del valle no pisan la milpa, los corrales ni los talleres (estén donde estén).
func _actualizar_prohibido() -> void:
	var zonas: Array[Rect2] = []
	for celda in Granja.celdas_milpa():
		zonas.append(Granja.rect_de_milpa(celda).grow(16))
	for nodo in get_tree().get_nodes_in_group(&"movible"):
		if nodo is Corral or nodo is Taller:
			zonas.append(nodo.huella().grow(30))
	for animal in animales:
		animal.prohibido = zonas.duplicate()


## Algo cambió de lugar: los animales lo respetan y las plantas silvestres que quedaron debajo se van.
func _al_mover_en_granja(nodo: Node2D) -> void:
	_actualizar_prohibido()
	for planta in get_tree().get_nodes_in_group(&"silvestre"):
		if nodo.huella().grow(20).has_point(planta.position):
			Juego.silvestres.erase(planta.get_meta(&"dato"))
			planta.queue_free()


## Las zonas de interacción de la granja son más chicas que la de una puerta.
func _zona_de(nodo: Area2D, radio: float) -> void:
	var forma := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	forma.shape = circulo
	nodo.add_child(forma)
	nodo.collision_layer = 0
	nodo.collision_mask = 2
	nodo.monitorable = false
	var etiqueta := Label.new()
	etiqueta.name = "Aviso"
	etiqueta.add_theme_font_size_override("font_size", 24)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.position = Vector2(-120, 12)
	etiqueta.size = Vector2(240, 36)
	nodo.add_child(etiqueta)


func _poner_silvestres() -> void:
	for hijo in $Objetos.get_children():
		if hijo.is_in_group(&"silvestre"):
			hijo.queue_free()
	var ocupado: Array[Rect2] = [
		Rect2($Objetos/Achi.position - Vector2(220, 160), Vector2(440, 280)), Rect2(PUERTA_CASA - Vector2(150, 250), Vector2(300, 300))]
	for nodo in get_tree().get_nodes_in_group(&"movible"):
		ocupado.append(nodo.huella().grow(60))
	for celda in Granja.celdas_milpa():
		ocupado.append(Granja.rect_de_milpa(celda).grow(60))
	for dato in Granja.silvestres_de_hoy(AREA_SILVESTRES, ocupado):
		var planta: ZonaInteraccion = ESCENA_PUERTA.instantiate()
		planta.add_to_group(&"silvestre")
		planta.set_meta(&"dato", dato)
		planta.texto_aviso = "E  Recoger " + Granja.nombre(dato["tipo"]).to_lower()
		planta.position = dato["pos"]
		var imagen := Sprite2D.new()
		imagen.texture = Granja.icono(dato["tipo"])
		imagen.scale = Vector2(0.4, 0.4)
		imagen.offset = Vector2(0, -imagen.texture.get_height() / 2.0)
		planta.add_child(imagen)
		planta.activada.connect(func(_j):
			Granja.recolectar(dato)
			Granja.mostrar_recogida(dato["tipo"], 1, planta.global_position)
			planta.queue_free())
		$Objetos.add_child(planta)


func _al_cambiar_dia(_dia: int) -> void:
	_poner_silvestres()
	_actualizar_corral()


func _atender_corral(animal: AnimalValle) -> void:
	var id: String = animal.get_meta(&"corral")
	var dato: Dictionary = Granja.datos["corral"][animal.especie]
	var producto: String = dato["producto"]
	var antes := Granja.cantidad(producto) if not producto.is_empty() else 0
	var texto := Granja.atender(id)
	if not producto.is_empty() and Granja.cantidad(producto) > antes:
		Granja.mostrar_recogida(producto, Granja.cantidad(producto) - antes, animal.global_position + Vector2(0, -40))
	else:
		avisar(texto)
	_actualizar_corral()


## El comedero: a todos los animales del corral se les da de comer y se recoge lo que ya dieron.
func _atender_corral_entero(corral: Corral) -> void:
	var ids: Array[String] = []
	for animal in corral.animales:
		ids.append(animal.get_meta(&"corral"))
	var hecho := Granja.atender_todos(ids)
	var fila := 0
	for producto in hecho["recogido"]:
		Granja.mostrar_recogida(producto, int(hecho["recogido"][producto]), corral.comedero.global_position + Vector2(0, -40), fila)
		fila += 1
	if int(hecho["comieron"]) > 0:
		avisar("Les diste de comer a %d. Mañana tendrán más." % int(hecho["comieron"]))
	elif hecho["recogido"].is_empty():
		avisar("Ya comieron hoy. Vuelve mañana para recoger lo que den.")
	_actualizar_corral()


## Globitos sobre los animales: comida si no han comido hoy, y lo que dan cuando ya está listo.
func _actualizar_corral() -> void:
	for animal in _animales_de_corral():
		var estado: Dictionary = Juego.corral.get(animal.get_meta(&"corral"), {"comio": -1, "listo": false})
		var producto: String = Granja.datos["corral"][animal.especie]["producto"]
		if estado["listo"] and not producto.is_empty():
			animal.mostrar_burbuja(Granja.icono(producto))
		elif int(estado["comio"]) != Juego.dia:
			animal.mostrar_burbuja(Granja.icono("maiz"))
		else:
			animal.mostrar_burbuja(null)


## Pesca responsable: se espera a que pique y se presiona E a tiempo. Las crías se regresan al agua
## y solo se pueden sacar PESCA_POR_DIA peces al día.
var _pescando := false


func pescar() -> void:
	if _pescando:
		return
	if not Granja.puede_pescar():
		avisar("Ya pescaste %d hoy. Si sacamos de más, los peces no alcanzan a tener crías." % Granja.PESCA_POR_DIA)
		return
	_pescando = true
	Juego.entrada_bloqueada = true
	avisar("Lanzaste el anzuelo... espera a que piquen.")
	await get_tree().create_timer(randf_range(1.5, 3.5)).timeout
	Juego.entrada_bloqueada = false
	Sonido.efecto("chapoteo")
	Granja.jugar({"tipo": "atinar", "escena": "agua", "titulo": "¡Picó un pez!",
		"texto": "Jala la caña con cuidado para que no se escape.", "iconos": [Granja.icono("pescado")],
		"meta": 3, "fallas_max": 3}, _al_terminar_pesca)


func _al_terminar_pesca(exito: bool) -> void:
	_pescando = false
	if not exito:
		avisar("Se escapó. Puedes intentarlo otra vez.")
	elif Granja.sacar_pez(randf() < Granja.PROB_CRIA) == "cria":
		avisar("Era una cría: la regresaste al agua para que crezca.")
	else:
		Granja.mostrar_recogida("pescado", 1, MUELLE)
		avisar("¡Pescaste un pescado! (%d de %d hoy)" % [Granja.pescas_de_hoy(), Granja.PESCA_POR_DIA])


func avisar(texto: String) -> void:
	hud.mostrar_objetivo(texto, 4.0)


func _crear_animales() -> void:
	for datos in ANIMALES:
		var animal: AnimalValle = ESCENA_ANIMAL.instantiate()
		animal.name = datos["nombre"]
		animal.especie = datos["especie"]
		animal.requiere_zona = datos["zona"]
		animal.position = datos["pos"]
		animal.zona_paseo = datos["paseo"]
		animal.cuadros = load(datos["cuadros"])
		if datos.get("vuela", false):
			animal.anim_quieto = &"volar"
			animal.anim_caminar = &"volar"
		else:
			animal.anim_quieto = &"idle"
			animal.anim_caminar = &"caminar"
			animal.anims_pausa.assign([&"comer", &"descansar"])
		animal.escala = datos["escala"]
		animal.velocidad = datos["velocidad"]
		animal.vuela = datos.get("vuela", false)
		$Objetos.add_child(animal)
		animales.append(animal)


func _entrar_a_casa(_jugador: Node2D) -> void:
	if Transicion.en_curso:
		return
	Juego.posicion_valle = PUERTA_CASA + Vector2(0, 50)
	Juego.tiene_posicion_valle = true
	Juego.guardar()
	gara.leer_entrada_del_jugador = false
	gara.entrada_direccion = Vector2.ZERO
	Transicion.ir_a(ESCENA_CASA)


## Partidas guardadas antes de que existiera la bitácora: se registran las especies de las zonas
## ya restauradas (sin aviso).
func _especies_de_zonas_terminadas() -> void:
	for id in Bitacora.especies:
		if Juego.zona_esta_completa(Bitacora.especies[id]["zona"]):
			Juego.descubrir_especie(id)


func objetivo_actual() -> String:
	if Juego.juego_terminado():
		if pedidos and Juego.pedido.get("estado") == "activo":
			return pedidos.texto_objetivo()
		return "Pasea por el valle: los animales te buscarán si necesitan ayuda. Tu casa es tu base."
	if "don_chucho_inicio" not in Juego.dialogos_vistos:
		return "Habla con Don Chucho, junto al río."
	if not Juego.tiene_marca("rio_nivel"):
		return "Entra al río por el arco de piedra."
	if not Juego.zona_esta_completa("rio"):
		return "Habla con Don Chucho: quiere enseñarte algo."
	if not Juego.tiene_marca("bosque_nivel"):
		if "mari_inicio" not in Juego.dialogos_vistos:
			return "Habla con Mari, la mariposa, junto al bosque."
		return "Entra al bosque por el arco de troncos."
	if not Juego.zona_esta_completa("bosque"):
		return "Habla con Mari: quiere enseñarte algo."
	if not Juego.tiene_marca("lago_nivel"):
		if "achi_inicio" not in Juego.dialogos_vistos:
			return "Habla con Achi, el achoque, junto al lago."
		return "Entra al lago por el arco de tule."
	if not Juego.zona_esta_completa("lago"):
		return "Habla con Achi: necesita tu ayuda."
	return "¡El valle está restaurado!"


func _process(_delta: float) -> void:
	_noche.color = Juego.color_del_cielo()
	hud.actualizar_energia(Juego.energia)
	hud.actualizar_nivel()
	if Juego.juego_terminado() and Juego.energia < 25.0 and not _aviso_hambre:
		_aviso_hambre = true
		avisar("Tienes hambre y caminas más despacio. Come algo de tu mochila (I).")
	elif Juego.energia >= 25.0:
		_aviso_hambre = false
	# La casa enciende su luz desde que empieza a oscurecer.
	_luz_casa.enabled = Juego.hora >= 19.0 or Juego.hora < 6.0


func _al_cambiar_noche(es_noche: bool) -> void:
	Sonido.musica("valle_noche" if es_noche else "valle")


func _al_cambiar_hora(_hora: int) -> void:
	hud.actualizar_reloj()


func _physics_process(_delta: float) -> void:
	# Guardar dónde está Gara (para "Continuar" y para volver del menú de pausa).
	if not Transicion.en_curso:
		Juego.posicion_valle = gara.global_position
		Juego.tiene_posicion_valle = true


## Los caminos chuecos de la escena llevan a las entradas de las zonas: el de cada zona se va cuando la
## restauras (su entrada ya no está), y con la granja el del muelle se cambia por uno recto.
func _actualizar_caminos_viejos() -> void:
	for nodo in [$Caminos/CaminoRio, $Caminos/CaminoBosque, $Caminos/CaminoLago]:
		nodo.visible = not Juego.zona_esta_completa(String(nodo.name).trim_prefix("Camino").to_lower())
	$Caminos/CaminoMuelle.visible = not Juego.zona_esta_completa("rio")


func entradas() -> Array[EntradaZona]:
	var lista: Array[EntradaZona] = []
	for nodo in $Objetos.get_children():
		if nodo is EntradaZona:
			lista.append(nodo)
	return lista


func actualizar_mundo() -> void:
	(rio.material as ShaderMaterial).set_shader_parameter(
		"contaminacion", 0.0 if Juego.zona_esta_completa("rio") else 1.0)
	(filtro_restauracion.material as ShaderMaterial).set_shader_parameter(
		"desaturacion", DESATURACION_INICIAL * (1.0 - Juego.progreso()))
	for entrada in entradas():
		entrada.actualizar_estado()
	_actualizar_caminos_viejos()
	# Con el río restaurado ya no hay tubería tirando agua sucia.
	for nodo in $Objetos.get_children():
		if nodo.name.begins_with("Tuberia"):
			nodo.visible = not Juego.zona_esta_completa("rio")
			nodo.collision_layer = 1 if nodo.visible else 0
	# Con el bosque restaurado, los tocones de la tala ya no están.
	for nodo in $Objetos.get_children():
		if nodo.name.begins_with("Tocon"):
			nodo.visible = not Juego.zona_esta_completa("bosque")
			nodo.collision_layer = 1 if nodo.visible else 0
	for animal in animales:
		animal.actualizar_visibilidad()
	hud.actualizar_reloj()
	hud.actualizar_progreso(Juego.zonas_completadas.size(), Juego.ZONAS.size(),
		Juego.hojas if Juego.juego_terminado() else -1)


func _al_terminar_dialogo(id: String) -> void:
	if id in ["don_chucho_filtro", "don_chucho_filtro_repetir"] and not Juego.zona_esta_completa("rio"):
		puzzle_filtro.reiniciar()
		puzzle_filtro.abrir()
		return
	if id in ["mari_habitat", "mari_habitat_repetir"] and not Juego.zona_esta_completa("bosque"):
		puzzle_habitat.abrir()
		return
	if id in ["achi_residuos", "achi_residuos_repetir"] and not Juego.zona_esta_completa("lago"):
		puzzle_residuos.abrir()
		return
	hud.mostrar_objetivo(objetivo_actual())


func _al_resolver_filtro() -> void:
	Juego.completar_zona("rio")
	Bitacora.descubrir("martin_pescador")
	Juego.guardar()


func _al_cerrar_filtro() -> void:
	if Juego.zona_esta_completa("rio"):
		Sonido.efecto("zona_restaurada")
		await Dialogo.mostrar("don_chucho_filtro_listo")
		hud.mostrar_objetivo("¡Nueva habilidad: NADAR! (solo en agua limpia)")
		await get_tree().create_timer(4.0).timeout
	hud.mostrar_objetivo(objetivo_actual())


func _al_resolver_habitat() -> void:
	Juego.completar_zona("bosque")
	Juego.guardar()


func _al_cerrar_habitat() -> void:
	if Juego.zona_esta_completa("bosque"):
		Sonido.efecto("zona_restaurada")
		await Dialogo.mostrar("mari_listo")
		hud.mostrar_objetivo("¡Nueva habilidad: PLANTAR ENREDADERAS!")
		await get_tree().create_timer(4.0).timeout
	hud.mostrar_objetivo(objetivo_actual())


func _al_resolver_residuos() -> void:
	Juego.completar_zona("lago")
	Juego.guardar()


func _al_cerrar_residuos() -> void:
	if not Juego.zona_esta_completa("lago"):
		hud.mostrar_objetivo(objetivo_actual())
		return
	Sonido.efecto("zona_restaurada")
	await Dialogo.mostrar("achi_listo")
	Transicion.ir_a(ESCENA_FINAL)

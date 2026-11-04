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

## Granja (aparece cuando el río se restaura): milpa arriba de la casa (4x3), corral, muelle
## para pescar y zona donde salen plantas silvestres y leña.
const MILPA := Vector2(1556, 294)
const COLUMNAS_MILPA := 4
const SEPARACION_MILPA := Vector2(136, 96)
## Centro del corral si el jugador no lo ha movido (ver Corral).
const CORRAL := Vector2(1375, 1195)
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
var corral: Corral
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
	if not Juego.zona_esta_completa("rio"):
		return
	# Partidas de antes de la granja: se les dan las semillas de las zonas que ya restauraron.
	for zona in Juego.zonas_completadas:
		Granja.dar_semillas_de(zona)
	# Los adornos del valle que caen donde va la milpa completa (12 surcos) se quitan.
	var milpa := Rect2(MILPA, SEPARACION_MILPA * Vector2(COLUMNAS_MILPA - 1, Granja.PARCELAS_MAX / COLUMNAS_MILPA - 1)).grow(140)
	for nodo in $Objetos.get_children():
		if nodo is StaticBody2D and milpa.has_point(nodo.position):
			nodo.queue_free()
	_poner_parcelas()
	# Corral (donde lo dejó el jugador). Los adornos del valle que le caen encima se quitan.
	corral = Corral.new()
	corral.name = "Corral"
	corral.position = Granja.posicion("corral", CORRAL)
	_quitar_adornos(corral.huella().grow(30))
	$Objetos.add_child(corral)
	_poner_corral()
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
	boton.text = "DECORAR (C)"
	boton.add_theme_font_size_override("font_size", 24)
	boton.focus_mode = Control.FOCUS_NONE
	boton.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	boton.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	boton.grow_vertical = Control.GROW_DIRECTION_BEGIN
	boton.pressed.connect(func(): decorador.salir() if decorador.activo else decorador.entrar())
	hud.add_child(boton)
	# Terrenos: la cuadrícula del modo decorar y los que se pueden comprar.
	var terrenos := Terrenos.new()
	terrenos.name = "Terrenos"
	terrenos.decorador = decorador
	add_child(terrenos)
	move_child(terrenos, $Objetos.get_index())
	_actualizar_prohibido()
	_poner_silvestres()
	Granja.corral_cambio.connect(_poner_corral)
	Juego.dia_cambio.connect(_al_cambiar_dia)
	Granja.nivel_subio.connect(_al_subir_nivel)


## Los 12 surcos de la milpa (COLUMNAS_MILPA por fila); los que faltan por desbloquear dicen en qué nivel se abren.
func _poner_parcelas() -> void:
	if _suelo_milpa == null:
		_suelo_milpa = MilpaSuelo.new()
		_suelo_milpa.name = "SueloMilpa"
		add_child(_suelo_milpa)
		move_child(_suelo_milpa, $Objetos.get_index())
	_suelo_milpa.tam = SEPARACION_MILPA
	_suelo_milpa.posiciones.clear()
	for i in Granja.PARCELAS_MAX:
		_suelo_milpa.posiciones.append(MILPA + Vector2(i % COLUMNAS_MILPA, i / COLUMNAS_MILPA) * SEPARACION_MILPA)
	_suelo_milpa.queue_redraw()
	for i in Granja.PARCELAS_MAX:
		if $Objetos.has_node("Parcela%d" % i):
			continue
		var parcela := Parcela.new()
		parcela.name = "Parcela%d" % i
		parcela.indice = i
		parcela.position = MILPA + Vector2(i % COLUMNAS_MILPA, i / COLUMNAS_MILPA) * SEPARACION_MILPA
		_zona_de(parcela, 55.0)
		parcela.aviso.connect(avisar)
		$Objetos.add_child(parcela)


## Los animales del corral (ver Granja.animales_del_corral): los regalados al subir de nivel y los que
## se compran en el tianguis. El corral crece cuando son más.
func _poner_corral() -> void:
	var lista := Granja.animales_del_corral()
	# Primero crece el corral, para repartir a los animales en todo su espacio.
	var antes := corral.huella()
	corral.ajustar(lista.size())
	for i in lista.size():
		var id := lista[i]
		var especie := Granja.especie_de(id)
		var cuadros := Granja.CUADROS_ANIMAL % especie
		if $Objetos.has_node(id.to_pascal_case()) or not ResourceLoader.exists(cuadros):
			continue
		var dato: Dictionary = Granja.datos["corral"][especie]
		var animal: AnimalValle = ESCENA_ANIMAL.instantiate()
		animal.name = id.to_pascal_case()
		animal.set_meta(&"corral", id)
		animal.especie = especie
		animal.cuadros = load(cuadros)
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
	if corral.huella() != antes:
		_quitar_adornos(corral.huella().grow(30))
		_al_mover_en_granja(corral)
		_avisar_si_no_cabe()
	_actualizar_corral()


## Los árboles que quitó el corral al crecer desaparecen hasta el siguiente cuadro de física.
func _avisar_si_no_cabe() -> void:
	await get_tree().physics_frame
	if decorador and not decorador.cabe(corral):
		avisar("¡Tu corral creció! Si quedó encimado con algo, muévelo con el modo decorar (C).")


func _al_subir_nivel(nivel: int, texto: String) -> void:
	_poner_parcelas()
	_poner_corral()
	hud.mostrar_objetivo("¡Subiste al nivel %d!%s" % [nivel, "  Desbloqueaste: " + texto if not texto.is_empty() else ""], 7.0)


## Quita los adornos del valle (árboles, arbustos, rocas) cuyo pie cae en `zona`.
func _quitar_adornos(zona: Rect2) -> void:
	for nodo in $Objetos.get_children():
		if nodo is StaticBody2D and not nodo.name.begins_with("Casa") and zona.has_point(nodo.position):
			nodo.queue_free()


## Donde no se puede poner nada en el modo decorar: la milpa, frente a la casa, el tianguis, el muelle,
## el estanque de Achi y las entradas a las zonas.
func lugares_fijos() -> Array[Rect2]:
	var lugares: Array[Rect2] = [_rect_milpa().grow(20), Rect2(PUERTA_CASA - Vector2(90, 30), Vector2(180, 110)),
		Rect2(TIANGUIS - Vector2(130, 130), Vector2(260, 160)), Rect2(MUELLE - Vector2(110, 90), Vector2(220, 180)),
		Rect2($Objetos/Achi.position - Vector2(170, 110), Vector2(340, 200))]
	for entrada in entradas():
		lugares.append(Rect2(entrada.position - Vector2(130, 170), Vector2(260, 230)))
	return lugares


func _rect_milpa() -> Rect2:
	return Rect2(MILPA - SEPARACION_MILPA / 2.0, SEPARACION_MILPA * Vector2(COLUMNAS_MILPA, Granja.PARCELAS_MAX / COLUMNAS_MILPA))


## Los animales del valle no pisan la milpa, el corral ni los talleres (estén donde estén).
func _actualizar_prohibido() -> void:
	var zonas: Array[Rect2] = [_rect_milpa().grow(16)]
	for nodo in get_tree().get_nodes_in_group(&"movible"):
		if not nodo is Decoracion:
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
	var ocupado: Array[Rect2] = [_rect_milpa().grow(60),
		Rect2($Objetos/Achi.position - Vector2(220, 160), Vector2(440, 280)), Rect2(PUERTA_CASA - Vector2(150, 250), Vector2(300, 300))]
	for nodo in get_tree().get_nodes_in_group(&"movible"):
		ocupado.append(nodo.huella().grow(60))
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


## Globitos sobre los animales: comida si no han comido hoy, y lo que dan cuando ya está listo.
func _actualizar_corral() -> void:
	for animal in corral.animales:
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

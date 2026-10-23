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
const COLOR_NOCHE := Color(0.5, 0.56, 0.82)

## Animales que pasean por el valle. Cada uno aparece cuando su zona ya está restaurada.
## shortcut: usan el arte de perfil de los niveles hasta que haya sprites vistos desde arriba.
const ANIMALES := [
	{"nombre": "Venado1", "especie": "venado", "zona": "bosque", "pos": Vector2(2050, 330), "paseo": Rect2(1900, 220, 380, 260),
		"cuadros": "res://assets/characters/animales/venado_frames.tres", "quieto": &"idle", "caminar": &"correr", "escala": 0.28, "velocidad": 70.0},
	{"nombre": "Venado2", "especie": "venado", "zona": "bosque", "pos": Vector2(1250, 1350), "paseo": Rect2(1050, 1250, 500, 300),
		"cuadros": "res://assets/characters/animales/venado_frames.tres", "quieto": &"comer", "caminar": &"correr", "escala": 0.28, "velocidad": 70.0},
	{"nombre": "Garza1", "especie": "garza", "zona": "rio", "pos": Vector2(850, 520), "paseo": Rect2(810, 420, 80, 460),
		"cuadros": "res://assets/characters/animales/zona1_animales_frames.tres", "quieto": &"garza", "caminar": &"garza", "escala": 0.4, "velocidad": 40.0},
	{"nombre": "Garza2", "especie": "garza", "zona": "rio", "pos": Vector2(800, 1250), "paseo": Rect2(770, 1150, 100, 250),
		"cuadros": "res://assets/characters/animales/zona1_animales_frames.tres", "quieto": &"garza", "caminar": &"garza", "escala": 0.4, "velocidad": 40.0},
	{"nombre": "Pato1", "especie": "pato_mexicano", "zona": "lago", "pos": Vector2(2050, 1400), "paseo": Rect2(1900, 1320, 300, 200),
		"cuadros": "res://assets/characters/animales/zona3_animales_frames.tres", "quieto": &"pato", "caminar": &"pato", "escala": 0.3, "velocidad": 50.0, "mira_derecha": false},
	{"nombre": "Pato2", "especie": "pato_mexicano", "zona": "lago", "pos": Vector2(1950, 1650), "paseo": Rect2(1850, 1590, 300, 110),
		"cuadros": "res://assets/characters/animales/zona3_animales_frames.tres", "quieto": &"pato", "caminar": &"pato", "escala": 0.3, "velocidad": 50.0, "mira_derecha": false},
	{"nombre": "Monarca1", "especie": "monarca", "zona": "bosque", "pos": Vector2(1500, 450), "paseo": Rect2(1300, 300, 500, 300),
		"cuadros": "res://assets/characters/mari/mari_frames.tres", "quieto": &"idle", "caminar": &"idle", "escala": 0.07, "velocidad": 60.0, "vuela": true},
	{"nombre": "Monarca2", "especie": "monarca", "zona": "bosque", "pos": Vector2(2150, 800), "paseo": Rect2(2000, 700, 400, 300),
		"cuadros": "res://assets/characters/mari/mari_frames.tres", "quieto": &"idle", "caminar": &"idle", "escala": 0.07, "velocidad": 60.0, "vuela": true},
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


func _ready() -> void:
	add_to_group(&"jugable")
	Sonido.musica("valle")
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
	pedidos.pedido_cambio.connect(func(): actualizar_mundo())
	Juego.hojas_cambiaron.connect(func(_h): actualizar_mundo())
	actualizar_mundo()
	hud.mostrar_objetivo(objetivo_actual())
	Dialogo.terminado.connect(_al_terminar_dialogo)


func _crear_animales() -> void:
	for datos in ANIMALES:
		var animal: AnimalValle = ESCENA_ANIMAL.instantiate()
		animal.name = datos["nombre"]
		animal.especie = datos["especie"]
		animal.requiere_zona = datos["zona"]
		animal.position = datos["pos"]
		animal.zona_paseo = datos["paseo"]
		animal.cuadros = load(datos["cuadros"])
		animal.anim_quieto = datos["quieto"]
		animal.anim_caminar = datos["caminar"]
		animal.escala = datos["escala"]
		animal.velocidad = datos["velocidad"]
		animal.vuela = datos.get("vuela", false)
		animal.mira_derecha = datos.get("mira_derecha", true)
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
	_noche.color = COLOR_NOCHE if Juego.es_de_noche else Color.WHITE
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

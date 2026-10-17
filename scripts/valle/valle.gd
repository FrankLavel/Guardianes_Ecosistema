extends Node2D
## Valle de Tzintzun (mapa aéreo): conecta las zonas y cambia según el progreso de la partida.

const TAMANO := Vector2(2800, 1800)
## Gris del mundo cuando nada está restaurado (0 = colores normales).
const DESATURACION_INICIAL := 0.55

@onready var gara: GaraAerea = $Objetos/Gara
@onready var rio: Line2D = $Rio
@onready var filtro_restauracion: ColorRect = $Restauracion/Filtro
@onready var hud: CanvasLayer = $HUD
@onready var puzzle_filtro: PuzzleFiltro = $PuzzleFiltro
@onready var puzzle_habitat: PuzzleHabitat = $PuzzleHabitat


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
	_especies_de_zonas_terminadas()
	actualizar_mundo()
	hud.mostrar_objetivo(objetivo_actual())
	Dialogo.terminado.connect(_al_terminar_dialogo)


## Partidas guardadas antes de que existiera la bitácora: se registran las especies de las zonas
## ya restauradas (sin aviso).
func _especies_de_zonas_terminadas() -> void:
	for id in Bitacora.especies:
		if Juego.zona_esta_completa(Bitacora.especies[id]["zona"]):
			Juego.descubrir_especie(id)


func objetivo_actual() -> String:
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
	if not Juego.zona_esta_completa("lago"):
		return "Ve al lago de Pátzcuaro."
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
	hud.actualizar_progreso(Juego.zonas_completadas.size(), Juego.ZONAS.size())


func _al_terminar_dialogo(id: String) -> void:
	if id in ["don_chucho_filtro", "don_chucho_filtro_repetir"] and not Juego.zona_esta_completa("rio"):
		puzzle_filtro.reiniciar()
		puzzle_filtro.abrir()
		return
	if id in ["mari_habitat", "mari_habitat_repetir"] and not Juego.zona_esta_completa("bosque"):
		puzzle_habitat.abrir()
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

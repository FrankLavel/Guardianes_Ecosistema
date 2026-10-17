extends Node2D
## Nivel 1 - El río contaminado.
## El guardián recoge la basura y cierra el paso del agua sucia de la fábrica (puzzle de las
## compuertas). Con cada acción el río se ve más limpio; al terminar ambas aparecen peces, y al
## llegar al árbol del final se completa el nivel.

## Distancia por debajo del terreno a partir de la cual el guardián reaparece.
const MARGEN_CAIDA := 200.0
## Cuánto vale arreglar las compuertas en la salud del río (en "basuras").
const PESO_COMPUERTAS := 4

var recogidas := 0
var _total_basura := 0
var nivel_terminado := false

@onready var terreno: TileMapLayer = $Terreno
@onready var guardian: Guardian = $Guardian
@onready var hud: HUD = $HUD
@onready var pantalla_final: NivelCompletado = $NivelCompletado
@onready var meta: Meta = $Meta
@onready var fondo: FondoZona = $FondoZona1
@onready var garza: AnimatedSprite2D = $Garza
@onready var valvulas: EstacionValvulas = $EstacionValvulas


func _ready() -> void:
	add_to_group(&"jugable")
	Sonido.musica("rio")
	_ajustar_camara()
	_total_basura = basuras().size()
	for basura in basuras():
		basura.recogida.connect(_al_recoger)
	for rio in rios():
		rio.guardian_cayo.connect(_al_caer_al_rio)
	meta.guardian_llego.connect(_al_llegar_a_meta)
	valvulas.resuelta.connect(_al_cambiar_salud)
	hud.actualizar(recogidas, total_basura(), salud_del_rio())
	hud.mostrar_mensaje("¡El río está contaminado!",
		"Acércate a la basura y presiona E para recogerla.", 6.0)


func basuras() -> Array[Basura]:
	var lista: Array[Basura] = []
	for nodo in get_tree().get_nodes_in_group(&"basura"):
		if is_ancestor_of(nodo):
			lista.append(nodo)
	return lista


func rios() -> Array[Rio]:
	var lista: Array[Rio] = []
	for nodo in get_tree().get_nodes_in_group(&"rio"):
		if is_ancestor_of(nodo):
			lista.append(nodo)
	return lista


func total_basura() -> int:
	return _total_basura


## De 0 (todo contaminado) a 1 (río limpio): basura recogida + compuertas arregladas.
func salud_del_rio() -> float:
	var puntos := recogidas + (PESO_COMPUERTAS if valvulas.esta_resuelta else 0)
	return float(puntos) / (total_basura() + PESO_COMPUERTAS)


func rio_limpio() -> bool:
	return is_equal_approx(salud_del_rio(), 1.0)


## Rectángulo del terreno en coordenadas globales.
func obtener_limites_terreno() -> Rect2:
	var celdas := terreno.get_used_rect()
	var tamano_tile := Vector2(terreno.tile_set.tile_size)
	var inicio := terreno.to_global(Vector2(celdas.position) * tamano_tile)
	return Rect2(inicio, Vector2(celdas.size) * tamano_tile)


func _ajustar_camara() -> void:
	var limites := obtener_limites_terreno()
	var camara := guardian.camara
	camara.limit_left = int(limites.position.x)
	camara.limit_top = int(limites.position.y) - 400
	camara.limit_right = int(limites.end.x)
	camara.limit_bottom = int(limites.end.y)
	guardian.limite_caida = limites.end.y + MARGEN_CAIDA


func _al_recoger(basura: Basura) -> void:
	recogidas += 1
	_al_cambiar_salud(basura)


func _al_cambiar_salud(basura: Basura = null) -> void:
	hud.actualizar(recogidas, total_basura(), salud_del_rio())
	var salud := salud_del_rio()
	for rio in rios():
		rio.limpieza = salud
	fondo.animar_limpieza(salud)
	if rio_limpio():
		for rio in rios():
			rio.mostrar_peces()
		# Vuelven los animales: señal visible de que el ecosistema se recupera.
		garza.visible = true
		garza.play()
		for especie in ["garza", "pez_rio", "acocil"]:
			Bitacora.descubrir(especie)
		hud.mostrar_mensaje("¡El río está limpio!",
			"Los peces regresaron. Camina hasta el árbol al final del camino.", 6.0)
	elif basura:
		var datos := basura.datos()
		hud.mostrar_mensaje(datos.get("nombre", ""), datos.get("dato", ""), 5.0)
	else:
		hud.mostrar_mensaje("¡Ya no sale agua sucia!",
			"Ahora el agua de la fábrica pasa por la planta de tratamiento.", 5.0)


func _al_caer_al_rio(cuerpo: Guardian) -> void:
	cuerpo.call_deferred("reaparecer")
	if rio_limpio():
		hud.mostrar_mensaje("¡Cuidado!", "El río no es lugar para nadar. Salta de orilla a orilla.", 4.0)
	else:
		hud.mostrar_mensaje("¡Cuidado!", "El agua contaminada no es segura. Salta de orilla a orilla.", 4.0)


func _al_llegar_a_meta(_cuerpo: Guardian) -> void:
	if nivel_terminado:
		return
	if rio_limpio():
		nivel_terminado = true
		pantalla_final.mostrar()
	elif recogidas < total_basura():
		var faltan := total_basura() - recogidas
		hud.mostrar_mensaje("Aún hay basura en el río",
			"Te falta recoger %d. ¡El río te necesita!" % faltan, 4.0)
	else:
		hud.mostrar_mensaje("Aún sale agua sucia al río",
			"Busca la tubería de la fábrica y revisa sus válvulas.", 4.0)

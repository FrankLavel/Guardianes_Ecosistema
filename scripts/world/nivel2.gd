extends Node2D
## Nivel 2 - El bosque de oyamel.
## Se sube la montaña plantando enredaderas para trepar; hay que apagar una fogata mal apagada,
## liberar a un venado atrapado y, arriba, reforestar el claro con el árbol correcto para cada
## altura (puzzle). Con cada acción el bosque del fondo pasa de talado a vivo.

const MARGEN_CAIDA := 200.0

var nivel_terminado := false

@onready var terreno: TileMapLayer = $Terreno
@onready var guardian: Guardian = $Guardian
@onready var hud: HUD = $HUD
@onready var pantalla_final: NivelCompletado = $NivelCompletado
@onready var meta: Meta = $Meta
@onready var fondo: FondoZona = $FondoZona2
@onready var fogata: Fogata = $Fogata
@onready var venado: VenadoAtrapado = $VenadoAtrapado
@onready var vivero: EstacionPuzzle = $Vivero
@onready var arboles_nuevos: Node2D = $ArbolesNuevos


func _ready() -> void:
	add_to_group(&"jugable")
	Sonido.musica("bosque")
	_ajustar_camara()
	fogata.apagada.connect(_al_apagar_fogata)
	venado.liberado.connect(_al_liberar_venado)
	vivero.resuelta.connect(_al_reforestar)
	for tierra in tierras():
		tierra.plantada.connect(_al_plantar)
	meta.guardian_llego.connect(_al_llegar_a_meta)
	arboles_nuevos.visible = vivero.esta_resuelta
	# La meta de este nivel es un gran oyamel.
	var arbol: Sprite2D = meta.get_node("Sprite2D")
	arbol.texture = preload("res://assets/maps/valle/objetos/oyamel.png")
	arbol.scale = Vector2(0.6, 0.6)
	arbol.offset = Vector2(0, -arbol.texture.get_height() / 2.0 + 8)
	_actualizar()
	hud.mostrar_mensaje("El bosque de oyamel está en peligro",
		"Busca la tierra fértil y presiona E para plantar una enredadera. ¡Luego trepa con ↑!", 7.0)


func tierras() -> Array[TierraFertil]:
	var lista: Array[TierraFertil] = []
	for nodo in $Tierras.get_children():
		if nodo is TierraFertil:
			lista.append(nodo)
	return lista


## Tareas que restauran el bosque: [hecha, nombre].
func tareas() -> Array:
	var lista := [
		[fogata.esta_apagada, "fogata"],
		[venado.esta_libre, "venado"],
		[vivero.esta_resuelta, "reforestar"],
	]
	for tierra in tierras():
		lista.append([tierra.esta_plantada, "enredadera"])
	return lista


func tareas_hechas() -> int:
	return tareas().filter(func(t): return t[0]).size()


## De 0 (bosque talado) a 1 (bosque vivo).
func salud_del_bosque() -> float:
	return float(tareas_hechas()) / tareas().size()


## Para terminar hacen falta las tres tareas principales (las enredaderas son el camino).
func bosque_listo() -> bool:
	return fogata.esta_apagada and venado.esta_libre and vivero.esta_resuelta


func obtener_limites_terreno() -> Rect2:
	var celdas := terreno.get_used_rect()
	var tamano_tile := Vector2(terreno.tile_set.tile_size)
	var inicio := terreno.to_global(Vector2(celdas.position) * tamano_tile)
	return Rect2(inicio, Vector2(celdas.size) * tamano_tile)


func _ajustar_camara() -> void:
	var limites := obtener_limites_terreno()
	var camara := guardian.camara
	# La primera y la última columna son las paredes del nivel: la cámara no las muestra.
	var columna := limites.size.x / terreno.get_used_rect().size.x
	camara.limit_left = int(limites.position.x + columna)
	camara.limit_top = int(limites.position.y) - 500
	camara.limit_right = int(limites.end.x - columna)
	camara.limit_bottom = int(limites.end.y)
	guardian.limite_caida = limites.end.y + MARGEN_CAIDA


func _actualizar() -> void:
	hud.actualizar(tareas_hechas(), tareas().size(), salud_del_bosque())
	fondo.animar_limpieza(salud_del_bosque())


func _al_plantar() -> void:
	_actualizar()
	hud.mostrar_mensaje("¡Creció una enredadera!",
		"Acércate y presiona ↑ para trepar. Las plantas trepadoras sostienen el suelo con sus raíces.", 5.0)


func _al_apagar_fogata() -> void:
	_actualizar()
	hud.mostrar_mensaje("¡Apagaste la fogata!",
		"Una fogata mal apagada puede quemar todo el bosque. Siempre se apaga con agua o tierra.", 6.0)


func _al_liberar_venado() -> void:
	_actualizar()
	Bitacora.descubrir("venado")
	hud.mostrar_mensaje("¡El venado está libre!",
		"El alambre y la basura en el bosque lastiman a los animales.", 5.0)


func _al_reforestar() -> void:
	_actualizar()
	arboles_nuevos.visible = true
	arboles_nuevos.modulate.a = 0.0
	create_tween().tween_property(arboles_nuevos, "modulate:a", 1.0, 1.5)
	if bosque_listo():
		hud.mostrar_mensaje("¡El bosque vuelve a crecer!",
			"Las mariposas monarca tendrán dónde pasar el invierno. Ve hacia el gran oyamel.", 6.0)


func _al_llegar_a_meta(_cuerpo: Guardian) -> void:
	if nivel_terminado:
		return
	if bosque_listo():
		nivel_terminado = true
		pantalla_final.mostrar()
		return
	var falta := []
	if not fogata.esta_apagada:
		falta.append("apagar la fogata")
	if not venado.esta_libre:
		falta.append("liberar al venado")
	if not vivero.esta_resuelta:
		falta.append("plantar árboles en el claro")
	hud.mostrar_mensaje("El bosque todavía necesita ayuda", "Te falta: " + ", ".join(falta) + ".", 5.0)

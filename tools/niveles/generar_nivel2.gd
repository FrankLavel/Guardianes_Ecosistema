extends SceneTree
## Genera res://scenes/world/Nivel2.tscn (bosque de oyamel).
##
##     godot --headless --path . -s tools/niveles/generar_nivel2.gd
##
## Diseño (tiles de 32 px): inicio abajo -> enredadera -> meseta con fogata y venado ->
## enredadera -> claro arriba con el vivero (puzzle) -> gran oyamel (meta).

const T := 32
const PASTO := Vector2i(0, 0)
const TIERRA := Vector2i(1, 0)
const PLATAFORMA := Vector2i(2, 0)
const FONDO := 22

var raiz: Node2D
var capa: TileMapLayer


func _initialize() -> void:
	raiz = Node2D.new()
	raiz.name = "Nivel2"
	raiz.set_script(load("res://scripts/world/nivel2.gd"))

	_instancia("res://scenes/world/FondoZona2.tscn", "FondoZona2", Vector2.ZERO)

	capa = TileMapLayer.new()
	capa.name = "Terreno"
	capa.tile_set = load("res://assets/tilesets/terreno.tres")
	_agregar(raiz, capa)

	_muro(-1, 0)
	_muro(103, 0)
	_suelo(0, 24, 18)          # inicio
	_suelo(25, 58, 12)         # meseta (6 tiles más arriba)
	_plataforma(42, 44, 9)     # descanso sobre el venado
	_suelo(62, 102, 6)         # claro de arriba

	var visual := Node2D.new()
	visual.name = "TerrenoVisual"
	visual.set_script(load("res://scripts/world/decorador_terreno.gd"))
	visual.set("terreno", capa)
	visual.set("textura_suelo", load("res://assets/maps/zona2/plataformas/suelo_tira.png"))
	visual.set("alto_pasto", 195)
	visual.set("textura_plataforma", load("res://assets/maps/zona2/plataformas/tronco.png"))
	visual.set("borde_plataforma", 40)
	_agregar(raiz, visual)

	# Tocones: lo que dejó la tala.
	var tocones := Node2D.new()
	tocones.name = "Tocones"
	_agregar(raiz, tocones)
	for x in [8, 15, 29, 39, 53, 66, 71, 84, 90]:
		var fila := 18 if x < 25 else (12 if x < 62 else 6)
		var s := Sprite2D.new()
		s.name = "Tocon%d" % x
		s.texture = load("res://assets/maps/valle/objetos/tocon.png")
		s.scale = Vector2(0.22, 0.22)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0 + 40)  # hundido en el pasto
		s.position = Vector2(x * T + 16, fila * T)
		s.z_index = -1
		_agregar(tocones, s)

	# Árboles que aparecen al reforestar.
	var nuevos := Node2D.new()
	nuevos.name = "ArbolesNuevos"
	nuevos.z_index = -1
	_agregar(raiz, nuevos)
	var tipos := ["oyamel", "sabino", "oyamel", "encino", "oyamel", "oyamel", "sabino"]
	for i in tipos.size():
		var s := Sprite2D.new()
		s.name = "Arbol%d" % i
		s.texture = load("res://assets/maps/valle/objetos/%s.png" % tipos[i])
		var esc := 0.5 if tipos[i] == "oyamel" else 0.38
		s.scale = Vector2(esc, esc)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0 + 8)
		s.position = Vector2((65 + i * 4) * T, 6 * T)
		_agregar(nuevos, s)

	var tierras := Node2D.new()
	tierras.name = "Tierras"
	_agregar(raiz, tierras)
	var t1 := _instancia("res://scenes/world/TierraFertil.tscn", "TierraFertil1", Vector2(22 * T + 16, 18 * T), tierras)
	t1.set("altura_enredadera", 230.0)
	var t2 := _instancia("res://scenes/world/TierraFertil.tscn", "TierraFertil2", Vector2(57 * T + 16, 12 * T), tierras)
	t2.set("altura_enredadera", 240.0)

	var controles := Node2D.new()
	controles.name = "PuntosControl"
	_agregar(raiz, controles)
	_instancia("res://scenes/world/PuntoControl.tscn", "PuntoControl1", Vector2(27 * T, 12 * T), controles)
	_instancia("res://scenes/world/PuntoControl.tscn", "PuntoControl2", Vector2(64 * T, 6 * T), controles)

	_instancia("res://scenes/world/Fogata.tscn", "Fogata", Vector2(34 * T, 12 * T))
	_instancia("res://scenes/world/VenadoAtrapado.tscn", "VenadoAtrapado", Vector2(50 * T, 12 * T))
	_instancia("res://scenes/world/Vivero.tscn", "Vivero", Vector2(78 * T, 6 * T))
	# El árbol de la meta (un gran oyamel) lo pone nivel2.gd al iniciar.
	_instancia("res://scenes/world/Meta.tscn", "Meta", Vector2(98 * T, 6 * T))

	var guardian := _instancia("res://scenes/player/Guardian.tscn", "Guardian", Vector2(3 * T + 16, 18 * T))
	guardian.z_index = 1

	var hud := _instancia("res://scenes/ui/HUD.tscn", "HUD", Vector2.ZERO)
	hud.set("titulo_salud", "Salud del bosque")
	hud.set("formato_contador", "Tareas: %d / %d")
	var final := _instancia("res://scenes/ui/NivelCompletado.tscn", "NivelCompletado", Vector2.ZERO)
	final.set("marca", "bosque_nivel")
	final.set("subtitulo", "El bosque vuelve a crecer y los animales regresan.\nMari, la mariposa, te espera en el valle.")
	final.set("aprendizaje", "• Los árboles son hogar y alimento de muchos seres vivos.\n• Cada árbol crece mejor en su lugar: el oyamel arriba, donde hace frío.\n• Una fogata mal apagada puede destruir un bosque entero.\n• Tú también eres {guardian}: no tires basura en el bosque y cuida los árboles.")
	_instancia("res://scenes/ui/MenuPausa.tscn", "MenuPausa", Vector2.ZERO)

	var escena := PackedScene.new()
	assert(escena.pack(raiz) == OK)
	assert(ResourceSaver.save(escena, "res://scenes/world/Nivel2.tscn") == OK)
	print("NIVEL2 OK")
	quit()


func _instancia(ruta: String, nombre: String, posicion: Vector2, padre: Node = null) -> Node:
	var nodo: Node = load(ruta).instantiate()
	nodo.name = nombre
	if nodo is Node2D:
		nodo.position = posicion
	_agregar(padre if padre else raiz, nodo)
	return nodo


func _agregar(padre: Node, hijo: Node) -> void:
	padre.add_child(hijo)
	hijo.owner = raiz


func _suelo(desde: int, hasta: int, fila: int) -> void:
	for x in range(desde, hasta + 1):
		capa.set_cell(Vector2i(x, fila), 0, PASTO)
		for y in range(fila + 1, FONDO):
			capa.set_cell(Vector2i(x, y), 0, TIERRA)


func _plataforma(desde: int, hasta: int, fila: int) -> void:
	for x in range(desde, hasta + 1):
		capa.set_cell(Vector2i(x, fila), 0, PLATAFORMA)


func _muro(x: int, desde_fila: int) -> void:
	for y in range(desde_fila, FONDO):
		capa.set_cell(Vector2i(x, y), 0, TIERRA)

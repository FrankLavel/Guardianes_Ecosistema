extends SceneTree
## Genera res://scenes/world/Nivel3.tscn (lago de Pátzcuaro).
##
##     godot --headless --path . -s tools/niveles/generar_nivel3.gd
##
## Diseño (tiles de 32 px): orilla de inicio -> lago (nadar: lirio, huevos, basura) ->
## orilla con el mirador (puzzle de la cadena) -> enredadera -> muelle (meta) en lo alto.

const T := 32
const PASTO := Vector2i(0, 0)
const TIERRA := Vector2i(1, 0)
const FONDO := 31
const SUPERFICIE := 18
const LAGO_DESDE := 20
const LAGO_HASTA := 61
const LECHO := 27

var raiz: Node2D
var capa: TileMapLayer


func _initialize() -> void:
	raiz = Node2D.new()
	raiz.name = "Nivel3"
	raiz.set_script(load("res://scripts/world/nivel3.gd"))

	_instancia("res://scenes/world/FondoZona3.tscn", "FondoZona3", Vector2.ZERO)

	capa = TileMapLayer.new()
	capa.name = "Terreno"
	capa.tile_set = load("res://assets/tilesets/terreno.tres")
	_agregar(raiz, capa)
	_muro(-1, 0)
	_muro(101, 0)
	_suelo(0, LAGO_DESDE - 1, SUPERFICIE)
	_suelo(LAGO_DESDE, LAGO_HASTA, LECHO)      # lecho del lago
	_suelo(LAGO_HASTA + 1, 80, SUPERFICIE)
	_suelo(81, 100, 12)                        # mirador alto con el muelle

	var visual := Node2D.new()
	visual.name = "TerrenoVisual"
	visual.set_script(load("res://scripts/world/decorador_terreno.gd"))
	visual.set("terreno", capa)
	visual.set("textura_suelo", load("res://assets/maps/zona2/plataformas/suelo_tira.png"))
	visual.set("alto_pasto", 195)
	visual.set("textura_plataforma", load("res://assets/maps/zona2/plataformas/tronco.png"))
	visual.set("borde_plataforma", 40)
	_agregar(raiz, visual)

	var lago: Node2D = _instancia("res://scenes/world/Rio.tscn", "Lago", Vector2(LAGO_DESDE * T, SUPERFICIE * T))
	lago.set("tamano", Vector2((LAGO_HASTA - LAGO_DESDE + 1) * T, (LECHO - SUPERFICIE) * T))
	lago.set("limpieza_minima_nado", 0.4)
	lago.set("frames_peces", load("res://assets/characters/animales/zona3_animales_frames.tres"))
	lago.set("animacion_peces", "pescado_blanco")
	lago.set("escala_peces", 0.09)

	# Tule en las orillas.
	var tules := Node2D.new()
	tules.name = "Tules"
	_agregar(raiz, tules)
	for x in [17, 19, 62, 64, 72]:
		var s := Sprite2D.new()
		s.name = "Tule%d" % x
		s.texture = load("res://assets/objects/zona3/tule.png")
		s.scale = Vector2(0.3, 0.3)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0 + 4)
		s.position = Vector2(x * T, SUPERFICIE * T)
		s.z_index = -1
		_agregar(tules, s)

	var lirios := Node2D.new()
	lirios.name = "Lirios"
	_agregar(raiz, lirios)
	for i in 4:
		_instancia("res://scenes/world/Lirio.tscn", "Lirio%d" % (i + 1), Vector2([25, 33, 42, 53][i] * T, SUPERFICIE * T + 6), lirios)

	var huevos := Node2D.new()
	huevos.name = "Huevos"
	_agregar(raiz, huevos)
	var lugares := [Vector2(29, 25.6), Vector2(40, 26.2), Vector2(57, 25.4)]
	for i in lugares.size():
		_instancia("res://scenes/world/HuevoAchoque.tscn", "Huevo%d" % (i + 1), lugares[i] * T, huevos)

	var basura := Node2D.new()
	basura.name = "BasuraLago"
	_agregar(raiz, basura)
	for datos in [["botella", 37], ["bolsa", 47], ["lata", 58]]:
		var b: Node = _instancia("res://scenes/world/Basura.tscn", "Basura_%s" % datos[0], Vector2(datos[1] * T, SUPERFICIE * T + 14), basura)
		b.set("tipo", datos[0])

	var controles := Node2D.new()
	controles.name = "PuntosControl"
	_agregar(raiz, controles)
	_instancia("res://scenes/world/PuntoControl.tscn", "PuntoControl1", Vector2(64 * T, SUPERFICIE * T), controles)

	var mirador: Node = _instancia("res://scenes/world/Mirador.tscn", "Mirador", Vector2(70 * T, SUPERFICIE * T))

	var tierras := Node2D.new()
	tierras.name = "Tierras"
	_agregar(raiz, tierras)
	var t: Node = _instancia("res://scenes/world/TierraFertil.tscn", "TierraFertil1", Vector2(79 * T + 16, SUPERFICIE * T), tierras)
	t.set("altura_enredadera", 230.0)

	_instancia("res://scenes/world/Meta.tscn", "Meta", Vector2(96 * T, 12 * T))
	var guardian: Node = _instancia("res://scenes/player/Guardian.tscn", "Guardian", Vector2(4 * T + 16, SUPERFICIE * T))
	guardian.z_index = 1

	var hud: Node = _instancia("res://scenes/ui/HUD.tscn", "HUD", Vector2.ZERO)
	hud.set("titulo_salud", "Salud del lago")
	hud.set("formato_contador", "Tareas: %d / %d")
	var final: Node = _instancia("res://scenes/ui/NivelCompletado.tscn", "NivelCompletado", Vector2.ZERO)
	final.set("marca", "lago_nivel")
	final.set("subtitulo", "El agua del lago se aclara y los huevos de achoque están a salvo.\nAchi te espera en el valle.")
	final.set("aprendizaje", "• En un ecosistema todo está conectado: si falta un eslabón de la cadena alimenticia, todos lo sienten.\n• Las plantas invasoras como el lirio tapan la luz y dañan el lago.\n• El achoque solo vive aquí: si desaparece de Pátzcuaro, desaparece del mundo.\n• Tú también eres {guardian}: separa la basura para que no llegue al agua.")
	_instancia("res://scenes/ui/MenuPausa.tscn", "MenuPausa", Vector2.ZERO)

	var escena := PackedScene.new()
	assert(escena.pack(raiz) == OK)
	assert(ResourceSaver.save(escena, "res://scenes/world/Nivel3.tscn") == OK)
	print("NIVEL3 OK")
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


func _muro(x: int, desde_fila: int) -> void:
	for y in range(desde_fila, FONDO):
		capa.set_cell(Vector2i(x, y), 0, TIERRA)

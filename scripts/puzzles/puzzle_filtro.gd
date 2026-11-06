class_name PuzzleFiltro
extends PuzzleBase
## Puzzle 2 (Zona 1): armar un filtro de agua poniendo las capas en orden, de abajo hacia arriba.
## Si se elige una capa equivocada, se explica para qué sirve la que va en ese lugar.

## Orden correcto, empezando por abajo (junto a la boquilla por donde sale el agua).
const ORDEN := ["algodon", "carbon", "arena", "grava"]
const NOMBRES := {"algodon": "Algodón", "carbon": "Carbón", "arena": "Arena", "grava": "Grava"}
const PISTAS := {
	"algodon": "Hasta abajo va algo suave que deje pasar el agua\npero detenga todo lo demás para que no se salga.",
	"carbon": "Ahora va el carbón: atrapa lo que hace que el agua\nhuela y sepa feo.",
	"arena": "Sigue la arena: sus granitos detienen la tierra\nmás fina que trae el agua.",
	"grava": "Hasta arriba van las piedritas: detienen las hojas,\nlas ramas y la basura grande.",
}
const TEXTURAS := "res://assets/ui/puzzle_filtro/textura_%s.png"
const ALTO_CAPA := 92.0

var capas: Array[String] = []

@onready var _columna: VBoxContainer = %Capas
@onready var _gota_sucia: TextureRect = %GotaSucia
@onready var _gota_limpia: TextureRect = %GotaLimpia
@onready var _cartas := {"algodon": %CartaAlgodon, "carbon": %CartaCarbon, "arena": %CartaArena, "grava": %CartaGrava}


func _ready() -> void:
	super()
	for material in _cartas:
		var carta: TextureButton = _cartas[material]
		carta.pressed.connect(poner.bind(material))
		carta.focus_entered.connect(func(): carta.scale = Vector2(1.08, 1.08))
		carta.focus_exited.connect(func(): carta.scale = Vector2.ONE)
	reiniciar()


func _al_abrir() -> void:
	decir("Ayuda a Don Chucho a armar un filtro para limpiar el agua.\nElige las capas en orden, empezando por ABAJO.")
	_cartas["grava"].grab_focus()


func reiniciar() -> void:
	capas.clear()
	for hijo in _columna.get_children():
		hijo.queue_free()
	_gota_limpia.visible = false
	_gota_sucia.position.y = 0.0
	for material in _cartas:
		_cartas[material].disabled = false
		_cartas[material].modulate = Color.WHITE


func siguiente() -> String:
	return ORDEN[capas.size()] if capas.size() < ORDEN.size() else ""


func poner(material: String) -> void:
	if esta_resuelto or material in capas:
		return
	var esperado := siguiente()
	if material != esperado:
		_sacudir(_cartas[material])
		fallar("%s no va ahí. %s" % [NOMBRES[material], PISTAS[esperado]])
		return
	capas.append(material)
	Sonido.efecto("recoger")
	_cartas[material].disabled = true
	_cartas[material].modulate = Color(1, 1, 1, 0.35)
	_agregar_capa(material)
	if capas.size() == ORDEN.size():
		await _filtrar()
		decir("¡El agua sale limpia! Las capas detienen la suciedad poco a poco.\nAsí funcionan también las plantas que limpian el agua de las ciudades.", Color(0.8, 1, 0.7))
		resolver()
	else:
		decir("¡Bien! %s va en su lugar. ¿Qué capa sigue?" % NOMBRES[material], Color(0.85, 1, 0.75))
		for m in _cartas:
			if not _cartas[m].disabled:
				_cartas[m].grab_focus()
				break


func _agregar_capa(material: String) -> void:
	var capa := TextureRect.new()
	capa.texture = load(TEXTURAS % material)
	capa.stretch_mode = TextureRect.STRETCH_TILE
	capa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	capa.custom_minimum_size = Vector2(0, ALTO_CAPA)
	capa.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	capa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# La columna se llena de abajo hacia arriba: cada capa nueva va al principio.
	_columna.add_child(capa)
	_columna.move_child(capa, 0)
	capa.modulate.a = 0.0
	create_tween().tween_property(capa, "modulate:a", 1.0, 0.25)


## La gota sucia atraviesa las capas y sale limpia por abajo.
func _filtrar() -> void:
	var caida := create_tween()
	caida.tween_property(_gota_sucia, "position:y", 520.0, 1.4).set_trans(Tween.TRANS_SINE)
	caida.parallel().tween_property(_gota_sucia, "modulate:a", 0.0, 1.4)
	await caida.finished
	_gota_limpia.visible = true
	_gota_limpia.scale = Vector2(0.2, 0.2)
	await create_tween().tween_property(_gota_limpia, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).finished


func _sacudir(nodo: Control) -> void:
	var x := nodo.position.x
	var sacudida := create_tween()
	for d in [-12.0, 12.0, -8.0, 8.0, 0.0]:
		sacudida.tween_property(nodo, "position:x", x + d, 0.05)

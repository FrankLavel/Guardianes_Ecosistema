class_name PuzzleCadena
extends PuzzleBase
## Puzzle 5 (Zona 3): reconstruir la cadena alimenticia del lago, de quién da la energía a
## quién se come a quién: Sol → plantas acuáticas → insectos → achoque → garza.

const ORDEN := ["sol", "plantas", "insectos", "achoque", "garza"]
const DATOS := {
	"sol": {"nombre": "Sol", "imagen": "res://assets/objects/zona3/sol.png",
		"pista": "Todo empieza con el Sol: sin su luz, nada puede crecer."},
	"plantas": {"nombre": "Plantas del lago", "imagen": "res://assets/objects/zona3/plantas.png",
		"pista": "Las plantas usan la luz del Sol para crecer. Son la comida de los animales pequeños."},
	"insectos": {"nombre": "Insectos del agua", "imagen": "res://assets/objects/zona3/insecto.png",
		"pista": "Los insectos y animalitos del agua comen plantas."},
	"achoque": {"nombre": "Achoque", "imagen": "res://assets/objects/zona3/achoque.png",
		"pista": "El achoque come insectos y animalitos del agua."},
	"garza": {"nombre": "Garza", "imagen": "res://assets/ui/bitacora/garza.png",
		"pista": "La garza come peces y achoques: va al final de esta cadena."},
}
## Las tarjetas se muestran en este orden (mezcladas, siempre igual para poder explicarlo).
const ORDEN_TARJETAS := ["achoque", "sol", "garza", "insectos", "plantas"]

var cadena: Array[String] = []

var _tarjetas: Dictionary = {}
var _casillas: Array[TextureRect] = []

@onready var escenario: Control = %Escenario
@onready var _fila_tarjetas: HBoxContainer = %Tarjetas


func _ready() -> void:
	super()
	_construir()


func _al_abrir() -> void:
	decir("Si falta un eslabón, la cadena se rompe. ¡Arma la cadena alimenticia del lago!\nEmpieza por quien da la energía a todos.")
	_fila_tarjetas.get_child(0).grab_focus()


func _construir() -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 6)
	fila.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	escenario.add_child(fila)
	for i in ORDEN.size():
		var casilla := TextureRect.new()
		casilla.custom_minimum_size = Vector2(130, 130)
		casilla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		casilla.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var marco := Panel.new()
		marco.set_anchors_preset(Control.PRESET_FULL_RECT)
		marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(1, 1, 1, 0.12)
		estilo.border_color = Color(1, 1, 1, 0.55)
		estilo.set_border_width_all(3)
		estilo.set_corner_radius_all(16)
		marco.add_theme_stylebox_override("panel", estilo)
		casilla.add_child(marco)
		fila.add_child(casilla)
		_casillas.append(casilla)
		if i < ORDEN.size() - 1:
			var flecha := Label.new()
			flecha.text = "→"
			flecha.add_theme_font_size_override("font_size", 40)
			fila.add_child(flecha)
	fila.position -= fila.get_combined_minimum_size() / 2.0
	for id in ORDEN_TARJETAS:
		var tarjeta := Button.new()
		tarjeta.custom_minimum_size = Vector2(185, 190)
		tarjeta.text = DATOS[id]["nombre"]
		tarjeta.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tarjeta.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tarjeta.expand_icon = true
		tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD
		tarjeta.add_theme_font_size_override("font_size", 21)
		tarjeta.icon = load(DATOS[id]["imagen"])
		tarjeta.pressed.connect(poner.bind(id))
		_fila_tarjetas.add_child(tarjeta)
		_tarjetas[id] = tarjeta


func siguiente() -> String:
	return ORDEN[cadena.size()] if cadena.size() < ORDEN.size() else ""


## Pone el siguiente eslabón. Devuelve true si era el correcto.
func poner(id: String) -> bool:
	if esta_resuelto or id in cadena:
		return false
	var esperado := siguiente()
	if id != esperado:
		if cadena.is_empty():
			fallar("%s no va primero. %s" % [DATOS[id]["nombre"], DATOS[esperado]["pista"]])
		else:
			fallar("%s no come %s. %s" % [DATOS[id]["nombre"], DATOS[cadena[-1]]["nombre"].to_lower(), DATOS[esperado]["pista"]])
		return false
	_casillas[cadena.size()].texture = _tarjetas[id].icon
	cadena.append(id)
	_tarjetas[id].disabled = true
	_tarjetas[id].modulate = Color(1, 1, 1, 0.35)
	Sonido.efecto("recoger")
	if cadena.size() == ORDEN.size():
		decir("¡Cadena completa! Si el lirio tapa la luz y mueren las plantas,\ntodos los demás se quedan sin comida. Todo en el lago está conectado.", Color(0.8, 1, 0.7))
		Bitacora.descubrir("tule")
		resolver()
	else:
		decir("¡Bien! %s. ¿Quién sigue?" % DATOS[id]["pista"], Color(0.85, 1, 0.75))
		for otro in ORDEN_TARJETAS:
			if not _tarjetas[otro].disabled:
				_tarjetas[otro].grab_focus()
				break
	return true

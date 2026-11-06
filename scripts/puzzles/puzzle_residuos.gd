class_name PuzzleResiduos
extends PuzzleBase
## Puzzle 6 (Zona 3): separar la basura que se sacó del lago en su contenedor.

const CONTENEDORES := {
	"organico": {"nombre": "Orgánicos", "color": Color(0.36, 0.62, 0.28)},
	"plastico": {"nombre": "Plásticos", "color": Color(0.9, 0.72, 0.18)},
	"papel": {"nombre": "Papel y cartón", "color": Color(0.26, 0.5, 0.82)},
	"vidrio_metal": {"nombre": "Vidrio y metal", "color": Color(0.55, 0.58, 0.6)},
	"peligrosos": {"nombre": "Peligrosos", "color": Color(0.82, 0.25, 0.22)},
}
## Basura en el orden en que aparece: [id, nombre, imagen, contenedor, explicación].
const BASURA := [
	["cascara", "Cáscara de plátano", "res://assets/objects/zona3/cascara.png", "organico",
		"Es un resto de comida: se puede convertir en abono para las plantas."],
	["botella", "Botella de plástico", "res://assets/objects/basura/botella.png", "plastico",
		"El plástico se recicla para hacer cosas nuevas, en lugar de quedarse cientos de años en el agua."],
	["papel", "Hoja de papel", "res://assets/objects/zona3/papel.png", "papel",
		"El papel se recicla para hacer cuadernos y cajas nuevas."],
	["lata", "Lata", "res://assets/objects/basura/lata.png", "vidrio_metal",
		"Las latas son de metal y se pueden reciclar muchas veces."],
	["frasco", "Frasco de vidrio", "res://assets/objects/zona3/frasco.png", "vidrio_metal",
		"El vidrio se puede reciclar una y otra vez sin perder calidad."],
	["pila", "Pila", "res://assets/objects/basura/pila.png", "peligrosos",
		"¡Cuidado! Las pilas tienen sustancias tóxicas: van en un contenedor especial, nunca al agua."],
	["bolsa", "Bolsa de plástico", "res://assets/objects/basura/bolsa.png", "plastico",
		"Las bolsas también son plástico. Mejor usa una bolsa de tela que dure mucho."],
]

var indice := 0

var _imagen: TextureRect
var _nombre: Label
var _contador: Label
var _botones: Dictionary = {}

@onready var escenario: Control = %Escenario
@onready var _fila: HBoxContainer = %Tarjetas


func _ready() -> void:
	super()
	_construir()
	_mostrar_actual()


func _al_abrir() -> void:
	decir("Sacamos esta basura del lago. ¿En qué contenedor va cada cosa?")
	_botones["organico"].grab_focus()


func _construir() -> void:
	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	escenario.add_child(caja)
	_contador = Label.new()
	_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_contador.add_theme_font_size_override("font_size", 26)
	caja.add_child(_contador)
	_imagen = TextureRect.new()
	_imagen.custom_minimum_size = Vector2(0, 260)
	_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	caja.add_child(_imagen)
	_nombre = Label.new()
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre.add_theme_font_size_override("font_size", 38)
	caja.add_child(_nombre)
	for id in CONTENEDORES:
		var datos: Dictionary = CONTENEDORES[id]
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(170, 220)
		boton.text = datos["nombre"]
		boton.icon = load("res://assets/objects/zona3/contenedor_%s.png" % id)
		boton.expand_icon = true
		boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.add_theme_font_size_override("font_size", 24)
		for estilo in ["normal", "hover", "pressed", "focus"]:
			var caja_estilo := StyleBoxFlat.new()
			caja_estilo.bg_color = datos["color"].lightened(0.15 if estilo != "normal" else 0.0)
			caja_estilo.border_color = Color(0.99, 0.86, 0.45) if estilo in ["hover", "focus"] else datos["color"].darkened(0.4)
			caja_estilo.set_border_width_all(6 if estilo in ["hover", "focus"] else 4)
			caja_estilo.corner_radius_top_left = 10
			caja_estilo.corner_radius_top_right = 10
			caja_estilo.corner_radius_bottom_left = 24
			caja_estilo.corner_radius_bottom_right = 24
			caja_estilo.set_content_margin_all(10)
			boton.add_theme_stylebox_override(estilo, caja_estilo)
		boton.pressed.connect(clasificar.bind(id))
		_fila.add_child(boton)
		_botones[id] = boton


func item_actual() -> Array:
	return BASURA[indice] if indice < BASURA.size() else []


func _mostrar_actual() -> void:
	var item := item_actual()
	if item.is_empty():
		_imagen.texture = null
		_nombre.text = "¡Todo separado!"
		_contador.text = ""
		return
	_imagen.texture = load(item[2])
	_nombre.text = item[1]
	_contador.text = "Basura %d de %d" % [indice + 1, BASURA.size()]
	_imagen.pivot_offset = _imagen.size / 2.0
	_imagen.scale = Vector2(0.6, 0.6)
	create_tween().tween_property(_imagen, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


## Mete la basura actual en `contenedor`. Devuelve true si era el correcto.
func clasificar(contenedor: String) -> bool:
	var item := item_actual()
	if esta_resuelto or item.is_empty():
		return false
	if item[3] != contenedor:
		fallar("%s no va en %s. Piénsalo: ¿de qué está hecho?" % [item[1], CONTENEDORES[contenedor]["nombre"].to_lower()])
		return false
	Sonido.efecto("recoger")
	decir("¡Bien! %s" % item[4], Color(0.85, 1, 0.75))
	indice += 1
	_mostrar_actual()
	if indice >= BASURA.size():
		decir("¡Todo separado! Si separamos la basura, se puede reciclar\ny no termina en el lago. ¡Así se cuida el agua!", Color(0.8, 1, 0.7))
		Bitacora.descubrir("pato_mexicano")
		resolver()
	return true

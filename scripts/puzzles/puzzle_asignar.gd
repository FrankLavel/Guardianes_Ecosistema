class_name PuzzleAsignar
extends PuzzleBase
## Puzzle de "poner cada cosa en su lugar": se elige una tarjeta (abajo) y luego el lugar
## (en el escenario). Si el lugar es incorrecto, se explica por qué con la pista de la tarjeta.
## Lo usan "Reforestar" (cada árbol a su altura) y "¿Quién vive aquí?" (cada animal a su hábitat).

## id -> {nombre, imagen (ruta o ""), destino, pista}
## Tamaño para el que se escribieron las posiciones; se escalan al tamaño real del escenario.
const TAMANO_DISENO := Vector2(860, 520)

var opciones: Dictionary = {}
## id -> {nombre, posicion (centro dentro de %Escenario, en un escenario de TAMANO_DISENO)}
var destinos: Dictionary = {}
var texto_inicio := ""
var texto_final := ""
## Especies que se registran en la bitácora al resolver.
var especies_al_resolver: Array[String] = []

var elegida := ""
## destino -> opción colocada
var colocadas: Dictionary = {}

var _tarjetas: Dictionary = {}
var _botones_destino: Dictionary = {}

@onready var escenario: Control = %Escenario
@onready var _fila_tarjetas: HBoxContainer = %Tarjetas


func _ready() -> void:
	_configurar()
	super()
	_construir()


## Cada puzzle llena opciones, destinos y textos.
func _configurar() -> void:
	pass


func _al_abrir() -> void:
	decir(texto_inicio)
	if _fila_tarjetas.get_child_count() > 0:
		_fila_tarjetas.get_child(0).grab_focus()


func _construir() -> void:
	for id in destinos:
		var datos: Dictionary = destinos[id]
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(160, 140)
		boton.size = boton.custom_minimum_size
		var escala := escenario.custom_minimum_size / TAMANO_DISENO
		boton.position = (datos["posicion"] as Vector2) * escala - boton.size / 2.0
		boton.text = datos["nombre"]
		boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.expand_icon = true
		boton.add_theme_font_size_override("font_size", 20)
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for estilo in ["normal", "hover", "pressed", "focus", "disabled"]:
			boton.add_theme_stylebox_override(estilo, _estilo_destino(estilo in ["hover", "focus"]))
		boton.pressed.connect(colocar_en.bind(id))
		escenario.add_child(boton)
		_botones_destino[id] = boton
	for id in opciones:
		var datos: Dictionary = opciones[id]
		var tarjeta := Button.new()
		tarjeta.custom_minimum_size = Vector2(190, 210)
		tarjeta.autowrap_mode = TextServer.AUTOWRAP_WORD
		tarjeta.add_theme_font_size_override("font_size", 26)
		tarjeta.toggle_mode = true
		tarjeta.text = datos["nombre"]
		tarjeta.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tarjeta.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tarjeta.expand_icon = true
		var ruta: String = datos.get("imagen", "")
		if ruta != "" and ResourceLoader.exists(ruta):
			tarjeta.icon = load(ruta)
		tarjeta.pressed.connect(elegir.bind(id))
		_fila_tarjetas.add_child(tarjeta)
		_tarjetas[id] = tarjeta


func _estilo_destino(resaltado: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.28 if resaltado else 0.14)
	estilo.border_color = Color(0.99, 0.86, 0.45) if resaltado else Color(1, 1, 1, 0.6)
	estilo.set_border_width_all(5 if resaltado else 3)
	estilo.set_corner_radius_all(20)
	estilo.set_content_margin_all(8)
	return estilo


func elegir(id: String) -> void:
	if esta_resuelto or id in colocadas.values():
		return
	elegida = id
	for otro in _tarjetas:
		_tarjetas[otro].button_pressed = otro == id
	Sonido.efecto("boton")
	decir("Elegiste: %s. Ahora elige su lugar." % opciones[id]["nombre"])
	# Con teclado o control, el foco salta a los lugares.
	for destino in _botones_destino:
		if not colocadas.has(destino):
			_botones_destino[destino].grab_focus()
			break


func colocar_en(destino: String) -> void:
	if esta_resuelto or colocadas.has(destino):
		return
	if elegida == "":
		decir("Primero elige una tarjeta de abajo.")
		return
	asignar(elegida, destino)


## Coloca `opcion` en `destino`. Devuelve true si era su lugar.
func asignar(opcion: String, destino: String) -> bool:
	if opciones[opcion]["destino"] != destino:
		fallar("%s no va ahí. %s" % [opciones[opcion]["nombre"], opciones[opcion]["pista"]])
		_tarjetas[opcion].button_pressed = false
		elegida = ""
		return false
	colocadas[destino] = opcion
	elegida = ""
	var tarjeta: Button = _tarjetas[opcion]
	tarjeta.button_pressed = false
	tarjeta.disabled = true
	tarjeta.modulate = Color(1, 1, 1, 0.35)
	var boton: Button = _botones_destino[destino]
	boton.icon = tarjeta.icon
	boton.text = opciones[opcion]["nombre"]
	boton.disabled = true
	Sonido.efecto("recoger")
	if colocadas.size() == opciones.size():
		decir(texto_final, Color(0.8, 1, 0.7))
		for especie in especies_al_resolver:
			Bitacora.descubrir(especie)
		resolver()
	else:
		decir("¡Bien! %s va en su lugar. ¿Qué sigue?" % opciones[opcion]["nombre"], Color(0.85, 1, 0.75))
		for otro in _tarjetas:
			if not _tarjetas[otro].disabled:
				_tarjetas[otro].grab_focus()
				break
	return true

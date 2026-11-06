extends Control
## Al empezar una partida nueva: elegir niño o niña y escribir el nombre.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_MENU := "res://scenes/menu/menu_principal.tscn"

var genero := "nino"

@onready var _boton_nino: Button = %BtnNino
@onready var _boton_nina: Button = %BtnNina
@onready var _nombre: LineEdit = %Nombre
@onready var _comenzar: Button = %BtnComenzar


func _ready() -> void:
	var grupo := ButtonGroup.new()
	for datos in [[_boton_nino, "nino"], [_boton_nina, "nina"]]:
		var boton: Button = datos[0]
		boton.button_group = grupo
		boton.icon = _imagen_de(datos[1])
		boton.pressed.connect(elegir.bind(datos[1]))
	_comenzar.pressed.connect(comenzar)
	%BtnVolver.pressed.connect(func(): Transicion.ir_a(ESCENA_MENU))
	_nombre.text_submitted.connect(func(_t): comenzar())
	elegir("nino")
	_boton_nino.grab_focus()


func _imagen_de(clave: String) -> Texture2D:
	var cuadros: SpriteFrames = load(Juego.PERSONAJES[clave]["aereo"])
	return cuadros.get_frame_texture(&"idle_abajo", 0)


func elegir(clave: String) -> void:
	genero = clave
	(_boton_nino if clave == "nino" else _boton_nina).button_pressed = true
	# Si el nombre era la sugerencia del otro personaje, se cambia por la de este.
	var sugerencias: Array = Juego.PERSONAJES.values().map(func(p): return p["nombre_sugerido"])
	if _nombre.text.is_empty() or _nombre.text in sugerencias:
		_nombre.text = Juego.PERSONAJES[clave]["nombre_sugerido"]


func comenzar() -> void:
	Juego.nueva_partida(1, genero, _nombre.text)
	Juego.guardar()
	Transicion.ir_a(ESCENA_VALLE)

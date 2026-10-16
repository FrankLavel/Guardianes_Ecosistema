extends CanvasLayer
## Cuadro de diálogo (autoload "Dialogo"). Los textos están en data/dialogos.json.
##
##     await Dialogo.mostrar("don_chucho_inicio")
##
## Mientras está abierto, Juego.entrada_bloqueada = true para que nadie se mueva.

signal linea_mostrada(indice: int)
signal terminado(id: String)

const RUTA := "res://data/dialogos.json"
## Letras por segundo del efecto de máquina de escribir.
const VELOCIDAD_TEXTO := 45.0

var activo := false
var id_actual := ""

var _datos: Dictionary = {}
var _lineas: Array = []
var _indice := 0
var _escribiendo: Tween

@onready var _caja: Control = %Caja
@onready var _retrato: TextureRect = %Retrato
@onready var _marco_retrato: Control = %MarcoRetrato
@onready var _nombre: Label = %Nombre
@onready var _texto: Label = %Texto
@onready var _continuar: Label = %Continuar


func _ready() -> void:
	_caja.visible = false
	_datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA))


func existe(id: String) -> bool:
	return _datos.get("dialogos", {}).has(id)


func lineas_de(id: String) -> Array:
	return _datos.get("dialogos", {}).get(id, [])


func mostrar(id: String) -> void:
	if activo or not existe(id):
		if not existe(id):
			push_error("No existe el diálogo: %s" % id)
		return
	activo = true
	id_actual = id
	Juego.entrada_bloqueada = true
	_lineas = lineas_de(id)
	_indice = 0
	_caja.visible = true
	_caja.modulate.a = 0.0
	create_tween().tween_property(_caja, "modulate:a", 1.0, 0.15)
	_mostrar_linea()
	await terminado


func avanzar() -> void:
	if not activo:
		return
	if _escribiendo and _escribiendo.is_running():
		_escribiendo.kill()
		_texto.visible_ratio = 1.0
		_continuar.visible = true
		return
	_indice += 1
	if _indice >= _lineas.size():
		_cerrar()
	else:
		_mostrar_linea()


func _unhandled_input(evento: InputEvent) -> void:
	if activo and (evento.is_action_pressed("interactuar") or evento.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		avanzar()


func _mostrar_linea() -> void:
	var linea: Dictionary = _lineas[_indice]
	var personaje: Dictionary = _datos.get("personajes", {}).get(linea.get("quien", ""), {})
	_nombre.text = personaje.get("nombre", "")
	var ruta_retrato: String = personaje.get("retrato", "")
	_marco_retrato.visible = not ruta_retrato.is_empty()
	_retrato.texture = load(ruta_retrato) if not ruta_retrato.is_empty() else null
	_texto.text = linea.get("texto", "")
	_texto.visible_ratio = 0.0
	_continuar.visible = false
	_escribiendo = create_tween()
	_escribiendo.tween_property(_texto, "visible_ratio", 1.0, _texto.text.length() / VELOCIDAD_TEXTO)
	_escribiendo.tween_callback(func(): _continuar.visible = true)
	linea_mostrada.emit(_indice)


func _cerrar() -> void:
	activo = false
	_caja.visible = false
	Juego.marcar_dialogo_visto(id_actual)
	# Un cuadro de espera evita que la misma tecla que cerró el diálogo lo vuelva a abrir.
	await get_tree().process_frame
	Juego.entrada_bloqueada = false
	terminado.emit(id_actual)

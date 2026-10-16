class_name EntradaZona
extends ZonaInteraccion
## Arco de entrada a una zona. Si la zona está bloqueada, Gara explica por qué.

@export_enum("rio", "bosque", "lago") var zona := "rio"
@export var nombre_zona := "Río Cupatitzio"
@export_file("*.tscn") var escena := ""
## Dónde reaparece Gara al volver de la zona (relativo a la entrada).
@export var salida := Vector2(0, 90)
@export var textura: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _estado: Label = $Estado


func _ready() -> void:
	texto_aviso = "E  " + nombre_zona
	if textura:
		_sprite.texture = textura
		_sprite.offset.y = -textura.get_height() / 2.0
	super()
	actualizar_estado()


func actualizar_estado() -> void:
	if Juego.zona_esta_completa(zona):
		_sprite.modulate = Color.WHITE
		_estado.text = "¡Restaurado!"
		_estado.modulate = Color(0.75, 1, 0.6)
	elif Juego.zona_desbloqueada(zona):
		_sprite.modulate = Color.WHITE
		_estado.text = ""
	else:
		_sprite.modulate = Color(0.45, 0.45, 0.5)
		_estado.text = "Bloqueado"
		_estado.modulate = Color(1, 0.8, 0.7)


func _al_interactuar(jugador: Node2D) -> void:
	if not Juego.zona_desbloqueada(zona):
		Dialogo.mostrar("entrada_bloqueada_" + zona)
		return
	if escena.is_empty():
		return
	Juego.posicion_valle = global_position + salida
	Juego.tiene_posicion_valle = true
	Juego.guardar()
	if jugador is GaraAerea:
		jugador.leer_entrada_del_jugador = false
		jugador.entrada_direccion = Vector2.ZERO
	Transicion.ir_a(escena)

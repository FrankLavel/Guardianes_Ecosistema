class_name ZonaInteraccion
extends Area2D
## Algo con lo que Gara puede interactuar en el valle presionando E.
## Muestra el aviso (nodo hijo "Aviso") cuando Gara está cerca.

signal activada(jugador: Node2D)

@export var texto_aviso := "E"

var _aviso: Label


func _ready() -> void:
	_aviso = get_node_or_null("Aviso")
	if _aviso:
		_aviso.text = texto_aviso
		_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func interactuar(jugador: Node2D) -> void:
	activada.emit(jugador)
	_al_interactuar(jugador)


## El guardián solo muestra el aviso del objeto más cercano (el que activa la E).
func mostrar_aviso(si: bool) -> void:
	if _aviso:
		_aviso.visible = si


## Para sobrescribir en cada tipo de objeto.
func _al_interactuar(_jugador: Node2D) -> void:
	pass


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("registrar_interactuable"):
		cuerpo.registrar_interactuable(self)
		if _aviso:
			_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo.has_method("quitar_interactuable"):
		cuerpo.quitar_interactuable(self)
		if _aviso:
			_aviso.visible = false

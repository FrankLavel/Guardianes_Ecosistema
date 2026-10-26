class_name Parcela
extends ZonaInteraccion
## Un surco de la milpa: sembrar, regar una vez al día y cosechar (ver Granja).

signal aviso(texto: String)

const TIERRA := preload("res://assets/objects/zona2/tierra_fertil.png")

@export var indice := 0

var _tierra: Sprite2D
var _planta: Sprite2D


func _ready() -> void:
	_tierra = Sprite2D.new()
	_tierra.texture = TIERRA
	_tierra.scale = Vector2.ONE * 90.0 / TIERRA.get_width()
	_tierra.offset = Vector2(0, -TIERRA.get_height() / 2.0 + 30)
	add_child(_tierra)
	_planta = Sprite2D.new()
	_planta.scale = Vector2(0.55, 0.55)
	add_child(_planta)
	super()
	actualizar()


func actualizar() -> void:
	var p := Granja.parcela(indice)
	_planta.texture = Granja.textura_planta(indice)
	if _planta.texture:
		_planta.offset = Vector2(0, -_planta.texture.get_height() / 2.0)
	# Tierra mojada: más oscura.
	_tierra.modulate = Color(0.7, 0.7, 0.8) if p["regada"] else Color.WHITE
	var texto := "E  Sembrar"
	if not p["cultivo"].is_empty():
		texto = "E  Cosechar" if int(p["etapa"]) >= Granja.LISTO else ("E  Regar" if not p["regada"] else "Regada")
	_aviso.text = texto


func _al_interactuar(_jugador: Node2D) -> void:
	var p := Granja.parcela(indice)
	if p["cultivo"].is_empty():
		Granja.abrir_semillas(indice, actualizar)
	elif int(p["etapa"]) >= Granja.LISTO:
		var cosecha := Granja.cosechar(indice)
		var partes := []
		for id in cosecha:
			partes.append("%d %s" % [int(cosecha[id]), Granja.nombre(id).to_lower()])
		aviso.emit("¡Cosechaste %s!" % ", ".join(partes))
	elif Granja.regar(indice):
		aviso.emit("La regaste. Mañana crecerá un poco más.")
	else:
		aviso.emit("Ya la regaste hoy. Mañana crecerá.")
	actualizar()

class_name Parcela
extends ZonaInteraccion
## Un surco de la milpa: sembrar, regar una vez al día y cosechar (ver Granja).

signal aviso(texto: String)

const TIERRA := preload("res://assets/objects/zona2/tierra_fertil.png")

@export var indice := 0

var _tierra: Sprite2D
var _planta: Sprite2D


## Todas las plantas se escalan igual: el montón de tierra de cada imagen mide lo mismo.
const ESCALA_PLANTA := 0.38


func _ready() -> void:
	_tierra = Sprite2D.new()
	_tierra.texture = TIERRA
	_tierra.scale = Vector2.ONE * 80.0 / TIERRA.get_width()
	_tierra.offset = Vector2(0, -TIERRA.get_height() / 2.0 + 30)
	add_child(_tierra)
	_planta = Sprite2D.new()
	_planta.scale = Vector2.ONE * ESCALA_PLANTA
	add_child(_planta)
	super()
	actualizar()
	Granja.parcelas_cambio.connect(actualizar)


var _reloj := 0.0


## El aviso dice cuánto falta mientras crece.
func _process(delta: float) -> void:
	_reloj += delta
	if _reloj >= 1.0:
		_reloj = 0.0
		actualizar()


func actualizar() -> void:
	var p := Granja.parcela(indice)
	_planta.texture = Granja.textura_planta(indice)
	# La imagen de la planta ya trae su montón de tierra.
	_tierra.visible = _planta.texture == null
	if _planta.texture:
		_planta.offset = Vector2(0, -_planta.texture.get_height() / 2.0 + 10.0 / ESCALA_PLANTA)
	# Regada: la tierra (y la planta) se ve más oscura, como mojada.
	var mojada := Color(0.78, 0.78, 0.88)
	_tierra.modulate = mojada if p["regada"] else Color.WHITE
	_planta.modulate = mojada if p["regada"] else Color.WHITE
	var texto := "E  Sembrar"
	if not p["cultivo"].is_empty():
		if int(p["etapa"]) >= Granja.LISTO:
			texto = "E  Cosechar"
		elif not p["regada"]:
			texto = "E  Regar"
		else:
			texto = "Creciendo · %d min" % Granja.minutos_restantes(indice)
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
		aviso.emit("¡La regaste! Estará lista en unos %d minutos." % Granja.minutos_restantes(indice))
	else:
		aviso.emit("Está creciendo. Faltan unos %d minutos." % Granja.minutos_restantes(indice))
	actualizar()

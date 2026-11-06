class_name ObjetoAyuda
extends ZonaInteraccion
## Algo que aparece en el valle por un pedido de ayuda: basura para recoger o tierra suelta
## para plantar un arbolito.

signal usado(objeto: ObjetoAyuda)

const BASURA := ["botella", "lata", "bolsa", "pila", "unicel"]
const TIERRA := preload("res://assets/objects/zona2/tierra_fertil.png")
const ARBOLITO := preload("res://assets/objects/zona1/brote_control.png")
const FLORES := preload("res://assets/maps/valle/objetos/arbusto_flores.png")

## "basura" o "tierra".
@export var tipo := "basura"
## Lo que crece en la tierra: "arbolito" o "flores".
@export var planta := "arbolito"

var hecho := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if tipo == "basura":
		texto_aviso = "E  Recoger"
		_poner(load("res://assets/objects/basura/%s.png" % BASURA.pick_random()), 46.0)
		_sprite.rotation = randf_range(-0.5, 0.5)
	else:
		texto_aviso = "E  Plantar flores" if planta == "flores" else "E  Plantar"
		_poner(TIERRA, 70.0)
	super()


## Escala la imagen a `lado` px (raíz del área) y la apoya en el suelo.
func _poner(textura: Texture2D, lado: float) -> void:
	_sprite.texture = textura
	_sprite.scale = Vector2.ONE * lado / sqrt(textura.get_width() * textura.get_height())
	_sprite.offset = Vector2(0, -textura.get_height() / 2.0 + 6.0 / _sprite.scale.y)


func _al_interactuar(jugador: Node2D) -> void:
	if hecho:
		return
	hecho = true
	if jugador.has_method("quitar_interactuable"):
		jugador.quitar_interactuable(self)
	_aviso.visible = false
	monitoring = false
	if tipo == "basura":
		Sonido.efecto("recoger")
		var salir := create_tween()
		salir.tween_property(self, "scale", Vector2(0.2, 0.2), 0.25)
		salir.tween_callback(queue_free)
	else:
		Sonido.efecto("correcto")
		if planta == "flores":
			_poner(FLORES, 70.0)
		else:
			_poner(ARBOLITO, 80.0)
		_sprite.rotation = 0.0
		var crecer := create_tween()
		_sprite.scale *= 0.3
		crecer.tween_property(_sprite, "scale", _sprite.scale / 0.3, 0.5).set_trans(Tween.TRANS_BACK)
	usado.emit(self)

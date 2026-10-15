class_name Rio
extends Area2D
## Tramo de río. Su color pasa de contaminado a limpio según `limpieza` (0 a 1).
## Si el guardián cae al agua, avisa al nivel para que lo haga reaparecer.

signal guardian_cayo(guardian: Guardian)

const COLOR_CONTAMINADO := Color("5e5b2f")
const COLOR_LIMPIO := Color("3fa7e0")
const TEXTURA_PEZ := preload("res://assets/objects/pez.svg")

## Ancho y profundidad del agua; el origen es la esquina superior izquierda de la superficie.
@export var tamano := Vector2(96, 104)

var limpieza := 0.0:
	set(valor):
		limpieza = clampf(valor, 0.0, 1.0)
		if is_node_ready():
			_agua.color = COLOR_CONTAMINADO.lerp(COLOR_LIMPIO, limpieza)

var _peces: Array[Sprite2D] = []

@onready var _agua: ColorRect = $Agua
@onready var _forma: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"rio")
	_agua.size = tamano
	var rect := RectangleShape2D.new()
	# La zona que hace reaparecer empieza un poco bajo la superficie: se ve que "toca" el agua.
	rect.size = Vector2(tamano.x, tamano.y - 16.0)
	_forma.shape = rect
	_forma.position = Vector2(tamano.x / 2.0, 16.0 + rect.size.y / 2.0)
	limpieza = limpieza
	body_entered.connect(_al_entrar)


func hay_peces() -> bool:
	return not _peces.is_empty()


## Muestra peces saltando: señal visual de que el río volvió a estar sano.
func mostrar_peces(cantidad := 2) -> void:
	if hay_peces():
		return
	for i in cantidad:
		var pez := Sprite2D.new()
		pez.texture = TEXTURA_PEZ
		pez.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var x := tamano.x * (i + 1) / (cantidad + 1)
		pez.position = Vector2(x, 24.0)
		pez.flip_h = i % 2 == 1
		add_child(pez)
		_peces.append(pez)
		var salto := create_tween().set_loops()
		salto.tween_interval(0.4 + 0.5 * i)
		salto.tween_property(pez, "position:y", -36.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		salto.tween_property(pez, "position:y", 24.0, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		guardian_cayo.emit(cuerpo)

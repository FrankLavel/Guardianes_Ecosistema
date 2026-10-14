class_name Guardian
extends CharacterBody2D
## Personaje controlable: caminar, saltar y reaparecer si cae fuera del nivel.

signal reaparecio

@export_group("Movimiento")
@export var velocidad_maxima := 240.0
@export var aceleracion := 1800.0
@export var friccion := 2000.0

@export_group("Salto")
@export var fuerza_salto := 560.0
@export var gravedad := 1400.0
@export var velocidad_caida_maxima := 900.0
## Margen para saltar justo después de salir de una orilla (más amable para niños).
@export var tiempo_coyote := 0.12
## Margen para registrar el salto si se pulsa un poco antes de tocar el suelo.
@export var tiempo_buffer_salto := 0.12

@export_group("Nivel")
## Si el personaje baja de esta altura (coordenada Y global), reaparece.
@export var limite_caida := 2000.0

## Si es false, la entrada se asigna desde fuera (pruebas, cinemáticas).
var leer_entrada_del_jugador := true
var entrada_direccion := 0.0
var entrada_salto_presionado := false
var entrada_salto_mantenido := false

var punto_reaparicion: Vector2

var _tiempo_coyote_restante := 0.0
var _tiempo_buffer_restante := 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var camara: Camera2D = $Camera2D


func _ready() -> void:
	punto_reaparicion = global_position


func _physics_process(delta: float) -> void:
	if leer_entrada_del_jugador:
		entrada_direccion = Input.get_axis("mover_izquierda", "mover_derecha")
		entrada_salto_presionado = Input.is_action_just_pressed("saltar")
		entrada_salto_mantenido = Input.is_action_pressed("saltar")

	_aplicar_gravedad(delta)
	_aplicar_salto(delta)
	_aplicar_movimiento_horizontal(delta)
	move_and_slide()

	entrada_salto_presionado = false
	if entrada_direccion != 0.0:
		_sprite.flip_h = entrada_direccion < 0.0
	if global_position.y > limite_caida:
		reaparecer()


func reaparecer() -> void:
	global_position = punto_reaparicion
	velocity = Vector2.ZERO
	_tiempo_coyote_restante = 0.0
	_tiempo_buffer_restante = 0.0
	reaparecio.emit()


func _aplicar_gravedad(delta: float) -> void:
	if is_on_floor():
		_tiempo_coyote_restante = tiempo_coyote
	else:
		_tiempo_coyote_restante = maxf(_tiempo_coyote_restante - delta, 0.0)
		velocity.y = minf(velocity.y + gravedad * delta, velocidad_caida_maxima)


func _aplicar_salto(delta: float) -> void:
	if entrada_salto_presionado:
		_tiempo_buffer_restante = tiempo_buffer_salto
	else:
		_tiempo_buffer_restante = maxf(_tiempo_buffer_restante - delta, 0.0)

	if _tiempo_buffer_restante > 0.0 and _tiempo_coyote_restante > 0.0:
		velocity.y = -fuerza_salto
		_tiempo_buffer_restante = 0.0
		_tiempo_coyote_restante = 0.0

	# Salto variable: si se suelta el botón mientras sube, el salto es más corto.
	if not entrada_salto_mantenido and velocity.y < 0.0:
		velocity.y = maxf(velocity.y, -fuerza_salto * 0.4)


func _aplicar_movimiento_horizontal(delta: float) -> void:
	if entrada_direccion != 0.0:
		velocity.x = move_toward(velocity.x, entrada_direccion * velocidad_maxima, aceleracion * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)

class_name GaraAerea
extends CharacterBody2D
## Gara en el mapa aéreo: camina en 8 direcciones (animaciones en 4) e interactúa con E.

@export var velocidad := 300.0
@export var aceleracion := 2400.0

## Si es false, la entrada se asigna desde fuera (pruebas, cinemáticas).
var leer_entrada_del_jugador := true
var entrada_direccion := Vector2.ZERO
var entrada_interactuar := false
## "abajo", "arriba", "izquierda" o "derecha".
var mirando := "abajo"

var _interactuables: Array[Node2D] = []

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camara: Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	if leer_entrada_del_jugador:
		entrada_direccion = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
		entrada_interactuar = Input.is_action_just_pressed("interactuar")
	if Juego.entrada_bloqueada:
		entrada_direccion = Vector2.ZERO
		entrada_interactuar = false

	velocity = velocity.move_toward(entrada_direccion * velocidad, aceleracion * delta)
	move_and_slide()
	_animar()

	if entrada_interactuar:
		var objetivo := interactuable_mas_cercano()
		if objetivo:
			objetivo.interactuar(self)
	entrada_interactuar = false


func registrar_interactuable(objeto: Node2D) -> void:
	if objeto not in _interactuables:
		_interactuables.append(objeto)


func quitar_interactuable(objeto: Node2D) -> void:
	_interactuables.erase(objeto)


func interactuable_mas_cercano() -> Node2D:
	var mejor: Node2D = null
	for objeto in _interactuables:
		if is_instance_valid(objeto) and (mejor == null
				or global_position.distance_squared_to(objeto.global_position)
				< global_position.distance_squared_to(mejor.global_position)):
			mejor = objeto
	return mejor


func mirar_hacia(punto: Vector2) -> void:
	_actualizar_mirada(punto - global_position)
	_animar()


func _actualizar_mirada(direccion: Vector2) -> void:
	if direccion.length() < 0.1:
		return
	if absf(direccion.x) > absf(direccion.y):
		mirando = "derecha" if direccion.x > 0.0 else "izquierda"
	else:
		mirando = "abajo" if direccion.y > 0.0 else "arriba"


func _animar() -> void:
	var moviendose := velocity.length() > 20.0
	if moviendose:
		_actualizar_mirada(velocity)
	# El arte solo trae "izquierda": la derecha es el mismo dibujo volteado.
	var lado := "izquierda" if mirando == "derecha" else mirando
	sprite.flip_h = mirando == "derecha"
	var animacion := StringName(("caminar_" if moviendose else "idle_") + lado)
	if sprite.animation != animacion:
		sprite.play(animacion)

class_name Guardian
extends CharacterBody2D
## Personaje controlable: caminar, saltar, interactuar y reaparecer si cae fuera del nivel.

signal reaparecio
signal interactuo(objetivo: Node)

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

@export_group("Nado")
@export var gravedad_agua := 420.0
@export var velocidad_caida_agua := 140.0
## Empuje hacia arriba de cada brazada (tecla de saltar).
@export var fuerza_brazada := 260.0
## Qué tan rápido se mueve de lado dentro del agua (fracción de la velocidad normal).
@export var factor_velocidad_agua := 0.6
## Cerca de la superficie, saltar la saca del agua con un salto normal.
@export var margen_salir_agua := 34.0

@export_group("Trepar")
@export var velocidad_trepar := 190.0

@export_group("Interacción")
## Segundos que dura la pose de interactuar (el guardián no se mueve mientras tanto).
@export var duracion_interaccion := 0.35

## Si es false, la entrada se asigna desde fuera (pruebas, cinemáticas).
var leer_entrada_del_jugador := true
var entrada_direccion := 0.0
var entrada_salto_presionado := false
var entrada_salto_mantenido := false
var entrada_interactuar := false
## -1 arriba, 1 abajo (para trepar).
var entrada_vertical := 0.0

var punto_reaparicion: Vector2

var _tiempo_coyote_restante := 0.0
var _tiempo_buffer_restante := 0.0
var _tiempo_interaccion_restante := 0.0
## Objetos cercanos con un método interactuar(guardian).
var _interactuables: Array[Node2D] = []
## Ríos en los que está nadando (puede tocar dos a la vez en una orilla).
var _aguas: Array[Node2D] = []
## Enredaderas que está tocando y si va agarrado a una.
var _escalables: Array[Node2D] = []
var _trepando := false

## A partir de esta fracción de la velocidad máxima se usa "correr" en vez de "caminar".
const UMBRAL_CORRER := 0.6

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camara: Camera2D = $Camera2D


func _ready() -> void:
	punto_reaparicion = global_position
	var ruta: String = Juego.datos_personaje()["plataformas"]
	if not ruta.is_empty():
		sprite.sprite_frames = load(ruta)
		sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	if leer_entrada_del_jugador:
		entrada_direccion = Input.get_axis("mover_izquierda", "mover_derecha")
		entrada_salto_presionado = Input.is_action_just_pressed("saltar")
		entrada_salto_mantenido = Input.is_action_pressed("saltar")
		entrada_interactuar = Input.is_action_just_pressed("interactuar")
		entrada_vertical = Input.get_axis("mover_arriba", "mover_abajo")

	_aplicar_interaccion(delta)
	_actualizar_trepar()
	if _trepando:
		_aplicar_trepar()
	elif esta_nadando():
		_aplicar_nado(delta)
	else:
		_aplicar_gravedad(delta)
		if not esta_interactuando():
			_aplicar_salto(delta)
	if not _trepando:
		_aplicar_movimiento_horizontal(delta)
	move_and_slide()

	entrada_salto_presionado = false
	entrada_interactuar = false
	_actualizar_animacion()
	if global_position.y > limite_caida:
		reaparecer()


func esta_trepando() -> bool:
	return _trepando


func entrar_escalable(objeto: Node2D) -> void:
	if objeto not in _escalables:
		_escalables.append(objeto)


func salir_escalable(objeto: Node2D) -> void:
	_escalables.erase(objeto)


## Se agarra al presionar ↑ (o ↓ en el aire) junto a una enredadera; se suelta al saltar,
## al salir de la enredadera o al llegar al suelo bajando.
func _actualizar_trepar() -> void:
	if _escalables.is_empty():
		_trepando = false
		return
	if not _trepando:
		var subir := entrada_vertical < -0.5
		var bajar_en_el_aire := entrada_vertical > 0.5 and not is_on_floor()
		if subir or bajar_en_el_aire:
			_trepando = true
			velocity = Vector2.ZERO
			# ↑ también es tecla de salto: aquí significa "agarrarse", no saltar.
			entrada_salto_presionado = false
			_tiempo_buffer_restante = 0.0
	elif entrada_vertical > 0.5 and is_on_floor():
		_trepando = false


func _aplicar_trepar() -> void:
	# Saltar (con una tecla que no sea ↑) suelta la enredadera.
	if entrada_salto_presionado and entrada_vertical >= 0.0:
		_trepando = false
		velocity = Vector2(entrada_direccion * velocidad_maxima * 0.6, -fuerza_salto * 0.8)
		Sonido.efecto("salto", 0.05)
		return
	velocity = Vector2(entrada_direccion * velocidad_trepar * 0.4, entrada_vertical * velocidad_trepar)


func esta_nadando() -> bool:
	return not _aguas.is_empty()


func entrar_agua(agua: Node2D) -> void:
	if agua not in _aguas:
		_aguas.append(agua)
	# Al caer al agua se frena de golpe (el agua amortigua).
	velocity.y = minf(velocity.y, velocidad_caida_agua)
	# Tono azulado bajo el agua solo mientras no haya arte de nado.
	if not sprite.sprite_frames.has_animation(&"nadar"):
		sprite.modulate = Color(0.75, 0.9, 1.0)


func salir_agua(agua: Node2D) -> void:
	_aguas.erase(agua)
	if _aguas.is_empty():
		sprite.modulate = Color.WHITE


## Nombre de la animación que corresponde al estado actual del movimiento.
func animacion_segun_estado() -> StringName:
	if esta_interactuando():
		return &"interactuar"
	if _trepando:
		return &"trepar" if sprite.sprite_frames.has_animation(&"trepar") else &"saltar"
	if esta_nadando():
		# Si el personaje no tiene animación de nado, se usa la de caminar, más lenta.
		return &"nadar" if sprite.sprite_frames.has_animation(&"nadar") else &"caminar"
	if not is_on_floor():
		return &"saltar" if velocity.y < 0.0 else &"caer"
	var rapidez := absf(velocity.x)
	if rapidez < 5.0:
		return &"idle"
	return &"correr" if rapidez >= velocidad_maxima * UMBRAL_CORRER else &"caminar"


func _actualizar_animacion() -> void:
	# El arte mira a la derecha; se voltea al ir a la izquierda.
	if entrada_direccion != 0.0 and not esta_interactuando():
		sprite.flip_h = entrada_direccion < 0.0
	var animacion := animacion_segun_estado()
	if sprite.animation != animacion:
		sprite.play(animacion)
	# Las piernas avanzan al ritmo real del movimiento (evita que "patine" al acelerar).
	if _trepando:
		# Quieto en la enredadera: la animación se detiene.
		sprite.speed_scale = 1.0 if absf(velocity.y) > 1.0 else 0.0
	elif esta_nadando():
		sprite.speed_scale = 1.0 if sprite.animation == &"nadar" else 0.5
	elif animacion == &"caminar" or animacion == &"correr":
		sprite.speed_scale = clampf(absf(velocity.x) / velocidad_maxima, 0.6, 1.2)
	else:
		sprite.speed_scale = 1.0


func esta_interactuando() -> bool:
	return _tiempo_interaccion_restante > 0.0


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


func reaparecer() -> void:
	global_position = punto_reaparicion
	velocity = Vector2.ZERO
	_tiempo_coyote_restante = 0.0
	_tiempo_buffer_restante = 0.0
	_tiempo_interaccion_restante = 0.0
	_aguas.clear()
	_escalables.clear()
	_trepando = false
	sprite.modulate = Color.WHITE
	# Con interpolación de física activa, evita que se dibuje "deslizándose" hasta el punto de reaparición.
	reset_physics_interpolation()
	camara.reset_smoothing()
	reaparecio.emit()


func _aplicar_interaccion(delta: float) -> void:
	_tiempo_interaccion_restante = maxf(_tiempo_interaccion_restante - delta, 0.0)
	# También se puede interactuar nadando (quitar lirio, recoger basura que flota).
	if not entrada_interactuar or esta_interactuando() or not (is_on_floor() or esta_nadando()):
		return
	var objetivo := interactuable_mas_cercano()
	if objetivo == null:
		return
	_tiempo_interaccion_restante = duracion_interaccion
	# Mirar hacia el objeto.
	sprite.flip_h = objetivo.global_position.x < global_position.x
	objetivo.interactuar(self)
	interactuo.emit(objetivo)


func _aplicar_nado(delta: float) -> void:
	var agua: Node2D = _aguas[0]
	var profundidad: float = global_position.y - agua.superficie_y()
	velocity.y = minf(velocity.y + gravedad_agua * delta, velocidad_caida_agua)
	if entrada_salto_presionado:
		if profundidad < margen_salir_agua:
			# Cerca de la superficie: salto normal para salir a la orilla.
			velocity.y = -fuerza_salto
			Sonido.efecto("salto", 0.05)
		else:
			velocity.y = -fuerza_brazada
			Sonido.efecto("brazada", 0.1)
	# No se puede "volar" fuera del agua a brazadas: arriba de la superficie no hay empuje.
	_tiempo_coyote_restante = 0.0


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
		Sonido.efecto("salto", 0.05)
		_tiempo_buffer_restante = 0.0
		_tiempo_coyote_restante = 0.0

	# Salto variable: si se suelta el botón mientras sube, el salto es más corto.
	if not entrada_salto_mantenido and velocity.y < 0.0:
		velocity.y = maxf(velocity.y, -fuerza_salto * 0.4)


func _aplicar_movimiento_horizontal(delta: float) -> void:
	var maxima := velocidad_maxima * (factor_velocidad_agua if esta_nadando() else 1.0)
	if entrada_direccion != 0.0 and not esta_interactuando():
		velocity.x = move_toward(velocity.x, entrada_direccion * maxima, aceleracion * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friccion * delta)

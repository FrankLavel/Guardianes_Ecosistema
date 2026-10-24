class_name AnimalValle
extends ZonaInteraccion
## Animal que pasea libre por el valle. Aparece cuando su zona ya está restaurada.
## Después del final puede ir hacia el guardián para pedirle ayuda (ver pedidos_ayuda.gd).

signal llego_al_jugador(animal: AnimalValle)
signal hablaron(animal: AnimalValle)

enum Estado { PASEO, VA_AL_JUGADOR, ESPERA, SIGUE }

## Id de la especie (como en la bitácora): "venado", "garza", "pato_mexicano", "monarca".
@export var especie := "venado"
## Zona que tiene que estar restaurada para que aparezca ("" = siempre).
@export var requiere_zona := ""
@export var cuadros: SpriteFrames
@export var anim_quieto := &"idle"
@export var anim_caminar := &"idle"
## Otras poses para cuando se detiene a descansar (comer, echarse...). Se elige una al azar.
@export var anims_pausa: Array[StringName] = []
@export var escala := 0.3
## Rectángulo del valle por donde pasea.
@export var zona_paseo := Rect2(1000, 1000, 400, 300)
@export var velocidad := 70.0
## Las mariposas vuelan: suben y bajan y no llevan sombra.
@export var vuela := false
## El dibujo mira a la derecha (si no, se voltea al revés).
@export var mira_derecha := true

var estado := Estado.PASEO
## A quién sigue o hacia quién va (el guardián, o la mamá en el caso de una cría).
var objetivo: Node2D

var _destino := Vector2.ZERO
var _pausa := 0.0
var _hablando := false
var _pose := &""

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var _sombra: Polygon2D = $Sombra
@onready var _alerta: Label = $Alerta


func _ready() -> void:
	super()
	sprite.sprite_frames = cuadros
	sprite.scale = Vector2.ONE * escala
	sprite.play(anim_quieto)
	var alto := cuadros.get_frame_texture(anim_quieto, 0).get_height()
	sprite.offset = Vector2(0, -alto / 2.0)
	_sombra.visible = not vuela
	_alerta.position.y = -alto * escala - 60.0
	_alerta.visible = false
	if vuela:
		var flotar := create_tween().set_loops()
		flotar.tween_property(sprite, "position:y", -50.0, 0.8).set_trans(Tween.TRANS_SINE)
		flotar.tween_property(sprite, "position:y", -34.0, 0.8).set_trans(Tween.TRANS_SINE)
	_pausa = randf_range(0.0, 2.0)
	_destino = global_position
	actualizar_visibilidad()


## Solo está en el valle si su zona ya se restauró.
func actualizar_visibilidad() -> void:
	var presente := requiere_zona.is_empty() or Juego.zona_esta_completa(requiere_zona)
	visible = presente
	monitoring = presente
	process_mode = Node.PROCESS_MODE_INHERIT if presente else Node.PROCESS_MODE_DISABLED


func _physics_process(delta: float) -> void:
	if _hablando or Juego.entrada_bloqueada:
		_animar(Vector2.ZERO)
		return
	var paso := Vector2.ZERO
	match estado:
		Estado.PASEO:
			paso = _pasear(delta)
		Estado.VA_AL_JUGADOR:
			if objetivo and global_position.distance_to(objetivo.global_position) > 90.0:
				paso = _mover_hacia(objetivo.global_position, velocidad * 2.0, delta)
			else:
				estado = Estado.ESPERA
				llego_al_jugador.emit(self)
		Estado.SIGUE:
			# Camina detrás de quien sigue, sin encimarse.
			if objetivo and global_position.distance_to(objetivo.global_position) > 70.0:
				paso = _mover_hacia(objetivo.global_position, velocidad * 3.0, delta)
	_animar(paso)


func _pasear(delta: float) -> Vector2:
	if _pausa > 0.0:
		_pausa -= delta
		return Vector2.ZERO
	if global_position.distance_to(_destino) < 8.0:
		_pausa = randf_range(1.5, 4.5)
		_pose = ([anim_quieto] + anims_pausa).pick_random()
		_destino = Vector2(randf_range(zona_paseo.position.x, zona_paseo.end.x),
			randf_range(zona_paseo.position.y, zona_paseo.end.y))
		return Vector2.ZERO
	return _mover_hacia(_destino, velocidad, delta)


func _mover_hacia(punto: Vector2, rapidez: float, delta: float) -> Vector2:
	var antes := global_position
	global_position = global_position.move_toward(punto, rapidez * delta)
	return global_position - antes


func _animar(paso: Vector2) -> void:
	var quieto := _pose if estado == Estado.PASEO and not _pose.is_empty() else anim_quieto
	var anim := anim_caminar if paso.length() > 0.01 else quieto
	if sprite.animation != anim:
		sprite.play(anim)
	if absf(paso.x) > 0.01:
		sprite.flip_h = (paso.x < 0.0) == mira_derecha


## El animal camina hacia `jugador` (para pedirle ayuda) y espera ahí con el aviso "!".
func ir_hacia(jugador: Node2D) -> void:
	objetivo = jugador
	estado = Estado.VA_AL_JUGADOR
	mostrar_alerta("!")


## Se queda quieto donde está (mientras dura el pedido).
func esperar() -> void:
	estado = Estado.ESPERA


func seguir(a: Node2D) -> void:
	objetivo = a
	estado = Estado.SIGUE


func volver_a_pasear() -> void:
	objetivo = null
	estado = Estado.PASEO
	_destino = global_position
	mostrar_alerta("")


## "!" = necesita ayuda, "…" = esperando a que termines, "" = sin aviso.
func mostrar_alerta(texto: String) -> void:
	_alerta.text = texto
	_alerta.visible = not texto.is_empty()


func _al_interactuar(jugador: Node2D) -> void:
	if Dialogo.activo:
		return
	if jugador is GaraAerea:
		jugador.mirar_hacia(global_position)
	sprite.flip_h = (jugador.global_position.x < global_position.x) == mira_derecha
	_hablando = true
	hablaron.emit(self)
	# Quien atiende la señal muestra el diálogo; se espera a que termine para volver a caminar.
	await get_tree().process_frame
	while Dialogo.activo:
		await Dialogo.terminado
	_hablando = false

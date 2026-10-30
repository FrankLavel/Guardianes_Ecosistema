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
## Lugares que no pisa (la milpa); las mariposas sí pasan volando por encima.
var prohibido: Array[Rect2] = []

var estado := Estado.PASEO
## A quién sigue o hacia quién va (el guardián, o la mamá en el caso de una cría).
var objetivo: Node2D

var _destino := Vector2.ZERO
var _pausa := 0.0
var _hablando := false
var _pose := &""
var _dormido := false
var _alto_alerta := 0.0
var _salto_alerta: Tween
var _burbuja: Panel

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
	_alto_alerta = -alto * escala - 60.0
	_alerta.position.y = _alto_alerta
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
	# De noche los que pasean se echan a dormir; las mariposas se van a descansar a los árboles.
	var dormido := Juego.es_de_noche and estado == Estado.PASEO
	if dormido != _dormido:
		_dormido = dormido
		sprite.visible = not (dormido and vuela)
		monitoring = not (dormido and vuela)
	if dormido:
		var pose := &"descansar" if cuadros.has_animation(&"descansar") else anim_quieto
		if sprite.animation != pose:
			sprite.play(pose)
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
		for intento in 10:
			_destino = Vector2(randf_range(zona_paseo.position.x, zona_paseo.end.x),
				randf_range(zona_paseo.position.y, zona_paseo.end.y))
			if not _pisa_prohibido(_destino):
				break
		return Vector2.ZERO
	var paso := _mover_hacia(_destino, velocidad, delta)
	if paso == Vector2.ZERO:
		_destino = global_position  # Se topó con la milpa: escoge otro rumbo.
	return paso


func _mover_hacia(punto: Vector2, rapidez: float, delta: float) -> Vector2:
	var antes := global_position
	var nuevo := antes.move_toward(punto, rapidez * delta)
	# Si el paso cae en la milpa, se desliza por la orilla (solo en x o solo en y) o se queda.
	if _pisa_prohibido(nuevo) and not _pisa_prohibido(antes):
		nuevo = Vector2(nuevo.x, antes.y)
		if _pisa_prohibido(nuevo):
			nuevo = Vector2(antes.x, antes.move_toward(punto, rapidez * delta).y)
		if _pisa_prohibido(nuevo):
			nuevo = antes
	global_position = nuevo
	return global_position - antes


func _pisa_prohibido(punto: Vector2) -> bool:
	if vuela:
		return false
	for zona in prohibido:
		if zona.has_point(punto):
			return true
	return false


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
## Globito con un ícono sobre el animal (lo que necesita o lo que tiene listo). null lo quita.
func mostrar_burbuja(textura: Texture2D) -> void:
	if _burbuja == null:
		_burbuja = Panel.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(1, 0.99, 0.94)
		estilo.border_color = Color(0.35, 0.25, 0.15)
		estilo.set_border_width_all(3)
		estilo.set_corner_radius_all(24)
		_burbuja.add_theme_stylebox_override("panel", estilo)
		_burbuja.size = Vector2(58, 58)
		_burbuja.position = Vector2(-29, _alto_alerta - 4)
		_burbuja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var imagen := TextureRect.new()
		imagen.name = "Icono"
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.position = Vector2(8, 8)
		imagen.size = Vector2(42, 42)
		_burbuja.add_child(imagen)
		add_child(_burbuja)
		var flotar := _burbuja.create_tween().set_loops()
		flotar.tween_property(_burbuja, "position:y", _alto_alerta - 14, 0.7).set_trans(Tween.TRANS_SINE)
		flotar.tween_property(_burbuja, "position:y", _alto_alerta - 4, 0.7).set_trans(Tween.TRANS_SINE)
	_burbuja.visible = textura != null
	(_burbuja.get_node("Icono") as TextureRect).texture = textura


func mostrar_alerta(texto: String) -> void:
	_alerta.text = texto
	_alerta.visible = not texto.is_empty()
	if _salto_alerta:
		_salto_alerta.kill()
	_alerta.position.y = _alto_alerta
	# El "!" brinca para que se note desde lejos.
	if texto == "!":
		_salto_alerta = create_tween().set_loops()
		_salto_alerta.tween_property(_alerta, "position:y", _alto_alerta - 14.0, 0.3).set_trans(Tween.TRANS_SINE)
		_salto_alerta.tween_property(_alerta, "position:y", _alto_alerta, 0.3).set_trans(Tween.TRANS_SINE)


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

class_name Rio
extends Area2D
## Tramo de río. Su color pasa de contaminado a limpio según `limpieza` (0 a 1).
## Si el guardián cae al agua sucia (o aún no sabe nadar), avisa al nivel para que reaparezca;
## si el agua está limpia y tiene la habilidad "nadar", puede nadar en él.

signal guardian_cayo(guardian: Guardian)

const MARGEN_ORILLA := 18.0
const FRAMES_ANIMALES := preload("res://assets/characters/animales/zona1_animales_frames.tres")

## Ancho y profundidad del agua; el origen es la esquina superior izquierda de la superficie.
@export var tamano := Vector2(96, 104)
## Si es false, nunca se puede nadar aquí (por ejemplo, un río que sigue contaminado).
@export var nadable_si_limpio := true
## Desde qué limpieza se puede nadar. El río exige agua limpia (1.0); el lago, turbio por el
## lirio pero sin veneno, permite nadar desde antes.
@export_range(0.0, 1.0) var limpieza_minima_nado := 0.99

var limpieza := 0.0:
	set(valor):
		limpieza = clampf(valor, 0.0, 1.0)
		if is_node_ready():
			(_agua.material as ShaderMaterial).set_shader_parameter("limpieza", limpieza)

## Para animar el cambio de color en vez de cambiarlo de golpe.
func animar_limpieza(objetivo: float, segundos := 1.0) -> void:
	create_tween().tween_property(self, "limpieza", objetivo, segundos)

var _peces: Array[AnimatedSprite2D] = []

@onready var _agua: ColorRect = $Agua
@onready var _forma: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"rio")
	# El agua se mete un poco bajo las orillas para que no queden huecos entre el suelo y el río.
	_agua.position = Vector2(-MARGEN_ORILLA, 0)
	_agua.size = tamano + Vector2(MARGEN_ORILLA * 2.0, 0)
	(_agua.material as ShaderMaterial).set_shader_parameter("alto_px", tamano.y)
	var rect := RectangleShape2D.new()
	# La zona que hace reaparecer empieza un poco bajo la superficie: se ve que "toca" el agua.
	rect.size = Vector2(tamano.x, tamano.y - 16.0)
	_forma.shape = rect
	_forma.position = Vector2(tamano.x / 2.0, 16.0 + rect.size.y / 2.0)
	limpieza = limpieza
	_crear_fondo()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func es_nadable() -> bool:
	return nadable_si_limpio and limpieza >= limpieza_minima_nado and Juego.tiene_habilidad("nadar")


func superficie_y() -> float:
	return global_position.y


## Lecho del río: para poder nadar hace falta un fondo donde apoyarse.
func _crear_fondo() -> void:
	var fondo := StaticBody2D.new()
	fondo.name = "Fondo"
	var forma := CollisionShape2D.new()
	var segmento := SegmentShape2D.new()
	segmento.a = Vector2(-MARGEN_ORILLA, tamano.y)
	segmento.b = Vector2(tamano.x + MARGEN_ORILLA, tamano.y)
	forma.shape = segmento
	fondo.add_child(forma)
	add_child(fondo)


func hay_peces() -> bool:
	return not _peces.is_empty()


## Muestra peces saltando: señal visual de que el río volvió a estar sano.
func mostrar_peces(cantidad := 2) -> void:
	if hay_peces():
		return
	for i in cantidad:
		var pez := AnimatedSprite2D.new()
		pez.sprite_frames = FRAMES_ANIMALES
		pez.animation = &"pez"
		pez.play()
		pez.scale = Vector2(0.11, 0.11)
		pez.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	if not cuerpo is Guardian:
		return
	Sonido.efecto("chapoteo", 0.1)
	if es_nadable():
		cuerpo.entrar_agua(self)
	else:
		guardian_cayo.emit(cuerpo)


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.salir_agua(self)

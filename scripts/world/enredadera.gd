class_name Enredadera
extends Area2D
## Enredadera trepable. Crece hacia arriba desde su origen (el pie) hasta `altura` píxeles.
## Arriba tiene una pequeña plataforma para pararse. El guardián trepa con ↑ / ↓.

signal termino_de_crecer

const TEXTURA := preload("res://assets/objects/zona2/enredadera.png")
const ANCHO := 40.0

@export var altura := 192.0

var crecida := false

var _visual: TextureRect
var _forma: CollisionShape2D
var _plataforma: CollisionShape2D


func _ready() -> void:
	add_to_group(&"escalable")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_visual = TextureRect.new()
	_visual.texture = TEXTURA
	_visual.stretch_mode = TextureRect.STRETCH_TILE
	_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_visual.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_visual.scale = Vector2.ONE * _escala()
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)
	_forma = CollisionShape2D.new()
	_forma.shape = RectangleShape2D.new()
	add_child(_forma)
	# Plataforma de arriba: se atraviesa desde abajo (one-way).
	var cuerpo := StaticBody2D.new()
	_plataforma = CollisionShape2D.new()
	var segmento := RectangleShape2D.new()
	segmento.size = Vector2(ANCHO + 30.0, 8.0)
	_plataforma.shape = segmento
	_plataforma.one_way_collision = true
	cuerpo.add_child(_plataforma)
	add_child(cuerpo)
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	_ajustar(0.0)


## Crece de 0 a la altura completa.
func crecer(segundos := 1.2) -> void:
	var animacion := create_tween()
	animacion.tween_method(_ajustar, 0.0, 1.0, segundos).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await animacion.finished
	crecida = true
	termino_de_crecer.emit()


func crecer_ya() -> void:
	_ajustar(1.0)
	crecida = true


## La textura se escala para que mida ANCHO de ancho en el mundo.
func _escala() -> float:
	return ANCHO / TEXTURA.get_width()


func _ajustar(fraccion: float) -> void:
	var alto := maxf(altura * fraccion, 1.0)
	_visual.size = Vector2(ANCHO, alto) / _escala()
	_visual.position = Vector2(-ANCHO / 2.0, -alto)
	(_forma.shape as RectangleShape2D).size = Vector2(ANCHO, alto)
	_forma.position = Vector2(0, -alto / 2.0)
	_plataforma.position = Vector2(0, -alto + 4.0)
	_plataforma.disabled = fraccion < 0.99


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo.has_method("entrar_escalable"):
		cuerpo.entrar_escalable(self)


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo.has_method("salir_escalable"):
		cuerpo.salir_escalable(self)

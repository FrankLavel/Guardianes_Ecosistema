class_name Comedero
extends ZonaInteraccion
## Comedero de un corral: con E se les da de comer a todos sus animales y se recoge lo que ya dieron
## (ver Granja.atender_todos). Va en la orilla de enfrente del corral y se mueve con él.

signal usado(comedero: Comedero)


func _ready() -> void:
	super()
	_aviso.text = "E  Comedero"
	queue_redraw()


## Una canoa de madera con maíz.
func _draw() -> void:
	var madera := Color(0.45, 0.28, 0.13)
	var oscuro := Color(0.18, 0.1, 0.05)
	draw_rect(Rect2(-34, -22, 68, 18), oscuro)
	draw_rect(Rect2(-32, -20, 64, 14), madera)
	draw_rect(Rect2(-30, -20, 60, 5), Color(0.95, 0.78, 0.2))
	draw_rect(Rect2(-30, -6, 6, 8), oscuro)
	draw_rect(Rect2(24, -6, 6, 8), oscuro)


func _al_interactuar(_jugador: Node2D) -> void:
	usado.emit(self)

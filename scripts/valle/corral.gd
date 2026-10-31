class_name Corral
extends Node2D
## Cerca del corral: cuatro tramos de la cerca del valle en forma de rombo, centrados en la posición.
## Se mueve en el modo decorar (ver Decorador) y los animales se van con ella.

const CERCA := preload("res://assets/maps/valle/objetos/cerca.png")
## Por donde caminan los animales, alrededor del centro.
const PASEO := Vector2(240, 120)

## Con qué nombre se guarda dónde quedó (ver Granja.posicion).
const clave := "corral"

var animales: Array[AnimalValle] = []


func _ready() -> void:
	add_to_group(&"movible")
	# Los tramos se ordenan con lo demás del valle: el de atrás queda detrás de los animales.
	y_sort_enabled = true
	for tramo in [[Vector2(-140, -22), false], [Vector2(140, -22), true], [Vector2(-140, 150), true], [Vector2(140, 150), false]]:
		var cerca := Sprite2D.new()
		cerca.texture = CERCA
		cerca.scale = Vector2(0.66, 0.6)
		cerca.offset = Vector2(0, -CERCA.get_height() / 2.0)
		cerca.flip_h = tramo[1]
		cerca.position = tramo[0]
		add_child(cerca)


func paseo() -> Rect2:
	return Rect2(global_position - PASEO / 2.0, PASEO)


func huella() -> Rect2:
	return Rect2(global_position + Vector2(-175, -100), Vector2(350, 260))


func contiene(punto: Vector2) -> bool:
	return huella().has_point(punto)


func agregar(animal: AnimalValle) -> void:
	animales.append(animal)
	animal.zona_paseo = paseo()


## Mueve la cerca y a los animales con ella (y siguen paseando dentro).
func mover_a(destino: Vector2) -> void:
	var cambio := destino - global_position
	global_position = destino
	for animal in animales:
		animal.global_position += cambio
		animal.zona_paseo = paseo()
		animal.reiniciar_paseo()

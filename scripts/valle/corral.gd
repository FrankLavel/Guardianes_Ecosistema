class_name Corral
extends Node2D
## Corral de una especie: cuatro tramos de la cerca del valle en forma de rombo, centrados en la
## posición. Las aves (gallina, guajolote) tienen un gallinero adentro donde pasan la noche. Se mueve en
## el modo decorar (ver Decorador) y los animales se van con él.

const CERCA := preload("res://assets/maps/valle/objetos/cerca.png")
const GALLINERO := "res://assets/maps/valle/objetos/gallinero.png"
## Por donde caminan los animales, alrededor del centro (con tamaño 1).
const PASEO := Vector2(270, 130)
## Dónde va el gallinero (al fondo del corral, con tamaño 1), qué tan ancho es y dónde queda el pie de
## su rampa (por donde entran las aves), contando desde el gallinero.
const LUGAR_GALLINERO := Vector2(-70, 40)
const ANCHO_GALLINERO := 170.0
const RAMPA := Vector2(78, -4)

var especie := "gallina"
var animales: Array[AnimalValle] = []
## Tamaño del corral de la especie (data/granja.json) y cuánto crece con más animales (ver ajustar).
var base := 1.0
var tamano := 1.0
var con_gallinero := false
var _cuerpo: StaticBody2D
## El comedero va en la orilla de enfrente (lo pone el valle; ver Comedero).
var comedero: Comedero:
	set(valor):
		comedero = valor
		add_child(comedero)
		_acomodar_comedero()

## Con qué nombre se guarda dónde quedó (el de la gallina usa el nombre de cuando había un solo corral).
var clave: String:
	get:
		return "corral" if especie == "gallina" else "corral_" + especie


func _ready() -> void:
	add_to_group(&"movible")
	# Los tramos se ordenan con lo demás del valle: el de atrás queda detrás de los animales.
	y_sort_enabled = true
	_poner_cerca()


## Forma de choque de un tramo de cerca (el dibujo es una cerca en diagonal): una línea por la base de
## los postes, para que el guardián no la atraviese. Sirve para los corrales y la cerca suelta del valle.
static func choque_de_cerca(tramo: Sprite2D) -> CollisionShape2D:
	var forma := SegmentShape2D.new()
	var lado := -1.0 if tramo.flip_h else 1.0
	forma.a = Vector2(-200.0 * lado, -25.0) * tramo.scale
	forma.b = Vector2(200.0 * lado, -210.0) * tramo.scale
	var choque := CollisionShape2D.new()
	choque.shape = forma
	choque.position = tramo.position
	return choque


func _poner_cerca() -> void:
	for hijo in get_children():
		if hijo != comedero:
			hijo.queue_free()
	_acomodar_comedero()
	_cuerpo = StaticBody2D.new()
	add_child(_cuerpo)
	for tramo in [[Vector2(-140, -22), false], [Vector2(140, -22), true], [Vector2(-140, 150), true], [Vector2(140, 150), false]]:
		var cerca := Sprite2D.new()
		cerca.texture = CERCA
		cerca.scale = Vector2(0.66, 0.6) * tamano
		cerca.offset = Vector2(0, -CERCA.get_height() / 2.0)
		cerca.flip_h = tramo[1]
		cerca.position = tramo[0] * tamano
		add_child(cerca)
		_cuerpo.add_child(choque_de_cerca(cerca))
	if con_gallinero and ResourceLoader.exists(GALLINERO):
		var gallinero := Sprite2D.new()
		gallinero.name = "Gallinero"
		gallinero.texture = load(GALLINERO)
		gallinero.scale = Vector2.ONE * ANCHO_GALLINERO * tamano / gallinero.texture.get_width()
		gallinero.offset = Vector2(0, -gallinero.texture.get_height() / 2.0)
		gallinero.position = LUGAR_GALLINERO * tamano
		add_child(gallinero)


func _acomodar_comedero() -> void:
	if comedero:
		comedero.position = Vector2(60, 150) * tamano


## El pie de la rampa del gallinero.
func puerta_local() -> Vector2:
	return (LUGAR_GALLINERO + RAMPA) * tamano


## Con 3 o 4 animales el corral se hace un poco más grande.
func ajustar(cuantos: int) -> void:
	var nuevo := base * (1.0 if cuantos <= 2 else 1.2)
	if is_equal_approx(nuevo, tamano):
		return
	tamano = nuevo
	if is_inside_tree():
		_poner_cerca()
	for animal in animales:
		animal.zona_paseo = paseo()
		animal.reiniciar_paseo()


func paseo() -> Rect2:
	var tam := PASEO * tamano
	return Rect2(global_position + Vector2(0, 64) * tamano - tam / 2.0, tam)


## Lo que ocupa la cerca dibujada (cada tramo mide 274 x 184 con tamaño 1).
func huella() -> Rect2:
	return Rect2(global_position + Vector2(-280, -210) * tamano, Vector2(560, 370) * tamano)


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

class_name PuzzleCompuertas
extends PuzzleBase
## Puzzle 1 (Zona 1): abrir y cerrar 3 válvulas para que el agua sucia de la fábrica pase por
## la planta de tratamiento antes de llegar al río.
##
##   A: fábrica -> río directo        (debe quedar CERRADA)
##   B: fábrica -> planta             (ABIERTA)
##   C: planta  -> río (agua tratada) (ABIERTA)

const COLOR_VACIO := Color(0.45, 0.43, 0.4)
const COLOR_SUCIA := Color(0.42, 0.33, 0.16)
const COLOR_LIMPIA := Color(0.25, 0.65, 0.95)

## Puntos del diagrama (coordenadas dentro de %Diagrama).
const FABRICA := Vector2(170, 170)
const UNION := Vector2(440, 170)
const RIO_X := 1130.0
const PLANTA := Vector2(700, 430)
const TUBOS := {
	"fabrica": [FABRICA, UNION],
	"a": [UNION, Vector2(RIO_X, 170)],
	"b": [UNION, Vector2(440, 430), PLANTA],
	"c": [PLANTA, Vector2(RIO_X, 430)],
}
## De qué tubo le llega el agua a cada uno: el agua avanza en orden por el camino.
const ALIMENTA := {"fabrica": "", "a": "fabrica", "b": "fabrica", "c": "b"}
const ANCHO_BORDE := 34.0
const ANCHO_TUBO := 24.0
const ANCHO_AGUA := 16.0
## Separación y velocidad de las ondas que muestran hacia dónde corre el agua.
const ONDA_CADA := 36.0
const ONDA_VELOCIDAD := 70.0

## Estado de las válvulas: true = abierta.
var valvulas := {"a": true, "b": false, "c": false}
## Resultado de la última vez que se abrió el agua: color de cada tubo ("" = sin agua aún).
var flujo := {}
var _avance := 1.0
var _fase := 0.0

@onready var diagrama: Control = %Diagrama
@onready var _botones := {"a": %ValvulaA, "b": %ValvulaB, "c": %ValvulaC}
@onready var _boton_agua: Button = %BtnAgua
@onready var _planta: Control = %Planta
@onready var _rio: ColorRect = %RioDiagrama


func _ready() -> void:
	super()
	for id in _botones:
		var boton: TextureButton = _botones[id]
		boton.pressed.connect(alternar.bind(id))
		# Se agranda un poco la válvula elegida para que se note con teclado o control.
		boton.focus_entered.connect(func(): boton.scale = Vector2(1.15, 1.15))
		boton.focus_exited.connect(func(): boton.scale = Vector2.ONE)
	_boton_agua.pressed.connect(abrir_agua)
	diagrama.draw.connect(_dibujar)
	# B va en el tubo vertical: su imagen se gira para que quede alineada con él.
	var imagen: Image = _botones["b"].texture_normal.get_image()
	imagen.rotate_90(CLOCKWISE)
	_botones["b"].texture_normal = ImageTexture.create_from_image(imagen)
	_actualizar_botones()


func _process(delta: float) -> void:
	if not flujo.is_empty():
		_fase = fmod(_fase + delta * ONDA_VELOCIDAD, ONDA_CADA)
		diagrama.queue_redraw()


func _al_abrir() -> void:
	decir("El agua sucia de la fábrica no debe llegar al río.\nAbre o cierra las válvulas y luego presiona ABRIR EL AGUA.")
	_botones["a"].grab_focus()


func alternar(id: String) -> void:
	if esta_resuelto:
		return
	valvulas[id] = not valvulas[id]
	Sonido.efecto("valvula", 0.05)
	flujo.clear()
	_rio.color = Color(0.36, 0.42, 0.32)
	_actualizar_botones()
	diagrama.queue_redraw()


## Calcula a dónde llega el agua con las válvulas actuales.
## Devuelve {tubo: color} y un texto con lo que pasó.
func calcular() -> Dictionary:
	var a: bool = valvulas["a"]
	var b: bool = valvulas["b"]
	var c: bool = valvulas["c"]
	var colores := {"fabrica": COLOR_SUCIA}
	if a:
		colores["a"] = COLOR_SUCIA
	if b:
		colores["b"] = COLOR_SUCIA
		if c:
			colores["c"] = COLOR_LIMPIA
	var resultado := "bien"
	if a:
		resultado = "sucia_al_rio"
	elif not b:
		resultado = "sin_salida"
	elif not c:
		resultado = "planta_llena"
	return {"colores": colores, "resultado": resultado}


func abrir_agua() -> void:
	if esta_resuelto:
		return
	var calculo := calcular()
	flujo = calculo["colores"]
	_avance = 0.0
	var animacion := create_tween()
	animacion.tween_method(func(v): _avance = v; diagrama.queue_redraw(), 0.0, 1.0, 1.6)
	await animacion.finished
	match calculo["resultado"]:
		"sucia_al_rio":
			_rio.color = COLOR_SUCIA
			fallar("¡Oh no! El agua sucia llegó directo al río.\nEsa válvula debe estar cerrada.")
		"sin_salida":
			fallar("El agua sucia no tiene a dónde ir y se desborda.\nNecesita un camino hacia algún lugar.")
		"planta_llena":
			_planta.modulate = Color(1, 0.7, 0.6)
			fallar("El agua entró a la planta, pero no puede salir.\n¡La planta se está llenando!")
		"bien":
			_rio.color = COLOR_LIMPIA
			_planta.modulate = Color(0.8, 1, 0.8)
			decir("¡Muy bien! La planta de tratamiento limpia el agua\nantes de regresarla al río. Así los peces pueden vivir.", Color(0.8, 1, 0.7))
			_boton_agua.visible = false
			resolver()


func _actualizar_botones() -> void:
	for id in _botones:
		var boton: TextureButton = _botones[id]
		boton.button_pressed = valvulas[id]
		boton.get_node("Estado").text = "ABIERTA" if valvulas[id] else "CERRADA"


func _largo(id: String) -> float:
	var puntos: Array = TUBOS[id]
	var largo := 0.0
	for i in puntos.size() - 1:
		largo += (puntos[i] as Vector2).distance_to(puntos[i + 1])
	return largo


## Distancia que recorre el agua desde la fábrica hasta el inicio del tubo.
func _inicio(id: String) -> float:
	var anterior: String = ALIMENTA[id]
	return 0.0 if anterior == "" else _inicio(anterior) + _largo(anterior)


func _dibujar() -> void:
	# Por capas (borde, tubo, agua) y con uniones redondas, para que las esquinas y los cruces
	# se vean como un solo tubo.
	for id in TUBOS:
		_trazo(TUBOS[id], Color(0.2, 0.2, 0.22), ANCHO_BORDE)
	for id in TUBOS:
		_trazo(TUBOS[id], COLOR_VACIO, ANCHO_TUBO)
	if flujo.is_empty():
		return
	var recorrido := 0.0
	for id in flujo:
		recorrido = maxf(recorrido, _inicio(id) + _largo(id))
	recorrido *= _avance
	for id in flujo:
		_dibujar_agua(id, recorrido - _inicio(id))


func _trazo(puntos: Array, color: Color, ancho: float) -> void:
	for i in puntos.size() - 1:
		diagrama.draw_line(puntos[i], puntos[i + 1], color, ancho, true)
	for p in puntos:
		diagrama.draw_circle(p, ancho / 2.0, color, true, -1.0, true)


## Llena el tubo hasta `distancia` y encima dibuja ondas claras que avanzan con la corriente.
func _dibujar_agua(id: String, distancia: float) -> void:
	if distancia <= 0.0:
		return
	var puntos: Array = TUBOS[id]
	var color: Color = flujo[id]
	var claro := color.lightened(0.35)
	var hecho := 0.0
	diagrama.draw_circle(puntos[0], ANCHO_AGUA / 2.0, color, true, -1.0, true)
	for i in puntos.size() - 1:
		var p0: Vector2 = puntos[i]
		var p1: Vector2 = puntos[i + 1]
		var tramo := p0.distance_to(p1)
		var lleno := minf(distancia - hecho, tramo)
		if lleno <= 0.0:
			return
		var fin := p0.lerp(p1, lleno / tramo)
		diagrama.draw_line(p0, fin, color, ANCHO_AGUA, true)
		diagrama.draw_circle(fin, ANCHO_AGUA / 2.0, color, true, -1.0, true)
		# Las ondas usan la distancia desde la fábrica: así siguen de un tubo al otro sin saltos.
		var direccion := (p1 - p0) / tramo
		var desde := _inicio(id) + hecho
		var onda := ONDA_CADA - fmod(desde - _fase + ONDA_CADA * 100.0, ONDA_CADA)
		while onda < lleno:
			var a := p0 + direccion * onda
			var b := p0 + direccion * minf(onda + 12.0, lleno)
			diagrama.draw_line(a, b, claro, 6.0, true)
			onda += ONDA_CADA
		hecho += tramo

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

## Estado de las válvulas: true = abierta.
var valvulas := {"a": true, "b": false, "c": false}
## Resultado de la última vez que se abrió el agua: color de cada tubo ("" = sin agua aún).
var flujo := {}
var _avance := 1.0

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
	_actualizar_botones()


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
	animacion.tween_method(func(v): _avance = v; diagrama.queue_redraw(), 0.0, 1.0, 0.9)
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


func _dibujar() -> void:
	for id in TUBOS:
		var puntos: Array = TUBOS[id]
		for i in puntos.size() - 1:
			diagrama.draw_line(puntos[i], puntos[i + 1], Color(0.2, 0.2, 0.22), 34.0, true)
			diagrama.draw_line(puntos[i], puntos[i + 1], COLOR_VACIO, 24.0, true)
		if flujo.has(id):
			_dibujar_agua(puntos, flujo[id])


## El agua avanza por el tubo según `_avance` (0 a 1).
func _dibujar_agua(puntos: Array, color: Color) -> void:
	var largo := 0.0
	for i in puntos.size() - 1:
		largo += (puntos[i] as Vector2).distance_to(puntos[i + 1])
	var falta := largo * _avance
	for i in puntos.size() - 1:
		var p0: Vector2 = puntos[i]
		var p1: Vector2 = puntos[i + 1]
		var tramo := p0.distance_to(p1)
		if falta <= 0.0:
			return
		var fin := p0.lerp(p1, minf(falta / tramo, 1.0))
		diagrama.draw_line(p0, fin, color, 16.0, true)
		falta -= tramo

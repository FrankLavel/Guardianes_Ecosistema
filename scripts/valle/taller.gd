class_name Taller
extends ZonaInteraccion
## Un taller de la granja en el valle (molino, quesería o colmena; ver Granja). Con E se recoge lo
## que está listo o se abre su panel. Hasta su nivel se ve, pero dice cuándo se abre.

const DIBUJO := "res://assets/maps/valle/objetos/%s.png"

@export var id := "molino"
@export var escala := 0.5

var _reloj := 0.0


func _ready() -> void:
	var ancho := 150.0
	var ruta := DIBUJO % id
	if ResourceLoader.exists(ruta):
		var textura: Texture2D = load(ruta)
		var dibujo := Sprite2D.new()
		dibujo.texture = textura
		dibujo.scale = Vector2.ONE * escala
		dibujo.offset = Vector2(0, -textura.get_height() / 2.0 + 20)
		add_child(dibujo)
		ancho = textura.get_width() * escala * 0.8
	# El edificio no se atraviesa.
	var cuerpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ancho, 50)
	forma.shape = rect
	forma.position = Vector2(0, -30)
	cuerpo.add_child(forma)
	add_child(cuerpo)
	super()
	actualizar()
	Granja.talleres_cambio.connect(actualizar)


## El aviso dice cuánto falta mientras trabaja.
func _process(delta: float) -> void:
	_reloj += delta
	if _reloj >= 1.0:
		_reloj = 0.0
		actualizar()


func actualizar() -> void:
	var dato: Dictionary = Granja.datos["talleres"][id]
	var t := Granja.taller(id)
	var texto: String = "E  " + dato["nombre"]
	if not Granja.taller_abierto(id):
		texto = "%s · nivel %d" % [dato["nombre"], int(dato["nivel"])]
	elif int(t["listo"]) > 0:
		texto = "E  Recoger"
	elif t["trabajando"]:
		texto = "%s · %d min" % [dato["nombre"], Granja.minutos_taller(id)]
	_aviso.text = texto


func _al_interactuar(_jugador: Node2D) -> void:
	var fila := 0
	var recogido := Granja.recoger_taller(id)
	for producto in recogido:
		Granja.mostrar_recogida(producto, int(recogido[producto]), global_position + Vector2(0, -60), fila)
		fila += 1
	if recogido.is_empty():
		Granja.abrir_taller(id)
	actualizar()

class_name Frutal
extends ZonaInteraccion
## Árbol frutal de la granja (ver Granja.frutales): crece de arbolito a árbol y luego da fruta cada
## tanto. Con E se cosecha o se le echa abono (crece el doble de rápido). Se mueve en el modo decorar.

const DIBUJO := "res://assets/objects/frutales/%s_%d.png"
## Mientras no haya arte propio se usa el encino del valle, más chico en cada etapa.
const PROVISIONAL := preload("res://assets/maps/valle/objetos/encino.png")
const ALTO := [70.0, 130.0, 190.0, 190.0]
const COLOR_FRUTA := {"aguacate": Color(0.32, 0.2, 0.1), "guayaba": Color(1.0, 0.8, 0.45), "limon": Color(1.0, 0.95, 0.3)}

## Lo guardado en Juego.frutales ({"id", "x", "y", "etapa", "horas", "abonado"}).
var puesta: Dictionary = {}
var id := "aguacate"

var _dibujo: Sprite2D
var _reloj := 0.0
var _etapa := -1


func _ready() -> void:
	add_to_group(&"movible")
	_dibujo = Sprite2D.new()
	add_child(_dibujo)
	# El tronco no se atraviesa.
	var cuerpo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, 16)
	forma.shape = rect
	forma.position = Vector2(0, -6)
	cuerpo.add_child(forma)
	add_child(cuerpo)
	super()
	actualizar()
	Granja.frutales_cambio.connect(actualizar)


func _process(delta: float) -> void:
	_reloj += delta
	if _reloj >= 1.0:
		_reloj = 0.0
		actualizar()


func etapa() -> int:
	return int(puesta.get("etapa", 0))


func actualizar() -> void:
	if puesta.is_empty():
		_poner_dibujo(0)
		return
	if etapa() != _etapa:
		var antes := _etapa
		_poner_dibujo(etapa())
		if antes >= 0 and etapa() > antes:
			_brotar()
		_etapa = etapa()
	var dato: Dictionary = Granja.datos["frutales"][id]
	var texto := "%s · %d min" % [dato["nombre"], Granja.minutos_frutal(puesta)]
	if etapa() >= Granja.CON_FRUTA:
		texto = "E  Cosechar"
	elif Granja.puede_abonar_frutal(puesta):
		texto = "E  Abonar · %d min" % Granja.minutos_frutal(puesta)
	_aviso.text = texto
	queue_redraw()


func _poner_dibujo(n: int) -> void:
	var ruta := DIBUJO % [id, n]
	_dibujo.texture = load(ruta) if ResourceLoader.exists(ruta) else PROVISIONAL
	_dibujo.scale = Vector2.ONE * ALTO[n] / _dibujo.texture.get_height()
	_dibujo.offset = Vector2(0, -_dibujo.texture.get_height() / 2.0)
	_dibujo.modulate = Color(0.9, 1.05, 0.85) if _dibujo.texture == PROVISIONAL else Color.WHITE


## Con el dibujo provisional, la fruta se pinta encima como bolitas.
func _draw() -> void:
	if puesta.is_empty() or etapa() < Granja.CON_FRUTA or _dibujo.texture != PROVISIONAL:
		return
	var color: Color = COLOR_FRUTA.get(id, Color.ORANGE)
	for k in 7:
		var p := Vector2(cos(k * 2.4) * 48.0, -120.0 + sin(k * 1.7) * 30.0)
		draw_circle(p, 11.0, Color(0.1, 0.07, 0.04))
		draw_circle(p, 9.0, color)
		draw_circle(p + Vector2(-3, -3), 3.0, color.lightened(0.5))


func _brotar() -> void:
	var final := _dibujo.scale
	_dibujo.scale = final * Vector2(1.15, 0.75)
	var rebote := create_tween()
	rebote.tween_property(_dibujo, "scale", final, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Lo que ocupa en el piso: alrededor del tronco.
func huella() -> Rect2:
	return Rect2(global_position + Vector2(-40, -22), Vector2(80, 34))


func contiene(punto: Vector2) -> bool:
	var tam := _dibujo.texture.get_size() * _dibujo.scale
	return Rect2(global_position + Vector2(-tam.x / 2.0, -tam.y), tam).has_point(punto)


func _al_interactuar(_jugador: Node2D) -> void:
	if etapa() >= Granja.CON_FRUTA:
		var fruta := Granja.cosechar_frutal(puesta)
		for producto in fruta:
			Granja.mostrar_recogida(producto, int(fruta[producto]), global_position + Vector2(0, -120))
	elif Granja.abonar_frutal(puesta):
		_brotar()
		Granja.avisar_logro("abono", "¡Le echaste abono! Crece el doble de rápido.")
	elif etapa() < Granja.ADULTO:
		Granja.avisar_logro(id, "Está creciendo: faltan unos %d min. El abono lo acelera." % Granja.minutos_frutal(puesta))
	else:
		Granja.avisar_logro(id, "Dará fruta en unos %d min." % Granja.minutos_frutal(puesta))
	actualizar()

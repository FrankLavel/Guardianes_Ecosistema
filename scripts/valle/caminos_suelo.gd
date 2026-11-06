class_name CaminosSuelo
extends Node2D
## Caminos que el jugador pinta en la granja (ver Granja.poner_camino), solo en horizontal y vertical:
## cada fila o columna de cuadritos seguidos se dibuja como un tramo recto con la textura del camino
## del valle (la de tierra o la de piedra). Va debajo de todo (no entra al orden por altura).

const TEXTURA := {
	"arena": preload("res://assets/maps/valle/texturas/camino.png"),
	"piedra": preload("res://assets/maps/valle/texturas/camino_piedra.png"),
}
## Más ancho que el cuadrito: las orillas de la textura se desvanecen en el pasto.
const ANCHO := 72.0


func _ready() -> void:
	Granja.caminos_cambio.connect(dibujar)
	dibujar()


func dibujar() -> void:
	for hijo in get_children():
		hijo.queue_free()
	for tipo in TEXTURA:
		var celdas := {}
		for clave in Juego.caminos:
			if Juego.caminos[clave] == tipo:
				var p: PackedStringArray = clave.split(",")
				celdas[Vector2i(int(p[0]), int(p[1]))] = true
		for tramo in tramos(celdas):
			_linea(tramo[0], tramo[1], TEXTURA[tipo])


## Los tramos rectos ([desde, hasta] en cuadritos) que cubren todas las celdas: las filas y columnas de
## dos o más seguidas, y cada celda suelta como un tramo de una.
static func tramos(celdas: Dictionary) -> Array:
	var lista := []
	var cubiertas := {}
	for eje: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
		for celda: Vector2i in celdas:
			if celdas.has(celda - eje):
				continue
			var fin := celda
			while celdas.has(fin + eje):
				fin += eje
			if fin != celda:
				lista.append([celda, fin])
				var c := celda
				while true:
					cubiertas[c] = true
					if c == fin:
						break
					c += eje
	for celda: Vector2i in celdas:
		if not cubiertas.has(celda):
			lista.append([celda, celda])
	return lista


func _linea(desde: Vector2i, hasta: Vector2i, textura: Texture2D) -> void:
	var lado := Granja.CELDA_CAMINO
	var a := (Vector2(desde) + Vector2(0.5, 0.5)) * lado
	var b := (Vector2(hasta) + Vector2(0.5, 0.5)) * lado
	# Una celda suelta: un tramo cortito (las puntas redondas la completan).
	if a == b:
		a.x -= lado * 0.25
		b.x += lado * 0.25
	var linea := Line2D.new()
	linea.points = PackedVector2Array([a, b])
	linea.width = ANCHO
	linea.texture = textura
	linea.texture_mode = Line2D.LINE_TEXTURE_TILE
	linea.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	linea.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linea.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(linea)

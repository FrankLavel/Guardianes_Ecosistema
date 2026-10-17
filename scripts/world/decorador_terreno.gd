class_name DecoradorTerreno
extends Node2D
## Dibuja el terreno con el arte final encima de un TileMapLayer que solo se usa para colisiones.
##
## Lee las celdas del TileMapLayer y arma tiras de suelo (pasto + tierra) y plataformas de
## troncos con NinePatchRect. Así el nivel se diseña con tiles simples y se ve con arte pintado.

## Atlas del tileset de colisiones (assets/tilesets/terreno.tres).
const TILE_PASTO := Vector2i(0, 0)
const TILE_TIERRA := Vector2i(1, 0)
const TILE_PLATAFORMA := Vector2i(2, 0)

@export var terreno: TileMapLayer
## Escala del arte respecto al mundo (igual que la de Gara para que todo combine).
@export var escala_arte := 0.34
@export var textura_suelo: Texture2D
## Ancho (px de la textura) de los bordes izquierdo/derecho del suelo que no se repiten.
@export var borde_suelo := 70
## Alto (px de la textura) del pasto, que no se estira.
@export var alto_pasto := 195
@export var textura_plataforma: Texture2D
@export var borde_plataforma := 34
## El pasto sobresale un poco por encima de la colisión para que se vea natural.
@export var sobresale_pasto := 8.0
@export var ocultar_tiles := true


func _ready() -> void:
	if terreno == null:
		return
	if ocultar_tiles:
		# Transparente pero activo: las colisiones siguen funcionando.
		terreno.self_modulate = Color(1, 1, 1, 0)
	construir()


func construir() -> void:
	for hijo in get_children():
		hijo.queue_free()
	var tam := Vector2(terreno.tile_set.tile_size) * terreno.scale
	var limites := terreno.get_used_rect()
	var fondo_y := float(limites.end.y) * tam.y

	for tramo in tramos(TILE_PASTO):
		var fila: int = tramo.y
		var x0: float = tramo.x * tam.x
		var ancho: float = (tramo.z - tramo.x + 1) * tam.x
		var arriba := fila * tam.y - sobresale_pasto
		_agregar_parche(textura_suelo, Rect2(x0, arriba, ancho, fondo_y - arriba + 4.0), borde_suelo, alto_pasto, 40)

	# Paredes: columnas de tierra sin pasto encima (bordes del nivel).
	for columna in columnas_de_tierra():
		var rect := Rect2(columna.x * tam.x, columna.y * tam.y - sobresale_pasto, tam.x, fondo_y - columna.y * tam.y + sobresale_pasto)
		_agregar_parche(textura_suelo, rect, 0, alto_pasto, 40)

	for tramo in tramos(TILE_PLATAFORMA):
		var alto_tronco := textura_plataforma.get_height() * escala_arte
		var rect := Rect2(tramo.x * tam.x - 4.0, tramo.y * tam.y - 4.0, (tramo.z - tramo.x + 1) * tam.x + 8.0, alto_tronco)
		_agregar_parche(textura_plataforma, rect, borde_plataforma, 0, 0)


## Tramos horizontales de celdas de un tipo: Vector3i(x_inicio, fila, x_fin).
func tramos(tipo: Vector2i) -> Array[Vector3i]:
	var por_fila := {}
	for celda in terreno.get_used_cells():
		if terreno.get_cell_atlas_coords(celda) == tipo:
			por_fila.get_or_add(celda.y, []).append(celda.x)
	var lista: Array[Vector3i] = []
	for fila in por_fila:
		var xs: Array = por_fila[fila]
		xs.sort()
		var inicio: int = xs[0]
		var anterior: int = xs[0]
		for x in xs.slice(1):
			if x != anterior + 1:
				lista.append(Vector3i(inicio, fila, anterior))
				inicio = x
			anterior = x
		lista.append(Vector3i(inicio, fila, anterior))
	return lista


## Columnas de tierra cuya celda de arriba está vacía y que no están bajo pasto: Vector2i(x, fila_superior).
func columnas_de_tierra() -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for celda in terreno.get_used_cells():
		if terreno.get_cell_atlas_coords(celda) != TILE_TIERRA:
			continue
		if terreno.get_cell_source_id(celda + Vector2i.UP) == -1:
			lista.append(celda)
	return lista


func _agregar_parche(textura: Texture2D, rect_mundo: Rect2, borde: int, alto_fijo_arriba: int, alto_fijo_abajo: int) -> void:
	var parche := NinePatchRect.new()
	parche.texture = textura
	parche.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parche.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parche.patch_margin_left = borde
	parche.patch_margin_right = borde
	parche.patch_margin_top = alto_fijo_arriba
	parche.patch_margin_bottom = alto_fijo_abajo
	parche.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	parche.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	parche.position = rect_mundo.position
	parche.scale = Vector2(escala_arte, escala_arte)
	parche.size = rect_mundo.size / escala_arte
	add_child(parche)

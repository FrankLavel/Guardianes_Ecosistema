extends Node2D
## Nivel 1: ajusta la cámara y el límite de caída del guardián al tamaño del terreno.

## Distancia por debajo del terreno a partir de la cual el guardián reaparece.
const MARGEN_CAIDA := 200.0

@onready var terreno: TileMapLayer = $Terreno
@onready var guardian: Guardian = $Guardian


func _ready() -> void:
	var limites := obtener_limites_terreno()
	var camara := guardian.camara
	camara.limit_left = int(limites.position.x)
	camara.limit_top = int(limites.position.y) - 400
	camara.limit_right = int(limites.end.x)
	camara.limit_bottom = int(limites.end.y)
	guardian.limite_caida = limites.end.y + MARGEN_CAIDA


## Rectángulo del terreno en coordenadas globales.
func obtener_limites_terreno() -> Rect2:
	var celdas := terreno.get_used_rect()
	var tamano_tile := Vector2(terreno.tile_set.tile_size)
	var inicio := terreno.to_global(Vector2(celdas.position) * tamano_tile)
	return Rect2(inicio, Vector2(celdas.size) * tamano_tile)

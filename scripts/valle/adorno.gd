extends StaticBody2D
## Árbol, arbusto o roca del valle que se puede mover en el modo decorar, dentro de la granja (ver
## Decorador). Se le pone a los adornos de la escena del valle al crear la granja.

## Con qué nombre se guarda dónde quedó (ver Granja.posicion).
var clave: String:
	get:
		return "adorno:" + String(name)


## Lo que ocupa en el piso: su tronco (la forma con la que choca).
func huella() -> Rect2:
	var forma := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma and forma.shape is RectangleShape2D:
		var tam: Vector2 = forma.shape.size
		return Rect2(global_position + forma.position - tam / 2.0, tam).grow(6)
	return Rect2(global_position - Vector2(30, 20), Vector2(60, 30))


## Si el mouse está sobre el dibujo.
func contiene(punto: Vector2) -> bool:
	var dibujo := get_node_or_null("Sprite2D") as Sprite2D
	if dibujo == null or dibujo.texture == null:
		return huella().has_point(punto)
	var tam := dibujo.texture.get_size() * dibujo.scale
	var centro := global_position + dibujo.position + dibujo.offset * dibujo.scale
	return Rect2(centro - tam / 2.0, tam).has_point(punto)

class_name MilpaSuelo
extends Node2D
## Tierra arada de la milpa, pintada con la textura de surcos y fundida con el pasto (ver
## shaders/milpa.gdshader). Va debajo de todo (no entra al orden por altura). Regada se ve más oscura.

const TIERRA := preload("res://assets/maps/valle/texturas/tierra_arada.png")
const SHADER := preload("res://shaders/milpa.gdshader")

## Tamaño de cada cuadro (igual a la separación entre surcos, así quedan pegados).
var tam := Vector2(136, 96)
## Centro de cada cuadro del campo completo, en el mismo orden que las parcelas.
var posiciones: Array[Vector2] = []
var columnas := 4


func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("tierra", TIERRA)
	Granja.parcelas_cambio.connect(queue_redraw)


func _draw() -> void:
	if posiciones.is_empty():
		return
	var filas := ceili(posiciones.size() / float(columnas))
	var origen := posiciones[0] - tam / 2.0
	# Un texel por cuadro y una orilla vacía alrededor, para que el borde se desvanezca.
	var mascara := Image.create(columnas + 2, filas + 2, false, Image.FORMAT_RGBA8)
	for i in posiciones.size():
		var regada := 1.0 if Granja.parcela(i)["regada"] else 0.0
		mascara.set_pixel(i % columnas + 1, i / columnas + 1, Color(1, regada, 0, 1))
	var material_milpa := material as ShaderMaterial
	material_milpa.set_shader_parameter("mascara", ImageTexture.create_from_image(mascara))
	material_milpa.set_shader_parameter("origen", origen)
	material_milpa.set_shader_parameter("tam", tam)
	material_milpa.set_shader_parameter("celdas", Vector2(columnas + 2, filas + 2))
	draw_rect(Rect2(origen - tam, tam * Vector2(columnas + 2, filas + 2)), Color.WHITE)

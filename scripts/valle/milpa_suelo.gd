class_name MilpaSuelo
extends Node2D
## Tierra arada de la milpa, pintada con la textura de surcos y fundida con el pasto (ver
## shaders/milpa.gdshader), en los cuadros que puso el jugador (Granja.celdas_milpa). Va debajo de
## todo (no entra al orden por altura). Regada se ve más oscura.

const TIERRA := preload("res://assets/maps/valle/texturas/tierra_arada.png")
const SHADER := preload("res://shaders/milpa.gdshader")


func _ready() -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("tierra", TIERRA)
	Granja.parcelas_cambio.connect(queue_redraw)
	Granja.milpa_cambio.connect(queue_redraw)


func _draw() -> void:
	var celdas := Granja.celdas_milpa()
	if celdas.is_empty():
		return
	var tam := Granja.CELDA_MILPA
	var menor := celdas[0]
	var mayor := celdas[0]
	for c in celdas:
		menor = Vector2i(mini(menor.x, c.x), mini(menor.y, c.y))
		mayor = Vector2i(maxi(mayor.x, c.x), maxi(mayor.y, c.y))
	var ancho := mayor - menor + Vector2i.ONE
	var origen := Granja.ORIGEN_MILPA + Vector2(menor) * tam
	# Un texel por cuadro y una orilla vacía alrededor, para que el borde se desvanezca.
	var mascara := Image.create(ancho.x + 2, ancho.y + 2, false, Image.FORMAT_RGBA8)
	for i in celdas.size():
		var regada := 1.0 if Granja.parcela(i)["regada"] else 0.0
		var c := celdas[i] - menor + Vector2i.ONE
		mascara.set_pixel(c.x, c.y, Color(1, regada, 0, 1))
	var material_milpa := material as ShaderMaterial
	material_milpa.set_shader_parameter("mascara", ImageTexture.create_from_image(mascara))
	material_milpa.set_shader_parameter("origen", origen)
	material_milpa.set_shader_parameter("tam", tam)
	material_milpa.set_shader_parameter("celdas", Vector2(ancho + Vector2i(2, 2)))
	draw_rect(Rect2(origen - tam, tam * Vector2(ancho + Vector2i(2, 2))), Color.WHITE)

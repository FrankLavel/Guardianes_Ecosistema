extends Control

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_NIVEL1 := "res://scenes/world/Nivel1.tscn"
const ESCENA_OPCIONES := "res://scenes/ui/Opciones.tscn"
const ESCENA_SELECCION := "res://scenes/menu/SeleccionPersonaje.tscn"

@onready var _boton_continuar: Button = %BtnContinuar
@onready var _boton_nueva: Button = %BtnJugar
@onready var _logo: TextureRect = %Logo


func _ready() -> void:
	Sonido.musica("valle")
	_boton_continuar.visible = Juego.existe_partida()
	(_boton_continuar if _boton_continuar.visible else _boton_nueva).grab_focus()
	# En pantallas más anchas que 16:9 (celulares) las montañas y los árboles crecen con el ancho, sin
	# recortarse: si no, se ve el corte de arriba de las montañas.
	get_viewport().size_changed.connect(_acomodar_fondo)
	_acomodar_fondo()
	# El logo "respira" un poco para que el menú no se sienta estático.
	var animacion := create_tween().set_loops()
	animacion.tween_property(_logo, "scale", Vector2(1.03, 1.03), 1.6).set_trans(Tween.TRANS_SINE)
	animacion.tween_property(_logo, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)


func _acomodar_fondo() -> void:
	var ancho := get_viewport_rect().size.x
	for capa: TextureRect in [$Montanas, $Arboles]:
		var alto := ancho * capa.texture.get_height() / capa.texture.get_width()
		# Nunca más bajito que en 16:9 (ahí ya se veía bien).
		capa.offset_top = capa.offset_bottom - maxf(alto, 640.0 if capa == $Montanas else 560.0)


func _on_btn_continuar_pressed() -> void:
	if Juego.cargar():
		Transicion.ir_a(ESCENA_VALLE)


func _on_btn_jugar_pressed() -> void:
	# Primero se elige niño o niña y el nombre; ahí se crea la partida. Si ya hay una partida, antes se
	# pregunta: empezar otra borra el progreso.
	if Juego.existe_partida():
		_confirmar_nueva()
	else:
		Transicion.ir_a(ESCENA_SELECCION)


var _confirmacion: Control


## Aviso con dos botones encima del menú: "NO, REGRESAR" y "SÍ, EMPEZAR DE NUEVO".
func _confirmar_nueva() -> void:
	if _confirmacion:
		return
	_confirmacion = ColorRect.new()
	_confirmacion.color = Color(0, 0, 0, 0.6)
	_confirmacion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_confirmacion)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirmacion.add_child(centro)
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.14, 0.08, 0.97)
	estilo.border_color = Color(0.55, 0.38, 0.18)
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(14)
	estilo.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 22)
	panel.add_child(columna)
	for linea in [["¿Empezar una partida nueva?", 40, Color(0.99, 0.86, 0.45)],
			["Ya tienes una partida guardada. Si empiezas otra,
se borrará todo tu progreso.", 28, Color(1, 0.96, 0.86)]]:
		var texto := Label.new()
		texto.text = linea[0]
		texto.add_theme_font_size_override("font_size", linea[1])
		texto.add_theme_color_override("font_color", linea[2])
		texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		columna.add_child(texto)
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 24)
	columna.add_child(botones)
	var no := Button.new()
	no.name = "BtnNo"
	no.text = "NO, REGRESAR"
	no.custom_minimum_size = Vector2(300, 64)
	no.pressed.connect(func():
		_confirmacion.queue_free()
		_confirmacion = null
		_boton_nueva.grab_focus())
	botones.add_child(no)
	var si := Button.new()
	si.name = "BtnSi"
	si.text = "SÍ, EMPEZAR DE NUEVO"
	si.custom_minimum_size = Vector2(360, 64)
	si.pressed.connect(func(): Transicion.ir_a(ESCENA_SELECCION))
	botones.add_child(si)
	# Lo seguro va primero: con Enter o E se regresa.
	no.grab_focus()


func _on_btn_opciones_pressed() -> void:
	Transicion.ir_a(ESCENA_OPCIONES)


func _on_btn_salir_pressed() -> void:
	get_tree().quit()

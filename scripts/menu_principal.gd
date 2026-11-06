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
	# Primero se elige niño o niña y el nombre; ahí se crea la partida.
	Transicion.ir_a(ESCENA_SELECCION)


func _on_btn_opciones_pressed() -> void:
	Transicion.ir_a(ESCENA_OPCIONES)


func _on_btn_salir_pressed() -> void:
	get_tree().quit()

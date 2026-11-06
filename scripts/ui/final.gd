extends Control
## Final del juego: "El corazón del valle". Resume lo aprendido, muestra cuántas especies se
## descubrieron y pasa los créditos. Desde aquí se puede seguir explorando el valle.

const ESCENA_VALLE := "res://scenes/valle/Valle.tscn"
const ESCENA_MENU := "res://scenes/menu/menu_principal.tscn"
const RUTA_CREDITOS := "res://data/creditos.txt"
## Segundos que tardan los créditos en pasar de abajo hacia arriba.
const DURACION_CREDITOS := 40.0

@onready var _titulo: Label = %Titulo
@onready var _mensaje: Label = %Mensaje
@onready var _especies: Label = %Especies
@onready var _resumen: Control = %Resumen
@onready var _creditos: Control = %Creditos
@onready var _texto_creditos: Label = %TextoCreditos
@onready var _boton_creditos: Button = %BtnCreditos


func _ready() -> void:
	Sonido.musica("valle")
	Juego.marcar("final_visto")
	Juego.guardar()
	_titulo.text = Juego.reemplazar("¡Gracias, {nombre}!")
	_mensaje.text = Juego.reemplazar(_mensaje.text)
	_especies.text = "Especies en tu bitácora: %d de %d" % [Bitacora.descubiertas(), Bitacora.total()]
	_texto_creditos.text = FileAccess.get_file_as_string(RUTA_CREDITOS)
	_creditos.visible = false
	_boton_creditos.pressed.connect(mostrar_creditos)
	%BtnValle.pressed.connect(func(): Transicion.ir_a(ESCENA_VALLE))
	%BtnMenu.pressed.connect(func(): Transicion.ir_a(ESCENA_MENU))
	%BtnSaltar.pressed.connect(_terminar_creditos)
	# Entrada suave del resumen.
	_resumen.modulate.a = 0.0
	create_tween().tween_property(_resumen, "modulate:a", 1.0, 1.2)
	_boton_creditos.grab_focus()


func mostrar_creditos() -> void:
	_resumen.visible = false
	_creditos.visible = true
	%BtnSaltar.grab_focus()
	await get_tree().process_frame
	var alto_pantalla := _creditos.size.y
	_texto_creditos.position.y = alto_pantalla
	var recorrido := create_tween()
	recorrido.tween_property(_texto_creditos, "position:y", -_texto_creditos.size.y, DURACION_CREDITOS)
	recorrido.finished.connect(_terminar_creditos)


func _terminar_creditos() -> void:
	if not _creditos.visible:
		return
	_creditos.visible = false
	_resumen.visible = true
	_boton_creditos.grab_focus()

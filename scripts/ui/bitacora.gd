extends CanvasLayer
## Bitácora de especies (autoload "Bitacora").
##
##     Bitacora.descubrir("garza")   # muestra un aviso y la guarda en la partida
##
## Se abre con Tab (o Select en el control) mientras se juega en el valle o en una zona.
## Los datos de cada especie están en data/especies.json; las imágenes en assets/ui/bitacora/.

signal especie_descubierta(id: String)

const RUTA_DATOS := "res://data/especies.json"
const RUTA_IMAGEN := "res://assets/ui/bitacora/%s.png"
const ZONAS := {"rio": "Río", "bosque": "Bosque", "lago": "Lago"}
const ESTADOS := {
	"seguro": ["Sin peligro", Color(0.55, 0.85, 0.45)],
	"cuidado": ["Necesita cuidado", Color(0.98, 0.8, 0.35)],
	"peligro": ["En peligro", Color(1.0, 0.5, 0.42)],
}

var especies: Dictionary = {}
var abierta := false
var zona_actual := "rio"
var seleccionada := ""

@onready var _libro: Control = %Libro
@onready var _rejilla: GridContainer = %Rejilla
@onready var _contador: Label = %Contador
@onready var _pestanas := {"rio": %PestanaRio, "bosque": %PestanaBosque, "lago": %PestanaLago}
@onready var _imagen: TextureRect = %ImagenGrande
@onready var _nombre: Label = %NombreEspecie
@onready var _cientifico: Label = %Cientifico
@onready var _estado: Label = %Estado
@onready var _dato: Label = %Dato
@onready var _aviso: PanelContainer = %Aviso
@onready var _aviso_imagen: TextureRect = %AvisoImagen
@onready var _aviso_nombre: Label = %AvisoNombre

var _animacion_aviso: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	especies = JSON.parse_string(FileAccess.get_file_as_string(RUTA_DATOS))
	_libro.visible = false
	_aviso.visible = false
	for zona in _pestanas:
		_pestanas[zona].pressed.connect(mostrar_zona.bind(zona))
	%BtnCerrarBitacora.pressed.connect(cerrar)


func total() -> int:
	return especies.size()


func descubiertas() -> int:
	return especies.keys().filter(func(id): return id in Juego.especies_descubiertas).size()


## Registra una especie. Devuelve true si era nueva.
func descubrir(id: String) -> bool:
	if not especies.has(id):
		push_error("Especie desconocida: %s" % id)
		return false
	if id in Juego.especies_descubiertas:
		return false
	Juego.descubrir_especie(id)
	especie_descubierta.emit(id)
	_mostrar_aviso(id)
	return true


func imagen_de(id: String) -> Texture2D:
	var ruta := RUTA_IMAGEN % id
	return load(ruta) if ResourceLoader.exists(ruta) else null


# ------------------------------------------------------------------ libro

## Solo se abre mientras se juega (el valle y las zonas están en el grupo "jugable").
func se_puede_abrir() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.is_in_group(&"jugable") \
		and not Dialogo.activo and not Transicion.en_curso and not get_tree().paused


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("bitacora"):
		if abierta:
			cerrar()
		elif se_puede_abrir():
			abrir()
		else:
			return
		get_viewport().set_input_as_handled()
	elif abierta and evento.is_action_pressed("pausa"):
		cerrar()
		get_viewport().set_input_as_handled()


func abrir(zona := "") -> void:
	abierta = true
	_libro.visible = true
	get_tree().paused = true
	Juego.entrada_bloqueada = true
	Sonido.efecto("boton")
	mostrar_zona(zona if zona != "" else zona_actual)


func cerrar() -> void:
	if not abierta:
		return
	abierta = false
	_libro.visible = false
	get_tree().paused = false
	await get_tree().process_frame
	Juego.entrada_bloqueada = false


func mostrar_zona(zona: String) -> void:
	zona_actual = zona
	for z in _pestanas:
		_pestanas[z].button_pressed = z == zona
	for hijo in _rejilla.get_children():
		hijo.queue_free()
	var primera := ""
	for id in especies:
		if especies[id]["zona"] != zona:
			continue
		var tarjeta := _crear_tarjeta(id)
		_rejilla.add_child(tarjeta)
		if primera == "":
			primera = id
			tarjeta.call_deferred("grab_focus")
	_contador.text = "Especies descubiertas: %d / %d" % [descubiertas(), total()]
	mostrar_especie(primera)


func _crear_tarjeta(id: String) -> Button:
	var conocida: bool = id in Juego.especies_descubiertas
	var tarjeta := Button.new()
	tarjeta.custom_minimum_size = Vector2(132, 132)
	tarjeta.expand_icon = true
	tarjeta.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for estilo in ["normal", "hover", "pressed", "focus"]:
		tarjeta.add_theme_stylebox_override(estilo, _estilo_tarjeta(estilo != "normal"))
	var imagen := imagen_de(id)
	if imagen:
		tarjeta.icon = imagen
		if not conocida:
			# Las no descubiertas se ven como silueta oscura.
			for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
				tarjeta.add_theme_color_override(c, Color(0.12, 0.1, 0.08, 0.9))
	else:
		# Todavía no hay dibujo de esta especie.
		tarjeta.text = "?"
		tarjeta.add_theme_font_size_override("font_size", 64)
	if not conocida:
		tarjeta.tooltip_text = "Aún no la descubres"
	tarjeta.focus_entered.connect(mostrar_especie.bind(id))
	tarjeta.pressed.connect(mostrar_especie.bind(id))
	return tarjeta


func _estilo_tarjeta(resaltada: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.96, 0.9, 0.74) if resaltada else Color(0.9, 0.82, 0.64)
	estilo.border_color = Color(0.99, 0.75, 0.25) if resaltada else Color(0.45, 0.3, 0.16)
	estilo.set_border_width_all(6 if resaltada else 3)
	estilo.set_corner_radius_all(14)
	estilo.set_content_margin_all(10)
	return estilo


func mostrar_especie(id: String) -> void:
	seleccionada = id
	if id == "":
		return
	var datos: Dictionary = especies[id]
	var conocida: bool = id in Juego.especies_descubiertas
	_imagen.texture = imagen_de(id) if conocida else null
	_nombre.text = datos["nombre"] if conocida else "???"
	_cientifico.text = datos["cientifico"] if conocida else ""
	var estado: Array = ESTADOS[datos["estado"]]
	_estado.text = estado[0] if conocida else ""
	_estado.modulate = estado[1]
	_dato.text = datos["dato"] if conocida else "Sigue explorando y ayudando al ecosistema para descubrir esta especie."


# ------------------------------------------------------------------ aviso

func _mostrar_aviso(id: String) -> void:
	_aviso_imagen.texture = imagen_de(id)
	_aviso_nombre.text = especies[id]["nombre"]
	_aviso.visible = true
	_aviso.modulate.a = 0.0
	Sonido.efecto("punto_control")
	if _animacion_aviso:
		_animacion_aviso.kill()
	# El aviso sigue su curso aunque el juego esté en pausa (por ejemplo, dentro de un puzzle).
	_animacion_aviso = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animacion_aviso.tween_property(_aviso, "modulate:a", 1.0, 0.25)
	_animacion_aviso.tween_interval(3.0)
	_animacion_aviso.tween_property(_aviso, "modulate:a", 0.0, 0.5)
	_animacion_aviso.tween_callback(_aviso.hide)

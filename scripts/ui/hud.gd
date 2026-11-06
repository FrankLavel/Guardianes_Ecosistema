class_name HUD
extends CanvasLayer
## Interfaz del nivel: salud del ecosistema, avance, mensajes educativos y ayuda de controles.

## Textos de cada zona (el río usa los de por defecto).
@export var titulo_salud := "Salud del río"
@export var formato_contador := "Basura recogida: %d / %d"

@onready var barra_salud: ProgressBar = %BarraSalud
@onready var etiqueta_basura: Label = %EtiquetaBasura
@onready var _mensaje: PanelContainer = %Mensaje
@onready var _titulo_mensaje: Label = %TituloMensaje
@onready var _texto_mensaje: Label = %TextoMensaje

var _animacion_mensaje: Tween


func _ready() -> void:
	_mensaje.visible = false
	%EtiquetaSalud.text = titulo_salud


func actualizar(recogidas: int, total: int, salud := -1.0) -> void:
	if salud < 0.0:
		salud = 1.0 if total == 0 else float(recogidas) / total
	var animacion := create_tween()
	animacion.tween_property(barra_salud, "value", salud * 100.0, 0.4)
	etiqueta_basura.text = formato_contador % [recogidas, total]


func mostrar_mensaje(titulo: String, texto: String, segundos := 4.0) -> void:
	_titulo_mensaje.text = titulo
	_texto_mensaje.text = texto
	_texto_mensaje.visible = not texto.is_empty()
	_mensaje.visible = true
	_mensaje.modulate.a = 1.0
	if _animacion_mensaje:
		_animacion_mensaje.kill()
	_animacion_mensaje = create_tween()
	_animacion_mensaje.tween_interval(segundos)
	_animacion_mensaje.tween_property(_mensaje, "modulate:a", 0.0, 0.5)
	_animacion_mensaje.tween_callback(_mensaje.hide)


func mensaje_visible() -> String:
	return _titulo_mensaje.text if _mensaje.visible else ""

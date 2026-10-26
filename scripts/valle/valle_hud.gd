extends CanvasLayer
## Interfaz del valle: zonas restauradas y objetivo actual.

@onready var etiqueta_progreso: Label = %Progreso
@onready var etiqueta_objetivo: Label = %Objetivo
@onready var _panel_objetivo: Control = %PanelObjetivo

var _animacion: Tween


func _ready() -> void:
	_panel_objetivo.visible = false


func actualizar_reloj() -> void:
	%Reloj.text = "Día %d · %s" % [Juego.dia, Juego.texto_hora()]


## `hojas` < 0: todavía no se muestran (se ganan después del final).
func actualizar_progreso(restauradas: int, total: int, hojas := -1) -> void:
	etiqueta_progreso.text = "Zonas restauradas: %d / %d" % [restauradas, total]
	if hojas >= 0:
		etiqueta_progreso.text += "   ·   Hojas: %d" % hojas


## `segundos` > 0: el mensaje se desvanece solo después de ese tiempo.
func mostrar_objetivo(texto: String, segundos := 0.0) -> void:
	etiqueta_objetivo.text = texto
	_panel_objetivo.visible = true
	_panel_objetivo.modulate.a = 0.0
	if _animacion:
		_animacion.kill()
	_animacion = create_tween()
	_animacion.tween_property(_panel_objetivo, "modulate:a", 1.0, 0.4)
	if segundos > 0.0:
		_animacion.tween_interval(segundos)
		_animacion.tween_property(_panel_objetivo, "modulate:a", 0.0, 0.6)

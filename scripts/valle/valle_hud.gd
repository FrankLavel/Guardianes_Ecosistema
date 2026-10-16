extends CanvasLayer
## Interfaz del valle: zonas restauradas y objetivo actual.

@onready var etiqueta_progreso: Label = %Progreso
@onready var etiqueta_objetivo: Label = %Objetivo
@onready var _panel_objetivo: Control = %PanelObjetivo


func _ready() -> void:
	_panel_objetivo.visible = false


func actualizar_progreso(restauradas: int, total: int) -> void:
	etiqueta_progreso.text = "Zonas restauradas: %d / %d" % [restauradas, total]


func mostrar_objetivo(texto: String) -> void:
	etiqueta_objetivo.text = texto
	_panel_objetivo.visible = true
	_panel_objetivo.modulate.a = 0.0
	create_tween().tween_property(_panel_objetivo, "modulate:a", 1.0, 0.4)

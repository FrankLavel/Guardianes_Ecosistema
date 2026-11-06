extends GutTest
## Pruebas de la pantalla de opciones (volumen general).

const ESCENA_OPCIONES := preload("res://scenes/ui/Opciones.tscn")

var _opciones: Control
var _volumen_original_db: float


func before_each() -> void:
	_volumen_original_db = AudioServer.get_bus_volume_db(_bus_master())
	_opciones = add_child_autofree(ESCENA_OPCIONES.instantiate())


func after_each() -> void:
	# Las opciones se guardan en disco: se dejan como estaban.
	Sonido.fijar_volumen("Master", db_to_linear(_volumen_original_db))
	Sonido.guardar_opciones()


func _bus_master() -> int:
	return AudioServer.get_bus_index("Master")


func test_volumen_100_deja_el_bus_en_0_db() -> void:
	_opciones._on_slider_volumen_value_changed(100.0)
	assert_almost_eq(AudioServer.get_bus_volume_db(_bus_master()), 0.0, 0.01)


func test_volumen_50_baja_unos_6_db() -> void:
	_opciones._on_slider_volumen_value_changed(50.0)
	assert_almost_eq(AudioServer.get_bus_volume_db(_bus_master()), -6.02, 0.05)


func test_volumen_mas_bajo_es_mas_silencioso() -> void:
	_opciones._on_slider_volumen_value_changed(80.0)
	var alto := AudioServer.get_bus_volume_db(_bus_master())
	_opciones._on_slider_volumen_value_changed(20.0)
	var bajo := AudioServer.get_bus_volume_db(_bus_master())
	assert_lt(bajo, alto)

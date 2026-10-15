extends GutTest
## Nivel1 completo: terreno, guardián, cámara, controles, basura, río y meta.

const ESCENA_NIVEL1 := preload("res://scenes/world/Nivel1.tscn")

var nivel: Node2D


func before_each() -> void:
	nivel = add_child_autofree(ESCENA_NIVEL1.instantiate())


func after_each() -> void:
	# La pantalla final pausa el juego.
	get_tree().paused = false


func _recoger_todo() -> void:
	for basura in nivel.basuras():
		basura.interactuar(nivel.guardian)


func test_controles_definidos_en_el_proyecto() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "saltar", "interactuar"]:
		assert_true(InputMap.has_action(accion), "Falta la acción: %s" % accion)
		assert_gt(InputMap.action_get_events(accion).size(), 0, "Sin teclas: %s" % accion)


func test_tiene_terreno_y_guardian() -> void:
	assert_gt(nivel.terreno.get_used_cells().size(), 100, "El nivel no debería estar vacío")
	assert_not_null(nivel.guardian)


func test_camara_limitada_al_ancho_del_nivel() -> void:
	var limites: Rect2 = nivel.obtener_limites_terreno()
	assert_eq(nivel.guardian.camara.limit_right, int(limites.end.x))
	assert_gt(limites.size.x, 1280.0, "El nivel es más ancho que la pantalla")


func test_guardian_aterriza_sobre_el_terreno() -> void:
	await wait_until(func(): return nivel.guardian.is_on_floor(), 3.0)
	assert_true(nivel.guardian.is_on_floor(), "El guardián debería pisar el suelo del nivel")


func test_empieza_con_el_rio_contaminado() -> void:
	assert_eq(nivel.total_basura(), 8)
	assert_eq(nivel.rios().size(), 2)
	assert_eq(nivel.salud_del_rio(), 0.0)
	for rio in nivel.rios():
		assert_eq(rio.limpieza, 0.0)
		assert_false(rio.hay_peces())


func test_recoger_basura_sube_la_salud_y_muestra_el_dato() -> void:
	var basura: Basura = nivel.basuras()[0]
	basura.interactuar(nivel.guardian)
	assert_almost_eq(nivel.salud_del_rio(), 1.0 / 8.0, 0.001)
	assert_almost_eq(nivel.rios()[0].limpieza, 1.0 / 8.0, 0.001)
	assert_eq(nivel.hud.mensaje_visible(), basura.datos()["nombre"])
	assert_eq(nivel.hud.etiqueta_basura.text, "Basura recogida: 1 / 8")


func test_recoger_todo_limpia_el_rio_y_aparecen_peces() -> void:
	_recoger_todo()
	assert_true(nivel.rio_limpio())
	for rio in nivel.rios():
		assert_eq(rio.limpieza, 1.0)
		assert_true(rio.hay_peces(), "Deberían aparecer peces")
	assert_eq(nivel.hud.mensaje_visible(), "¡El río está limpio!")


func test_meta_sin_limpiar_el_rio_no_termina_el_nivel() -> void:
	nivel._al_llegar_a_meta(nivel.guardian)
	assert_false(nivel.nivel_terminado)
	assert_false(nivel.pantalla_final.visible)
	assert_eq(nivel.hud.mensaje_visible(), "Aún hay basura en el río")


func test_meta_con_el_rio_limpio_completa_el_nivel() -> void:
	_recoger_todo()
	nivel._al_llegar_a_meta(nivel.guardian)
	var pausado := get_tree().paused
	# Quitar la pausa antes de cualquier await: con el árbol pausado GUT también se detiene.
	get_tree().paused = false
	assert_true(nivel.nivel_terminado)
	assert_true(nivel.pantalla_final.visible)
	assert_true(pausado, "La pantalla final debe pausar el juego")


func test_la_meta_detecta_al_guardian() -> void:
	watch_signals(nivel.meta)
	nivel.guardian.global_position = nivel.meta.global_position
	await wait_physics_frames(3)
	get_tree().paused = false
	assert_signal_emitted(nivel.meta, "guardian_llego")


func test_caer_al_rio_hace_reaparecer_al_guardian() -> void:
	var guardian: Guardian = nivel.guardian
	watch_signals(guardian)
	var rio: Rio = nivel.rios()[0]
	guardian.global_position = rio.global_position + Vector2(rio.tamano.x / 2.0, -20.0)
	await wait_for_signal(guardian.reaparecio, 3.0)
	assert_signal_emitted(guardian, "reaparecio")
	assert_eq(nivel.hud.mensaje_visible(), "¡Cuidado!")


func test_los_datos_educativos_se_incluyen_en_la_exportacion() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	for seccion in ["preset.0", "preset.1"]:
		assert_string_contains(presets.get_value(seccion, "include_filter"), "data/*.json")

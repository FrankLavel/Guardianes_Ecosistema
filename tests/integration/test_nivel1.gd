extends GutTest
## Nivel1 completo: terreno, guardián, cámara y controles configurados.

const ESCENA_NIVEL1 := preload("res://scenes/world/Nivel1.tscn")

var nivel: Node2D


func before_each() -> void:
	nivel = add_child_autofree(ESCENA_NIVEL1.instantiate())


func test_controles_definidos_en_el_proyecto() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "saltar"]:
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

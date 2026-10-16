extends GutTest
## Estado de la partida: desbloqueo de zonas y guardado/carga (CP-09, CP-10).

const RANURA := 98


func before_each() -> void:
	Juego.nueva_partida(RANURA)


func after_each() -> void:
	Juego.borrar_partida(RANURA)


func test_solo_el_rio_empieza_desbloqueado() -> void:
	assert_true(Juego.zona_desbloqueada("rio"))
	assert_false(Juego.zona_desbloqueada("bosque"))
	assert_false(Juego.zona_desbloqueada("lago"))


func test_completar_una_zona_desbloquea_la_siguiente() -> void:
	watch_signals(Juego)
	Juego.completar_zona("rio")
	assert_signal_emitted_with_parameters(Juego, "zona_completada", ["rio"])
	assert_true(Juego.zona_desbloqueada("bosque"))
	assert_false(Juego.zona_desbloqueada("lago"))
	assert_almost_eq(Juego.progreso(), 1.0 / 3.0, 0.001)


func test_completar_dos_veces_no_duplica() -> void:
	Juego.completar_zona("rio")
	Juego.completar_zona("rio")
	assert_eq(Juego.zonas_completadas.size(), 1)


func test_guardar_y_cargar_recupera_el_progreso() -> void:
	Juego.completar_zona("rio")
	Juego.marcar_dialogo_visto("don_chucho_inicio")
	Juego.posicion_valle = Vector2(123, 456)
	Juego.tiene_posicion_valle = true
	assert_true(Juego.guardar())
	assert_true(Juego.existe_partida(RANURA))

	Juego.nueva_partida(RANURA)
	assert_eq(Juego.zonas_completadas.size(), 0)
	assert_true(Juego.cargar(RANURA))
	assert_eq(Juego.zonas_completadas, ["rio"] as Array[String])
	assert_has(Juego.dialogos_vistos, "don_chucho_inicio")
	assert_eq(Juego.posicion_valle, Vector2(123, 456))


func test_cargar_una_ranura_vacia_falla_sin_romper() -> void:
	assert_false(Juego.cargar(97))

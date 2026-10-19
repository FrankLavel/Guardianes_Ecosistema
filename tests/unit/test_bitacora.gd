extends GutTest
## Bitácora de especies.

const RANURA := 95


func before_each() -> void:
	Juego.nueva_partida(RANURA)


func after_each() -> void:
	if Bitacora.abierta:
		Bitacora.cerrar()
	get_tree().paused = false
	Juego.entrada_bloqueada = false
	Juego.borrar_partida(RANURA)
	Juego.nueva_partida()


func test_cada_especie_tiene_sus_datos() -> void:
	assert_gte(Bitacora.total(), 12, "El GDD pide ~15 especies")
	for id in Bitacora.especies:
		var e: Dictionary = Bitacora.especies[id]
		for campo in ["nombre", "cientifico", "zona", "estado", "dato"]:
			assert_ne(str(e.get(campo, "")), "", "%s: falta %s" % [id, campo])
		assert_has(Bitacora.ZONAS, e["zona"], id)
		assert_has(Bitacora.ESTADOS, e["estado"], id)


func test_las_especies_de_rio_y_bosque_tienen_imagen() -> void:
	for id in Bitacora.especies:
		if Bitacora.especies[id]["zona"] in ["rio", "bosque"]:
			assert_not_null(Bitacora.imagen_de(id), "Falta imagen de %s" % id)


func test_descubrir_registra_una_sola_vez() -> void:
	watch_signals(Bitacora)
	assert_true(Bitacora.descubrir("garza"))
	assert_false(Bitacora.descubrir("garza"), "La segunda vez no es nueva")
	assert_signal_emit_count(Bitacora, "especie_descubierta", 1)
	assert_has(Juego.especies_descubiertas, "garza")
	assert_eq(Bitacora.descubiertas(), 1)


func test_abrir_muestra_las_especies_de_la_zona() -> void:
	Bitacora.descubrir("garza")
	Bitacora.abrir("rio")
	get_tree().paused = false
	await wait_process_frames(2)
	var rejilla: GridContainer = Bitacora.get_node("%Rejilla")
	var del_rio := Bitacora.especies.keys().filter(func(id): return Bitacora.especies[id]["zona"] == "rio")
	assert_eq(rejilla.get_child_count(), del_rio.size())
	Bitacora.mostrar_especie("garza")
	assert_eq(Bitacora.get_node("%NombreEspecie").text, "Garza blanca")
	Bitacora.mostrar_especie("acocil")
	assert_eq(Bitacora.get_node("%NombreEspecie").text, "???", "No descubierta: no se revela")


func test_solo_se_abre_mientras_se_juega() -> void:
	assert_false(Bitacora.se_puede_abrir(), "En las pruebas no hay escena jugable")

extends GutTest
## Estado de la partida: desbloqueo de zonas y guardado/carga (CP-09, CP-10).

const RANURA := 98


func before_each() -> void:
	Juego.nueva_partida(RANURA)


func after_each() -> void:
	Juego.borrar_partida(RANURA)


func test_el_guardado_deja_respaldo_y_lo_usa_si_la_partida_se_dana() -> void:
	Juego.nueva_partida(RANURA)
	Juego.dar_hojas(3)
	Juego.guardar()
	Juego.dar_hojas(4)
	Juego.guardar()
	assert_true(FileAccess.file_exists(Juego.ruta_ranura(RANURA) + ".bak"), "Queda la partida anterior")
	assert_false(FileAccess.file_exists(Juego.ruta_ranura(RANURA) + ".tmp"))
	# La app se cerró a medio guardar: el archivo bueno quedó roto.
	var roto := FileAccess.open(Juego.ruta_ranura(RANURA), FileAccess.WRITE)
	roto.store_string("{\"hojas\": 7")
	roto.close()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA), "Se carga el respaldo")
	assert_eq(Juego.hojas, 3)
	Juego.borrar_partida(RANURA)
	assert_false(Juego.existe_partida(RANURA), "Se borran también el respaldo y el temporal")


func test_se_guarda_al_mandar_la_app_a_segundo_plano() -> void:
	Juego.nueva_partida(RANURA)
	Juego.dar_hojas(9)
	Juego.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_eq(Juego.hojas, 9)
	Juego.borrar_partida(RANURA)


func test_el_boton_atras_no_cierra_el_juego() -> void:
	assert_false(ProjectSettings.get_setting("application/config/quit_on_go_back"), "Lo maneja el juego (pausa)")


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


func test_textos_segun_el_personaje() -> void:
	Juego.nueva_partida(RANURA, "nino", "")
	assert_eq(Juego.reemplazar("¡Hola, {muchacho}! Eres {el} {nuevo} {guardian}."), "¡Hola, muchacho! Eres el nuevo guardián.")
	assert_eq(Juego.nombre_jugador(), "Guardián")
	Juego.nueva_partida(RANURA, "nina", "")
	assert_eq(Juego.reemplazar("¡Hola, {muchacho}! Eres {el} {nuevo} {guardian}."), "¡Hola, muchacha! Eres la nueva guardiana.")
	assert_eq(Juego.nombre_jugador(), "Guardiana")


func test_el_nombre_escrito_se_usa_en_los_textos() -> void:
	Juego.nueva_partida(RANURA, "nina", "  Xóchitl ")
	assert_eq(Juego.nombre_jugador(), "Xóchitl")
	assert_eq(Juego.reemplazar("¡Lo lograste, {nombre}!"), "¡Lo lograste, Xóchitl!")


func test_se_guarda_el_personaje_elegido() -> void:
	Juego.nueva_partida(RANURA, "nina", "Xóchitl")
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_eq(Juego.genero, "nino")
	Juego.cargar(RANURA)
	assert_eq(Juego.genero, "nina")
	assert_eq(Juego.nombre, "Xóchitl")


func test_cada_personaje_tiene_su_arte() -> void:
	for clave in Juego.PERSONAJES:
		var datos: Dictionary = Juego.PERSONAJES[clave]
		assert_true(ResourceLoader.exists(datos["aereo"]), "Falta arte aéreo de %s" % clave)
		assert_true(ResourceLoader.exists(datos["retrato"]), "Falta retrato de %s" % clave)
		var cuadros: SpriteFrames = load(datos["aereo"])
		for anim in ["idle_abajo", "idle_arriba", "idle_izquierda", "caminar_abajo", "caminar_arriba", "caminar_izquierda"]:
			assert_true(cuadros.has_animation(anim), "%s: falta %s" % [clave, anim])


func test_cada_personaje_tiene_arte_de_plataformas_completo() -> void:
	for clave in Juego.PERSONAJES:
		var ruta: String = Juego.PERSONAJES[clave]["plataformas"]
		assert_true(ResourceLoader.exists(ruta), "Falta arte de plataformas de %s" % clave)
		var cuadros: SpriteFrames = load(ruta)
		for anim in ["idle", "caminar", "correr", "saltar", "caer", "agachar", "interactuar"]:
			assert_true(cuadros.has_animation(anim), "%s: falta %s" % [clave, anim])
			for i in cuadros.get_frame_count(anim):
				var img := cuadros.get_frame_texture(anim, i).get_image()
				var tocado := false
				for x in img.get_width():
					tocado = tocado or img.get_pixel(x, 0).a > 0.0
				for y in img.get_height():
					tocado = tocado or img.get_pixel(0, y).a > 0.0 or img.get_pixel(img.get_width() - 1, y).a > 0.0
				assert_false(tocado, "%s: cuadro %d de %s está recortado" % [clave, i, anim])

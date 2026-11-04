extends GutTest
## Granja: semillas de las zonas, milpa, corral, pesca responsable, cocina y energía.

const RANURA := 95


func before_each() -> void:
	Juego.nueva_partida(RANURA)


func after_each() -> void:
	Granja.cerrar()
	Juego.entrada_bloqueada = false
	Juego.borrar_partida(RANURA)


func _dia_siguiente() -> void:
	Juego.dia += 1
	Granja.nuevo_dia()


func test_cada_zona_regala_sus_semillas_una_vez() -> void:
	Juego.completar_zona("rio")
	assert_eq(Granja.cantidad("semilla_frijol"), 4)
	Granja.dar_semillas_de("rio")
	assert_eq(Granja.cantidad("semilla_frijol"), 4, "No se regalan dos veces")


func test_la_milpa_crece_en_minutos_si_se_riega() -> void:
	Granja.dar("semilla_maiz")
	assert_true(Granja.plantar(0, "maiz"))
	assert_eq(Granja.cantidad("semilla_maiz"), 0)
	Granja.crecer(20.0)
	assert_eq(int(Granja.parcela(0)["etapa"]), 0, "Sin regar no crece")
	assert_true(Granja.regar(0))
	assert_false(Granja.regar(0), "Solo se riega una vez")
	var horas: float = float(Granja.datos["cultivos"]["maiz"]["horas"])
	assert_eq(Granja.minutos_restantes(0), ceili(horas * Juego.SEGUNDOS_POR_HORA / 60.0))
	Granja.crecer(horas / 2.0)
	assert_between(int(Granja.parcela(0)["etapa"]), 1, Granja.LISTO - 1, "A medio camino va creciendo")
	Granja.crecer(horas / 2.0)
	assert_eq(int(Granja.parcela(0)["etapa"]), Granja.LISTO)
	var cosecha := Granja.cosechar(0)
	assert_eq(int(cosecha["maiz"]), 3)
	assert_eq(Granja.cantidad("semilla_maiz"), 1, "La cosecha devuelve una semilla")
	assert_true(Granja.parcela(0)["cultivo"].is_empty())
	assert_gt(Juego.xp, 0, "Cosechar da experiencia")


func test_sin_semilla_no_se_siembra() -> void:
	assert_false(Granja.plantar(1, "calabaza"))


func test_la_gallina_pone_huevo_al_dia_siguiente_de_comer() -> void:
	Granja.atender("gallina")
	assert_eq(Granja.cantidad("huevo"), 0)
	_dia_siguiente()
	Granja.atender("gallina")
	assert_eq(Granja.cantidad("huevo"), 1)


func test_pesca_responsable() -> void:
	assert_eq(Granja.sacar_pez(true), "cria", "Las crías se regresan")
	assert_eq(Granja.cantidad("pescado"), 0)
	for i in Granja.PESCA_POR_DIA:
		Granja.sacar_pez(false)
	assert_eq(Granja.cantidad("pescado"), Granja.PESCA_POR_DIA)
	assert_false(Granja.puede_pescar(), "Hay límite por día")
	Juego.dia += 1
	assert_true(Granja.puede_pescar())


func test_cocinar_y_comer() -> void:
	Granja.dar("maiz")
	Granja.dar("leche")
	assert_false(Granja.cocinar("atole"), "Con el fogón apagado no se cocina")
	assert_false(Granja.prender_fogon(), "Sin leña no prende")
	Granja.dar("lena")
	assert_true(Granja.prender_fogon())
	assert_eq(Granja.cantidad("lena"), 0)
	assert_true(Granja.cocinar("atole"))
	assert_eq(Granja.cantidad("atole"), 1)
	assert_has(Juego.recetario, "atole")
	Granja.fijar_energia(40.0)
	assert_true(Granja.comer("atole"))
	assert_almost_eq(Juego.energia, 70.0, 0.01)
	assert_false(Granja.comer("lena"), "La leña no se come")


func test_con_poca_energia_se_camina_mas_lento() -> void:
	for zona in Juego.ZONAS:
		Juego.completar_zona(zona)
	Granja.fijar_energia(10.0)
	assert_lt(Granja.factor_velocidad(), 1.0)
	Granja.fijar_energia(80.0)
	assert_eq(Granja.factor_velocidad(), 1.0)


func test_la_granja_se_guarda() -> void:
	Granja.dar("semilla_frijol", 2)
	Granja.plantar(3, "frijol")
	Granja.regar(3)
	Juego.recetario.append("elote_asado")
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_eq(Granja.cantidad("semilla_frijol"), 1)
	assert_eq(Granja.parcela(3)["cultivo"], "frijol")
	assert_true(Granja.parcela(3)["regada"])
	assert_has(Juego.recetario, "elote_asado")


func test_la_milpa_aparece_al_restaurar_el_rio() -> void:
	var valle = preload("res://scenes/valle/Valle.tscn").instantiate()
	add_child_autofree(valle)
	await wait_process_frames(2)
	assert_null(valle.get_node_or_null("Objetos/Parcela0"), "Antes del río no hay milpa")
	valle.free()
	Juego.completar_zona("rio")
	valle = preload("res://scenes/valle/Valle.tscn").instantiate()
	add_child_autofree(valle)
	await wait_process_frames(2)
	assert_not_null(valle.get_node_or_null("Objetos/Parcela0"))
	assert_not_null(valle.get_node_or_null("Objetos/Gallina"))
	assert_not_null(valle.get_node_or_null("Objetos/Pescar"))
	assert_gt(get_tree().get_nodes_in_group(&"silvestre").size(), 0)


func test_subir_de_nivel_desbloquea_cosas() -> void:
	assert_eq(Granja.nivel(), 1)
	assert_eq(Granja.surcos(), 6)
	assert_eq(Granja.nivel_del_surco(5), 1)
	assert_eq(Granja.nivel_del_surco(6), 2)
	assert_eq(Granja.nivel_del_surco(11), 4)
	assert_false(Granja.desbloqueado("cabra", false))
	watch_signals(Granja)
	Granja.dar_xp(int(Granja.datos["niveles"]["xp"][2]))
	assert_eq(Granja.nivel(), 3)
	assert_signal_emit_count(Granja, "nivel_subio", 2, "Avisa de cada nivel que sube")
	assert_eq(Granja.surcos(), 9)
	assert_true(Granja.desbloqueado("cabra", false))


func test_las_recetas_avanzadas_piden_nivel() -> void:
	for id in ["frijol", "frijol", "calabaza", "lena"]:
		Granja.dar(id)
	Granja.prender_fogon()
	assert_false(Granja.cocinar("sopa_tarasca"), "La sopa tarasca es del nivel 4")
	Granja.dar_xp(int(Granja.datos["niveles"]["xp"][3]))
	assert_true(Granja.cocinar("sopa_tarasca"))


func test_entregar_un_pedido_del_tianguis() -> void:
	Juego.completar_zona("rio")
	var pedidos := Granja.pedidos_tianguis()
	assert_eq(pedidos.size(), 3)
	var pedido: Dictionary = pedidos[0]
	assert_false(Granja.entregar(0), "Sin lo que piden no se entrega")
	for id in pedido["cosas"]:
		Granja.dar(id, int(pedido["cosas"][id]))
	var xp_antes := Juego.xp
	assert_true(Granja.entregar(0))
	assert_eq(Juego.hojas, int(pedido["hojas"]))
	assert_eq(Juego.xp, xp_antes + int(pedido["xp"]))
	# Por azar el nuevo puede pedir lo mismo: se revisa que sea otro pedido, no que sea distinto.
	assert_false(is_same(Granja.pedidos_tianguis()[0], pedido), "Llega un pedido nuevo")
	for id in pedido["cosas"]:
		assert_eq(Granja.cantidad(id), 0)


func test_comprar_semillas_con_hojas() -> void:
	assert_false(Granja.comprar_semilla("semilla_maiz"))
	Juego.dar_hojas(5)
	assert_true(Granja.comprar_semilla("semilla_maiz"))
	assert_eq(Granja.cantidad("semilla_maiz"), 1)
	assert_eq(Juego.hojas, 5 - int(Granja.datos["semillas_tianguis"]["semilla_maiz"]))


func test_tianguis_y_nivel_se_guardan() -> void:
	Juego.completar_zona("rio")
	Granja.dar_xp(30)
	var pedidos := Granja.pedidos_tianguis().duplicate(true)
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_eq(Juego.xp, 30)
	assert_eq(Granja.pedidos_tianguis().size(), pedidos.size())
	assert_eq(Granja.pedidos_tianguis()[0]["hojas"], pedidos[0]["hojas"])


func test_los_animales_no_pisan_la_milpa() -> void:
	var animal: AnimalValle = preload("res://scenes/valle/AnimalValle.tscn").instantiate()
	animal.prohibido.append(Rect2(100, 0, 100, 100))
	animal.position = Vector2(50, 50)
	for i in 100:
		animal._mover_hacia(Vector2(300, 50), 70.0, 0.1)
	assert_lt(animal.position.x, 100.0, "Se queda en la orilla")
	animal.vuela = true
	for i in 100:
		animal._mover_hacia(Vector2(300, 50), 70.0, 0.1)
	assert_eq(animal.position, Vector2(300, 50), "Las mariposas pasan volando")
	animal.free()


func test_el_molino_hace_masa_desde_el_nivel_2() -> void:
	Granja.dar("maiz", 2)
	assert_true(Granja.hacer_en_taller("molino").is_empty(), "Antes del nivel 2 está cerrado")
	Granja.dar_xp(int(Granja.datos["niveles"]["xp"][1]))
	assert_eq(Granja.hacer_en_taller("molino"), {"masa": 2}, "Al terminar de moler sale la masa")
	assert_eq(Granja.cantidad("maiz"), 0)
	assert_eq(Granja.cantidad("masa"), 2)
	assert_true(Granja.hacer_en_taller("molino").is_empty(), "Sin maíz no se muele")


func test_los_minijuegos_se_ganan_y_se_pierden() -> void:
	var moler := Minijuego.new()
	moler.tipo = "machacar"
	moler.meta = 3
	add_child_autofree(moler)
	watch_signals(moler)
	for i in 3:
		moler.accion()
	await wait_seconds(0.9)
	assert_signal_emitted_with_parameters(moler, "terminado", [true])
	var revolver := Minijuego.new()
	revolver.tipo = "revolver"
	revolver.meta = 2
	add_child_autofree(revolver)
	revolver.revolver(1)
	assert_eq(revolver.progreso, 0, "Hay que empezar por la izquierda")
	revolver.revolver(-1)
	revolver.revolver(-1)
	assert_eq(revolver.progreso, 1, "Hay que alternar los lados")
	var pescar := Minijuego.new()
	pescar.tipo = "atinar"
	pescar.fallas_max = 2
	add_child_autofree(pescar)
	watch_signals(pescar)
	pescar._zona = Vector2(0.4, 0.6)
	pescar._marca = 0.5
	pescar.accion()
	assert_eq(pescar.progreso, 1, "En lo verde se atina")
	pescar._zona = Vector2(0.4, 0.6)
	for i in 2:
		pescar._marca = 0.05
		pescar.accion()
	assert_signal_emitted_with_parameters(pescar, "terminado", [false])


func test_la_colmena_trabaja_sola_y_se_llena() -> void:
	Granja.dar_xp(int(Granja.datos["niveles"]["xp"][5]))
	var horas := float(Granja.datos["talleres"]["colmena"]["horas"])
	for i in 5:
		Granja.avanzar_talleres(horas)
	assert_eq(int(Granja.taller("colmena")["listo"]), Granja.TANDAS_MAX, "Se llena y se para")
	assert_false(Granja.taller("colmena")["trabajando"])
	assert_eq(Granja.recoger_taller("colmena"), {"miel": Granja.TANDAS_MAX})
	assert_true(Granja.taller("colmena")["trabajando"], "Al recoger vuelve a trabajar")


func test_los_talleres_se_guardan() -> void:
	Granja.dar_xp(int(Granja.datos["niveles"]["xp"][5]))
	Granja.avanzar_talleres(float(Granja.datos["talleres"]["colmena"]["horas"]))
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_eq(int(Granja.taller("colmena")["listo"]), 1, "La miel que hicieron las abejas sigue ahí")


func test_las_decoraciones_se_compran_se_ponen_donde_sea_y_no_se_pierden() -> void:
	Juego.dar_hojas(3)
	assert_false(Granja.comprar_decoracion("espantapajaros"), "Se abre en un nivel más alto")
	assert_true(Granja.comprar_decoracion("cempasuchil"))
	assert_eq(Juego.hojas, 0)
	assert_false(Granja.comprar_decoracion("banca"), "No alcanzan las hojas")
	var puesta := Granja.poner_decoracion("cempasuchil", Vector2(500, 600))
	assert_eq(Granja.guardadas("cempasuchil"), 0)
	assert_true(Granja.poner_decoracion("cempasuchil", Vector2(1, 1)).is_empty(), "Ya no hay otra guardada")
	puesta["x"] = 700.0
	Granja.fijar_posicion("molino", Vector2(900, 400))
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_eq(Juego.decoraciones["puestas"].size(), 1)
	assert_eq(float(Juego.decoraciones["puestas"][0]["x"]), 700.0, "Se guarda donde se movió")
	assert_eq(Granja.posicion("molino", Vector2.ZERO), Vector2(900, 400))
	assert_eq(Granja.posicion("queseria", Vector2(5, 5)), Vector2(5, 5), "Lo que no se movió sigue en su lugar")
	Granja.guardar_decoracion(Juego.decoraciones["puestas"][0])
	assert_eq(Granja.guardadas("cempasuchil"), 1, "Guardarla no la pierde")


func test_el_guajolote_llega_en_el_nivel_5() -> void:
	assert_false(Granja.desbloqueado("guajolote", false))
	Granja.dar_xp(int(Granja.datos["niveles"]["xp"][4]))
	assert_true(Granja.desbloqueado("guajolote", false))
	assert_eq(Granja.atender("guajolote"), "Le diste de comer. Mañana tendrá huevo.")


func test_el_fogon_cocina_despues_del_fuego_y_cerrar_lo_cancela() -> void:
	Granja.dar("maiz", 2)
	Granja.dar("lena")
	Granja.prender_fogon()
	var receta: Dictionary = Granja.datos["recetas"][0]
	Granja.abrir_cocina()
	Granja._cocinar_con_fuego(receta)
	assert_eq(Granja.cantidad(receta["id"]), 0, "Primero se ve el fuego")
	await wait_seconds(1.4)
	assert_eq(Granja.cantidad(receta["id"]), 1)
	Granja.abrir_cocina()
	Granja._cocinar_con_fuego(receta)
	Granja.cerrar()
	await wait_seconds(1.4)
	assert_eq(Granja.cantidad(receta["id"]), 1, "Si se cierra a medias no se gasta nada")
	assert_eq(Granja.cantidad("maiz"), 1)


func test_la_lena_se_quema_y_apagar_la_guarda() -> void:
	Granja.dar("lena", 2)
	assert_true(Granja.prender_fogon())
	assert_true(Granja.echar_lena())
	assert_eq(Granja.cantidad("lena"), 0)
	Granja.quemar_lena(Granja.HORAS_POR_LENO)
	assert_true(Granja.fogon_prendido(), "Le queda un leño")
	Granja.apagar_fogon()
	Granja.quemar_lena(10.0)
	assert_false(Granja.fogon_prendido())
	assert_true(Granja.prender_fogon(), "Prende con la leña que quedó adentro, sin gastar otro leño")
	Granja.quemar_lena(Granja.HORAS_POR_LENO)
	assert_false(Granja.fogon_prendido(), "Sin leña se apaga solo")
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_false(Granja.fogon_prendido())

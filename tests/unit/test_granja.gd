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


func test_la_milpa_crece_solo_si_se_riega() -> void:
	Granja.dar("semilla_maiz")
	assert_true(Granja.plantar(0, "maiz"))
	assert_eq(Granja.cantidad("semilla_maiz"), 0)
	_dia_siguiente()
	assert_eq(int(Granja.parcela(0)["etapa"]), 0, "Sin regar no crece")
	for i in Granja.LISTO:
		assert_true(Granja.regar(0))
		assert_false(Granja.regar(0), "Solo se riega una vez al día")
		_dia_siguiente()
	assert_eq(int(Granja.parcela(0)["etapa"]), Granja.LISTO)
	var cosecha := Granja.cosechar(0)
	assert_eq(int(cosecha["maiz"]), 3)
	assert_eq(Granja.cantidad("semilla_maiz"), 1, "La cosecha devuelve una semilla")
	assert_true(Granja.parcela(0)["cultivo"].is_empty())


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
	assert_false(Granja.cocinar("atole"), "Sin leña no hay fuego")
	Granja.dar("lena")
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

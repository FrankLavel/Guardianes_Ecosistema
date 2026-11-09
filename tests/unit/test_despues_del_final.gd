extends GutTest
## Después del final: animales que pasean, pedidos de ayuda, hojas y la casa del guardián.

const RANURA := 96
const ESCENA_VALLE := preload("res://scenes/valle/Valle.tscn")
const ESCENA_CASA := preload("res://scenes/valle/Casa.tscn")


func before_each() -> void:
	Juego.nueva_partida(RANURA)


func after_each() -> void:
	Juego.entrada_bloqueada = false
	Juego.borrar_partida(RANURA)


func _terminar_juego() -> void:
	for zona in Juego.ZONAS:
		Juego.completar_zona(zona)


func _valle() -> Node:
	var valle: Node = ESCENA_VALLE.instantiate()
	add_child_autofree(valle)
	await wait_physics_frames(2)
	return valle


func test_hojas_ayudas_y_muebles_se_guardan() -> void:
	Juego.dar_hojas(9)
	Juego.contar_ayuda("basura")
	Juego.contar_ayuda("basura")
	Juego.muebles.append("maceta")
	Juego.pedido = {"tipo": "cria", "animal": "Venado1", "especie": "venado", "estado": "activo", "progreso": 0}
	Juego.es_de_noche = true
	Juego.guardar()
	Juego.nueva_partida(RANURA)
	assert_true(Juego.cargar(RANURA))
	assert_eq(Juego.hojas, 9)
	assert_eq(int(Juego.ayudas["basura"]), 2)
	assert_eq(Juego.muebles, ["maceta"] as Array[String])
	assert_eq(Juego.pedido["animal"], "Venado1")
	assert_true(Juego.es_de_noche)


func test_partida_vieja_sin_datos_nuevos_carga() -> void:
	Juego.desde_diccionario({"version": 3, "genero": "nina", "zonas_completadas": ["rio"]})
	assert_eq(Juego.hojas, 0)
	assert_true(Juego.pedido.is_empty())
	assert_false(Juego.es_de_noche)


func test_no_se_gastan_hojas_que_no_hay() -> void:
	Juego.dar_hojas(3)
	assert_false(Juego.gastar_hojas(5))
	assert_eq(Juego.hojas, 3)
	assert_true(Juego.gastar_hojas(3))
	assert_eq(Juego.hojas, 0)


func test_los_animales_aparecen_al_restaurar_su_zona() -> void:
	Juego.completar_zona("rio")
	var valle = await _valle()
	assert_true(valle.get_node("Objetos/Garza1").visible, "La garza vuelve con el río limpio")
	assert_false(valle.get_node("Objetos/Venado1").visible, "El venado espera al bosque")
	assert_false(valle.get_node("Objetos/Pato1").visible, "El pato espera al lago")


func test_no_hay_pedidos_antes_del_final() -> void:
	Juego.completar_zona("rio")
	var valle = await _valle()
	Juego.siguiente_pedido = 0.0
	await wait_process_frames(3)
	assert_true(Juego.pedido.is_empty())


func test_ya_no_piden_recoger_basura_ni_plantar_arboles() -> void:
	_terminar_juego()
	var valle = await _valle()
	var pedidos: PedidosAyuda = valle.pedidos
	assert_false(pedidos.iniciar_pedido("basura"))
	assert_false(pedidos.iniciar_pedido("plantar"))


func test_el_siguiente_pedido_tarda_un_dia() -> void:
	_terminar_juego()
	var valle = await _valle()
	var pedidos: PedidosAyuda = valle.pedidos
	var venado: AnimalValle = valle.get_node("Objetos/Venado1")
	assert_true(pedidos.iniciar_pedido("cria", venado))
	assert_eq(Juego.pedido["estado"], "aviso")
	pedidos._activar()
	Juego.pedido["progreso"] = 1
	pedidos._terminar()
	assert_eq(Juego.hojas, 8)
	assert_eq(venado.estado, AnimalValle.Estado.PASEO)
	assert_gte(Juego.siguiente_pedido - Juego.horas_totales(), 20.0, "El que sigue llega casi un día después")
	await wait_process_frames(3)
	assert_true(Juego.pedido.is_empty(), "No llega otro enseguida")


func test_la_cria_cuenta_al_llegar_con_su_mama() -> void:
	_terminar_juego()
	var valle = await _valle()
	var pedidos: PedidosAyuda = valle.pedidos
	var venado: AnimalValle = valle.get_node("Objetos/Venado1")
	pedidos.iniciar_pedido("cria", venado)
	pedidos._activar()
	assert_not_null(pedidos.cria)
	pedidos._al_llamar_cria(pedidos.cria)
	assert_eq(pedidos.cria.objetivo, valle.gara, "La cría sigue al guardián")
	pedidos.cria.global_position = venado.global_position + Vector2(40, 0)
	await wait_process_frames(2)
	assert_eq(int(Juego.pedido["progreso"]), 1)


func test_el_animal_que_llega_de_abajo_queda_al_alcance_para_hablar() -> void:
	_terminar_juego()
	Juego.dialogos_vistos.append("don_chucho_granja")
	var valle = await _valle()
	var venado: AnimalValle = valle.get_node("Objetos/Venado1")
	valle.gara.global_position = Vector2(2050, 1000)
	venado.global_position = valle.gara.global_position + Vector2(0, 250)
	await wait_physics_frames(2)
	valle.pedidos.iniciar_pedido("cria", venado)
	await wait_until(func(): return venado.estado == AnimalValle.Estado.ESPERA, 10.0)
	await wait_physics_frames(3)
	assert_has(valle.gara._interactuables, venado, "Se puede hablar con él sin dar un paso")


func test_un_pedido_a_medias_reaparece_al_volver() -> void:
	_terminar_juego()
	Juego.pedido = {"tipo": "flores", "animal": "Monarca1", "especie": "monarca", "estado": "activo", "progreso": 2}
	var valle = await _valle()
	assert_eq(valle.pedidos._objetos.size(), 1, "Solo falta plantar una")
	assert_eq(valle.get_node("Objetos/Monarca1").estado, AnimalValle.Estado.ESPERA)


func test_comprar_mueble_en_la_casa() -> void:
	var casa = ESCENA_CASA.instantiate()
	add_child_autofree(casa)
	await wait_process_frames(2)
	assert_false(casa.comprar("pecera"), "Sin hojas no se compra")
	Juego.dar_hojas(12)
	assert_true(casa.comprar("pecera"))
	assert_has(Juego.muebles, "pecera")
	assert_eq(Juego.hojas, 0)
	assert_false(casa.comprar("pecera"), "No se compra dos veces")


func test_paneles_de_la_casa_se_abren_y_cierran() -> void:
	var casa = ESCENA_CASA.instantiate()
	add_child_autofree(casa)
	await wait_process_frames(2)
	for panel in ["trofeos", "tablero", "muebles"]:
		casa.abrir_panel(panel)
		assert_true(Juego.entrada_bloqueada)
		casa.cerrar_panel()
		await wait_process_frames(2)
		assert_false(Juego.entrada_bloqueada)


func test_se_puede_caminar_hasta_la_puerta_y_la_cama() -> void:
	var casa = ESCENA_CASA.instantiate()
	add_child_autofree(casa)
	var gara: GaraAerea = casa.gara
	gara.leer_entrada_del_jugador = false
	gara.entrada_direccion = Vector2.DOWN
	await wait_seconds(1.5)
	assert_gt(gara.global_position.y, 950.0, "Llega a la puerta entre los postes")
	var cama: Node2D = casa.get_node("Objetos/Cama")
	gara.global_position = Vector2(900, 700)
	gara.entrada_direccion = gara.global_position.direction_to(cama.global_position)
	await wait_until(func(): return gara.global_position.distance_to(cama.global_position) < 60.0, 3.0)
	assert_lt(gara.global_position.distance_to(cama.global_position), 60.0, "Llega junto a la cama")


func test_la_monarca_pide_flores() -> void:
	_terminar_juego()
	var valle = await _valle()
	var pedidos: PedidosAyuda = valle.pedidos
	var monarca: AnimalValle = valle.get_node("Objetos/Monarca1")
	assert_true(pedidos.iniciar_pedido("flores", monarca))
	pedidos._activar()
	assert_eq(pedidos._objetos.size(), 3)
	assert_eq(pedidos._objetos[0].planta, "flores")
	for objeto in pedidos._objetos.duplicate():
		objeto.interactuar(valle.gara)
	pedidos._terminar()
	assert_eq(int(Juego.ayudas["flores"]), 1)


func test_el_reloj_avisa_cuando_anochece() -> void:
	Juego.hora = 19.5
	watch_signals(Juego)
	Juego.avanzar_hora(1.0)
	assert_true(Juego.es_de_noche)
	assert_signal_emitted_with_parameters(Juego, "noche_cambio", [true])
	assert_eq(Juego.texto_hora(), "8 de la noche")
	assert_eq(Juego.color_del_cielo(), Juego.COLOR_NOCHE)


func test_dormir_empieza_un_dia_nuevo() -> void:
	var casa = ESCENA_CASA.instantiate()
	add_child_autofree(casa)
	await wait_process_frames(2)
	Juego.hora = 22.0
	await casa.dormir()
	assert_eq(Juego.dia, 2)
	assert_almost_eq(Juego.hora, Juego.HORA_DESPERTAR, 0.01)
	assert_false(Juego.es_de_noche)
	assert_false(Juego.entrada_bloqueada)


func test_de_noche_los_animales_duermen_y_no_piden_ayuda() -> void:
	_terminar_juego()
	Juego.hora = 23.0
	var valle = await _valle()
	Juego.siguiente_pedido = 0.0
	await wait_process_frames(3)
	await wait_physics_frames(3)
	assert_true(Juego.pedido.is_empty(), "De noche no hay pedidos")
	assert_eq(valle.get_node("Objetos/Venado1").sprite.animation, &"descansar")
	assert_false(valle.get_node("Objetos/Monarca1").sprite.visible, "Las mariposas se van a descansar")

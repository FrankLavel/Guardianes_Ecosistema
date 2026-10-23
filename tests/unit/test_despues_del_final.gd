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
	valle.pedidos._espera = 0.0
	await wait_process_frames(3)
	assert_true(Juego.pedido.is_empty())


func test_pedido_de_basura_completo() -> void:
	_terminar_juego()
	var valle = await _valle()
	var pedidos: PedidosAyuda = valle.pedidos
	var venado: AnimalValle = valle.get_node("Objetos/Venado1")
	assert_true(pedidos.iniciar_pedido("basura", venado))
	assert_eq(Juego.pedido["estado"], "aviso")
	assert_eq(venado.estado, AnimalValle.Estado.VA_AL_JUGADOR)
	pedidos._activar()
	assert_eq(Juego.pedido["estado"], "activo")
	assert_eq(pedidos._objetos.size(), 3, "Aparecen 3 basuras")
	for objeto in pedidos._objetos.duplicate():
		objeto.interactuar(valle.gara)
	assert_eq(int(Juego.pedido["progreso"]), 3)
	pedidos._terminar()
	assert_true(Juego.pedido.is_empty())
	assert_eq(Juego.hojas, 5)
	assert_eq(int(Juego.ayudas["basura"]), 1)
	assert_eq(venado.estado, AnimalValle.Estado.PASEO)


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


func test_un_pedido_a_medias_reaparece_al_volver() -> void:
	_terminar_juego()
	Juego.pedido = {"tipo": "plantar", "animal": "Venado2", "especie": "venado", "estado": "activo", "progreso": 1}
	var valle = await _valle()
	assert_eq(valle.pedidos._objetos.size(), 1, "Solo falta plantar uno")
	assert_eq(valle.get_node("Objetos/Venado2").estado, AnimalValle.Estado.ESPERA)


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

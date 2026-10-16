extends GutTest
## Valle (mapa aéreo): Gara camina, Don Chucho habla y las entradas respetan el progreso.

const ESCENA_VALLE := preload("res://scenes/valle/Valle.tscn")
const RANURA := 99

var valle: Node2D


func before_each() -> void:
	Juego.nueva_partida(RANURA)
	valle = add_child_autofree(ESCENA_VALLE.instantiate())
	valle.gara.leer_entrada_del_jugador = false


func after_each() -> void:
	get_tree().paused = false
	if Dialogo.activo:
		for i in 20:
			Dialogo.avanzar()
		await wait_for_signal(Dialogo.terminado, 1.0)
	Juego.entrada_bloqueada = false
	Juego.borrar_partida(RANURA)


func _entrada(zona: String) -> EntradaZona:
	for e in valle.entradas():
		if e.zona == zona:
			return e
	return null


func test_gara_camina_en_cuatro_direcciones() -> void:
	var gara: GaraAerea = valle.gara
	for datos in [[Vector2.RIGHT, "derecha"], [Vector2.LEFT, "izquierda"], [Vector2.UP, "arriba"], [Vector2.DOWN, "abajo"]]:
		gara.velocity = Vector2.ZERO
		var inicio := gara.global_position
		gara.entrada_direccion = datos[0]
		await wait_physics_frames(15)
		assert_gt(gara.global_position.distance_to(inicio), 20.0, "Se mueve hacia %s" % datos[1])
		assert_eq(gara.mirando, datos[1])
	gara.entrada_direccion = Vector2.ZERO


func test_no_se_mueve_durante_un_dialogo() -> void:
	var gara: GaraAerea = valle.gara
	Juego.entrada_bloqueada = true
	var inicio := gara.global_position
	gara.entrada_direccion = Vector2.RIGHT
	await wait_physics_frames(10)
	assert_almost_eq(gara.global_position.x, inicio.x, 0.5)


func test_hay_tres_entradas_y_solo_el_rio_esta_abierto() -> void:
	assert_eq(valle.entradas().size(), 3)
	assert_eq(_entrada("rio").get_node("Estado").text, "")
	assert_eq(_entrada("bosque").get_node("Estado").text, "Bloqueado")
	assert_eq(_entrada("lago").get_node("Estado").text, "Bloqueado")


func test_la_entrada_del_rio_lleva_al_nivel_1() -> void:
	assert_eq(_entrada("rio").escena, "res://scenes/world/Nivel1.tscn")
	assert_true(ResourceLoader.exists(_entrada("rio").escena))


func test_entrada_bloqueada_explica_por_que() -> void:
	_entrada("bosque").interactuar(valle.gara)
	assert_true(Dialogo.activo)
	assert_eq(Dialogo.id_actual, "entrada_bloqueada_bosque")


func test_don_chucho_cambia_su_dialogo_con_el_progreso() -> void:
	var chucho: PersonajeValle = valle.get_node("Objetos/DonChucho")
	assert_eq(chucho.dialogo_actual(), "don_chucho_inicio")
	Juego.marcar_dialogo_visto("don_chucho_inicio")
	assert_eq(chucho.dialogo_actual(), "don_chucho_repetir")
	Juego.completar_zona("rio")
	assert_eq(chucho.dialogo_actual(), "don_chucho_rio_limpio")


func test_el_valle_recupera_color_al_restaurar_zonas() -> void:
	var filtro: ShaderMaterial = valle.filtro_restauracion.material
	var gris_inicial: float = filtro.get_shader_parameter("desaturacion")
	Juego.completar_zona("rio")
	assert_lt(filtro.get_shader_parameter("desaturacion"), gris_inicial)
	assert_eq((valle.rio.material as ShaderMaterial).get_shader_parameter("contaminacion"), 0.0)
	assert_eq(_entrada("rio").get_node("Estado").text, "¡Restaurado!")
	assert_eq(_entrada("bosque").get_node("Estado").text, "")


func test_gara_no_cruza_el_rio() -> void:
	var gara: GaraAerea = valle.gara
	gara.global_position = Vector2(900, 900)
	gara.reset_physics_interpolation()
	gara.entrada_direccion = Vector2.LEFT
	await wait_physics_frames(90)
	assert_gt(gara.global_position.x, 760.0, "El río la detiene")


func test_menu_de_pausa_pausa_y_reanuda() -> void:
	var pausa: MenuPausa = valle.get_node("MenuPausa")
	pausa.abrir()
	var estaba_pausado := get_tree().paused
	pausa.cerrar()
	assert_true(estaba_pausado)
	assert_false(get_tree().paused)
	assert_false(pausa.get_node("Panel/VBox/BtnValle").visible, "En el valle no se ofrece volver al valle")

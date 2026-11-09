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


func test_atras_cierra_el_panel_abierto_sin_abrir_la_pausa() -> void:
	# (Se prueba lo que cierra "atrás"; _atras completo cambiaría la escena de las pruebas.)
	Granja.abrir_mochila()
	assert_true(Juego._cerrar_lo_abierto(valle), "Cierra la mochila en lugar de abrir la pausa")
	await wait_process_frames(3)
	assert_eq(Granja.abierto, "")
	assert_false(Juego._cerrar_lo_abierto(valle), "Sin nada abierto, toca abrir la pausa")


func test_la_cria_no_aparece_dentro_de_la_casa() -> void:
	await wait_physics_frames(2)
	assert_false(valle.pedidos.libre(Vector2(1680, 870)), "La casa no es lugar libre")
	assert_true(valle.pedidos.libre(Vector2(2050, 1250)), "El pasto sí")


func test_la_entrada_desaparece_al_restaurar_su_zona() -> void:
	Juego.completar_zona("rio")
	valle.actualizar_mundo()
	assert_false(_entrada("rio").visible, "Ya solo queda su trofeo")
	assert_true(_entrada("bosque").visible)


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
	assert_false(_entrada("rio").visible, "La entrada se va; queda su trofeo en la casa")
	assert_eq(_entrada("bosque").get_node("Estado").text, "")


func test_gara_no_cruza_el_rio() -> void:
	var gara: GaraAerea = valle.gara
	gara.global_position = Vector2(900, 900)
	gara.reset_physics_interpolation()
	gara.entrada_direccion = Vector2.LEFT
	await wait_physics_frames(90)
	assert_gt(gara.global_position.x, 760.0, "El río la detiene")


## CP-04: empuja a Gara contra algo sólido y revisa que se quede de su lado.
func _empujar(desde: Vector2, direccion: Vector2) -> Vector2:
	var gara: GaraAerea = valle.gara
	gara.global_position = desde
	gara.reset_physics_interpolation()
	gara.entrada_direccion = direccion
	await wait_physics_frames(120)
	gara.entrada_direccion = Vector2.ZERO
	return gara.global_position


func test_no_atraviesa_la_casa() -> void:
	var casa: Node2D = valle.get_node("Objetos/CasaAdobe1")
	var al_final := await _empujar(casa.position + Vector2(260, -20), Vector2.LEFT)
	assert_gt(al_final.x, casa.position.x + 60.0, "La pared de la casa la detiene")


func test_no_atraviesa_un_arbol() -> void:
	var arbol: Node2D = valle.get_node("Objetos/Encino18")
	var al_final := await _empujar(arbol.position + Vector2(-160, -4), Vector2.RIGHT)
	assert_lt(al_final.x, arbol.position.x - 10.0, "El tronco la detiene")


## Empuja de frente contra un tramo de cerca (es una línea en diagonal) y revisa que siga del mismo lado.
func _empujar_contra_la_cerca(choque: CollisionShape2D) -> float:
	var forma: SegmentShape2D = choque.shape
	var a: Vector2 = choque.global_transform * forma.a
	var b: Vector2 = choque.global_transform * forma.b
	var centro := (a + b) / 2.0
	var normal := (b - a).orthogonal().normalized()
	if normal.y < 0.0:
		normal = -normal
	var al_final := await _empujar(centro + normal * 90.0, -normal)
	return (al_final - centro).dot(normal)


func test_no_atraviesa_la_cerca() -> void:
	await wait_physics_frames(2)
	var choque := valle.get_node("Objetos/Cerca2").find_children("*", "CollisionShape2D", true, false)[0] as CollisionShape2D
	assert_gt(await _empujar_contra_la_cerca(choque), 0.0, "La cerca la detiene")


func test_no_atraviesa_la_cerca_de_un_corral() -> void:
	for zona in ["rio", "bosque", "lago"]:
		Juego.completar_zona(zona)
	Juego.dialogos_vistos.append("don_chucho_granja")
	valle.free()
	valle = add_child_autofree(ESCENA_VALLE.instantiate())
	valle.gara.leer_entrada_del_jugador = false
	await wait_physics_frames(3)
	var corral: Corral = valle.corrales["gallina"]
	var choques := corral.find_children("*", "CollisionShape2D", true, false).filter(func(c): return c.shape is SegmentShape2D)
	assert_eq(choques.size(), 4, "Los 4 tramos de la cerca son sólidos")
	assert_gt(await _empujar_contra_la_cerca(choques[2]), 0.0, "La cerca del corral la detiene")


func test_no_sale_del_mapa() -> void:
	var al_final := await _empujar(Vector2(2700, 900), Vector2.RIGHT)
	assert_lt(al_final.x, valle.TAMANO.x, "La orilla del valle la detiene")


func test_menu_de_pausa_pausa_y_reanuda() -> void:
	var pausa: MenuPausa = valle.get_node("MenuPausa")
	pausa.abrir()
	var estaba_pausado := get_tree().paused
	pausa.cerrar()
	assert_true(estaba_pausado)
	assert_false(get_tree().paused)
	assert_false(pausa.get_node("Panel/VBox/BtnValle").visible, "En el valle no se ofrece volver al valle")


func _presionar_e() -> void:
	var evento := InputEventAction.new()
	evento.action = &"interactuar"
	evento.pressed = true
	Input.parse_input_event(evento)
	await wait_physics_frames(1)
	evento = evento.duplicate()
	evento.pressed = false
	Input.parse_input_event(evento)
	await wait_physics_frames(1)


func test_cerrar_el_dialogo_con_e_no_lo_vuelve_a_abrir() -> void:
	# Regresión: la E que cerraba el diálogo de Don Chucho lo abría otra vez, en bucle.
	var gara: GaraAerea = valle.gara
	gara.leer_entrada_del_jugador = true
	var chucho: PersonajeValle = valle.get_node("Objetos/DonChucho")
	gara.global_position = chucho.global_position + Vector2(0, 50)
	gara.reset_physics_interpolation()
	await wait_physics_frames(5)
	await _presionar_e()
	assert_true(Dialogo.activo, "La E abre el diálogo")
	var lineas := Dialogo.lineas_de(Dialogo.id_actual).size()
	for i in lineas * 2:
		await _presionar_e()
	await wait_physics_frames(15)
	assert_false(Dialogo.activo, "El diálogo se cerró y no se volvió a abrir")


func test_la_nina_camina_con_su_propio_arte() -> void:
	Juego.nueva_partida(RANURA, "nina", "")
	var otro: Node2D = add_child_autofree(ESCENA_VALLE.instantiate())
	assert_eq(otro.gara.sprite.sprite_frames.resource_path, Juego.PERSONAJES["nina"]["aereo"])


func test_tras_el_nivel_don_chucho_pide_ayuda_con_el_filtro() -> void:
	var chucho: PersonajeValle = valle.get_node("Objetos/DonChucho")
	Juego.marcar_dialogo_visto("don_chucho_inicio")
	Juego.marcar("rio_nivel")
	assert_eq(chucho.dialogo_actual(), "don_chucho_filtro")
	assert_eq(valle.objetivo_actual(), "Habla con Don Chucho: quiere enseñarte algo.")


func test_al_terminar_ese_dialogo_se_abre_el_filtro() -> void:
	Juego.marcar("rio_nivel")
	valle._al_terminar_dialogo("don_chucho_filtro")
	get_tree().paused = false
	assert_true(valle.puzzle_filtro.visible)
	valle.puzzle_filtro.cerrar()


func test_resolver_el_filtro_restaura_el_rio_y_da_nadar() -> void:
	Juego.marcar("rio_nivel")
	valle._al_resolver_filtro()
	assert_true(Juego.zona_esta_completa("rio"))
	assert_true(Juego.tiene_habilidad("nadar"))
	assert_true(Juego.zona_desbloqueada("bosque"))

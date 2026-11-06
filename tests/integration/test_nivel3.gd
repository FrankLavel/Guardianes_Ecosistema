extends GutTest
## Nivel 3 (lago), su flujo en el valle y el final.

const ESCENA_NIVEL3 := preload("res://scenes/world/Nivel3.tscn")
const ESCENA_VALLE := preload("res://scenes/valle/Valle.tscn")
const ESCENA_FINAL := preload("res://scenes/ui/Final.tscn")
const RANURA := 91

var nivel: Node2D


func before_each() -> void:
	Juego.nueva_partida(RANURA)
	Juego.dar_habilidad("nadar")
	nivel = add_child_autofree(ESCENA_NIVEL3.instantiate())
	nivel.guardian.leer_entrada_del_jugador = false


func after_each() -> void:
	get_tree().paused = false
	Juego.entrada_bloqueada = false
	if Dialogo.activo:
		for i in 20:
			Dialogo.avanzar()
		await wait_for_signal(Dialogo.terminado, 1.0)
	Juego.borrar_partida(RANURA)
	Juego.nueva_partida()


func _terminar_todo() -> void:
	for l in nivel.lirios():
		l.interactuar(nivel.guardian)
	for h in nivel.huevos():
		h._al_entrar(nivel.guardian)
	for b in nivel.basuras():
		b.interactuar(nivel.guardian)
	nivel.cadena.puzzle.resuelto.emit()


func test_empieza_turbio_pero_se_puede_nadar() -> void:
	assert_eq(nivel.salud_del_lago(), 0.0)
	assert_eq(nivel.lirios().size(), 4)
	assert_eq(nivel.huevos().size(), 3)
	assert_eq(nivel.basuras().size(), 3)
	assert_true(nivel.lago.es_nadable(), "El lago turbio permite nadar")


func test_se_nada_en_el_lago_sin_reaparecer() -> void:
	var g: Guardian = nivel.guardian
	watch_signals(nivel.lago)
	g.global_position = nivel.lago.global_position + Vector2(300, -10)
	g.reset_physics_interpolation()
	await wait_physics_frames(30)
	assert_true(g.esta_nadando())
	assert_signal_not_emitted(nivel.lago, "guardian_cayo")


func test_se_puede_quitar_lirio_nadando() -> void:
	var g: Guardian = nivel.guardian
	var lirio: Lirio = nivel.lirios()[0]
	g.global_position = lirio.global_position + Vector2(0, 30)
	g.reset_physics_interpolation()
	await wait_physics_frames(4)
	g.entrada_interactuar = true
	await wait_physics_frames(2)
	assert_true(lirio.esta_quitado, "E quita el lirio aunque esté nadando")


func test_tocar_un_huevo_lo_rescata() -> void:
	var g: Guardian = nivel.guardian
	var huevo: HuevoAchoque = nivel.huevos()[0]
	g.global_position = huevo.global_position
	g.reset_physics_interpolation()
	await wait_physics_frames(4)
	assert_true(huevo.esta_rescatado)
	assert_eq(nivel.huevos_rescatados(), 1)


func test_con_todo_hecho_se_completa_y_aparecen_peces() -> void:
	_terminar_todo()
	await wait_seconds(0.5)
	assert_eq(nivel.tareas().size(), 11, "La basura recogida sigue contando como tarea")
	assert_true(nivel.lago_listo())
	assert_true(nivel.lago.hay_peces())
	assert_has(Juego.especies_descubiertas, "achoque")
	assert_has(Juego.especies_descubiertas, "pescado_blanco")
	nivel._al_llegar_a_meta(nivel.guardian)
	get_tree().paused = false
	assert_true(nivel.nivel_terminado)
	assert_true(Juego.tiene_marca("lago_nivel"))


func test_la_meta_dice_lo_que_falta() -> void:
	nivel._al_llegar_a_meta(nivel.guardian)
	var texto: String = nivel.hud.get_node("%TextoMensaje").text
	assert_string_contains(texto, "lirio")
	assert_string_contains(texto, "cadena alimenticia")


func test_flujo_del_valle_con_achi_hasta_el_final() -> void:
	nivel.queue_free()
	for m in ["rio_nivel", "bosque_nivel"]:
		Juego.marcar(m)
	Juego.marcar_dialogo_visto("don_chucho_inicio")
	Juego.marcar_dialogo_visto("mari_inicio")
	Juego.completar_zona("rio")
	Juego.completar_zona("bosque")
	var valle: Node2D = add_child_autofree(ESCENA_VALLE.instantiate())
	var achi: PersonajeValle = valle.get_node("Objetos/Achi")
	assert_eq(achi.dialogo_actual(), "achi_inicio")
	assert_eq(valle.objetivo_actual(), "Habla con Achi, el achoque, junto al lago.")
	Juego.marcar("lago_nivel")
	assert_eq(achi.dialogo_actual(), "achi_residuos")
	valle._al_terminar_dialogo("achi_residuos")
	get_tree().paused = false
	assert_true(valle.puzzle_residuos.visible)
	valle.puzzle_residuos.visible = false
	valle._al_resolver_residuos()
	assert_true(Juego.zona_esta_completa("lago"))
	assert_eq(Juego.progreso(), 1.0, "Las tres zonas restauradas")


func test_la_entrada_del_lago_lleva_al_nivel_3() -> void:
	nivel.queue_free()
	var valle: Node2D = add_child_autofree(ESCENA_VALLE.instantiate())
	for e in valle.entradas():
		if e.zona == "lago":
			assert_eq(e.escena, "res://scenes/world/Nivel3.tscn")


func test_el_final_muestra_resumen_y_creditos() -> void:
	nivel.queue_free()
	Juego.nueva_partida(RANURA, "nina", "Xóchitl")
	var final: Control = add_child_autofree(ESCENA_FINAL.instantiate())
	assert_eq(final.get_node("%Titulo").text, "¡Gracias, Xóchitl!")
	assert_string_contains(final.get_node("%Mensaje").text, "guardiana")
	assert_true(Juego.tiene_marca("final_visto"))
	var creditos: String = final.get_node("%TextoCreditos").text
	for nombre in ["Diego Arellano Bautista", "Ignacio Emiliano Santoyo Gonzales", "Francisco Gabriel Lazo Velázquez"]:
		assert_string_contains(creditos, nombre)
	final.mostrar_creditos()
	await wait_process_frames(2)
	assert_true(final.get_node("%Creditos").visible)

extends GutTest
## Nivel 2 (bosque) y su flujo en el valle.

const ESCENA_NIVEL2 := preload("res://scenes/world/Nivel2.tscn")
const ESCENA_VALLE := preload("res://scenes/valle/Valle.tscn")
const RANURA := 92

var nivel: Node2D


func before_each() -> void:
	Juego.nueva_partida(RANURA)
	nivel = add_child_autofree(ESCENA_NIVEL2.instantiate())


func after_each() -> void:
	get_tree().paused = false
	Juego.entrada_bloqueada = false
	Juego.borrar_partida(RANURA)
	Juego.nueva_partida()


func test_empieza_con_el_bosque_talado() -> void:
	assert_eq(nivel.salud_del_bosque(), 0.0)
	assert_false(nivel.bosque_listo())
	assert_false(nivel.arboles_nuevos.visible)
	assert_eq(nivel.tierras().size(), 2)


func test_el_guardian_aterriza_en_el_inicio() -> void:
	await wait_until(func(): return nivel.guardian.is_on_floor(), 3.0)
	assert_true(nivel.guardian.is_on_floor())


func test_sin_terminar_las_tareas_la_meta_dice_que_falta() -> void:
	nivel.fogata.interactuar(nivel.guardian)
	nivel._al_llegar_a_meta(nivel.guardian)
	assert_false(nivel.nivel_terminado)
	assert_string_contains(nivel.hud.get_node("%TextoMensaje").text, "liberar al venado")


func test_cada_tarea_sube_la_salud_del_bosque() -> void:
	nivel.fogata.interactuar(nivel.guardian)
	var salud_1: float = nivel.salud_del_bosque()
	nivel.venado.interactuar(nivel.guardian)
	assert_gt(nivel.salud_del_bosque(), salud_1)
	assert_has(Juego.especies_descubiertas, "venado")


func test_con_las_tres_tareas_se_completa_el_nivel() -> void:
	nivel.fogata.interactuar(nivel.guardian)
	nivel.venado.interactuar(nivel.guardian)
	nivel.vivero.puzzle.resuelto.emit()
	assert_true(nivel.bosque_listo())
	assert_true(nivel.arboles_nuevos.visible, "Aparecen los árboles nuevos")
	nivel._al_llegar_a_meta(nivel.guardian)
	get_tree().paused = false
	assert_true(nivel.nivel_terminado)
	assert_true(Juego.tiene_marca("bosque_nivel"))


func test_flujo_del_valle_con_mari() -> void:
	nivel.queue_free()
	Juego.marcar_dialogo_visto("don_chucho_inicio")
	Juego.marcar("rio_nivel")
	Juego.completar_zona("rio")
	var valle: Node2D = add_child_autofree(ESCENA_VALLE.instantiate())
	var mari: PersonajeValle = valle.get_node("Objetos/Mari")
	assert_eq(mari.dialogo_actual(), "mari_inicio")
	assert_eq(valle.objetivo_actual(), "Habla con Mari, la mariposa, junto al bosque.")
	Juego.marcar("bosque_nivel")
	assert_eq(mari.dialogo_actual(), "mari_habitat")
	valle._al_terminar_dialogo("mari_habitat")
	get_tree().paused = false
	assert_true(valle.puzzle_habitat.visible, "Mari abre el puzzle de hábitats")
	valle.puzzle_habitat.cerrar()
	await wait_process_frames(2)
	valle._al_resolver_habitat()
	assert_true(Juego.zona_esta_completa("bosque"))
	assert_true(Juego.tiene_habilidad("enredaderas"))
	assert_true(Juego.zona_desbloqueada("lago"))


func test_la_entrada_del_bosque_lleva_al_nivel_2() -> void:
	nivel.queue_free()
	var valle: Node2D = add_child_autofree(ESCENA_VALLE.instantiate())
	for e in valle.entradas():
		if e.zona == "bosque":
			assert_eq(e.escena, "res://scenes/world/Nivel2.tscn")

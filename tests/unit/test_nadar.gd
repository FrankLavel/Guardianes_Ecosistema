extends GutTest
## Habilidad de nadar: solo en agua limpia y después de aprenderla.

const ESCENA_GUARDIAN := preload("res://scenes/player/Guardian.tscn")
const ESCENA_RIO := preload("res://scenes/world/Rio.tscn")
const RANURA := 96

var guardian: Guardian
var rio: Rio


func before_each() -> void:
	Juego.nueva_partida(RANURA)
	rio = ESCENA_RIO.instantiate()
	rio.tamano = Vector2(300, 200)
	rio.position = Vector2(-150, 0)
	add_child_autofree(rio)
	guardian = ESCENA_GUARDIAN.instantiate()
	guardian.leer_entrada_del_jugador = false
	guardian.limite_caida = 5000.0
	add_child_autofree(guardian)


func _al_agua() -> void:
	guardian.global_position = Vector2(0, -40)
	guardian.reset_physics_interpolation()
	await wait_physics_frames(25)


func test_sin_la_habilidad_caer_al_agua_avisa_para_reaparecer() -> void:
	rio.limpieza = 1.0
	watch_signals(rio)
	await _al_agua()
	assert_signal_emitted(rio, "guardian_cayo")
	assert_false(guardian.esta_nadando())


func test_con_la_habilidad_pero_agua_sucia_tampoco_se_nada() -> void:
	Juego.dar_habilidad("nadar")
	rio.limpieza = 0.5
	watch_signals(rio)
	await _al_agua()
	assert_signal_emitted(rio, "guardian_cayo")


func test_con_la_habilidad_y_agua_limpia_se_nada() -> void:
	Juego.dar_habilidad("nadar")
	rio.limpieza = 1.0
	watch_signals(rio)
	await _al_agua()
	assert_signal_not_emitted(rio, "guardian_cayo")
	assert_true(guardian.esta_nadando())
	assert_lt(guardian.velocity.y, guardian.velocidad_caida_agua + 1.0, "Se hunde despacio")


func test_las_brazadas_suben_y_no_se_atraviesa_el_fondo() -> void:
	Juego.dar_habilidad("nadar")
	rio.limpieza = 1.0
	await _al_agua()
	await wait_physics_frames(90)
	assert_lt(guardian.global_position.y, rio.tamano.y + 2.0, "El lecho del río la detiene")
	var y := guardian.global_position.y
	guardian.entrada_salto_presionado = true
	await wait_physics_frames(6)
	assert_lt(guardian.global_position.y, y - 5.0, "Una brazada la sube")


func test_completar_el_rio_da_la_habilidad_de_nadar() -> void:
	assert_false(Juego.tiene_habilidad("nadar"))
	Juego.completar_zona("rio")
	assert_true(Juego.tiene_habilidad("nadar"))


func after_each() -> void:
	Juego.borrar_partida(RANURA)
	Juego.nueva_partida()

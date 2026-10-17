extends GutTest
## Mecánicas del bosque: enredaderas (plantar y trepar), fogata y venado.

const ESCENA_GUARDIAN := preload("res://scenes/player/Guardian.tscn")
const ESCENA_TIERRA := preload("res://scenes/world/TierraFertil.tscn")
const ESCENA_FOGATA := preload("res://scenes/world/Fogata.tscn")
const ESCENA_VENADO := preload("res://scenes/world/VenadoAtrapado.tscn")
const RANURA := 94

var guardian: Guardian


func before_each() -> void:
	Juego.nueva_partida(RANURA)
	var suelo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000, 40)
	forma.shape = rect
	forma.position = Vector2(0, 20)
	suelo.add_child(forma)
	add_child_autofree(suelo)
	guardian = ESCENA_GUARDIAN.instantiate()
	guardian.leer_entrada_del_jugador = false
	guardian.position = Vector2(0, -10)
	add_child_autofree(guardian)
	await wait_until(func(): return guardian.is_on_floor(), 2.0)


func after_each() -> void:
	Juego.borrar_partida(RANURA)
	Juego.nueva_partida()


func _tierra_plantada() -> TierraFertil:
	var tierra: TierraFertil = ESCENA_TIERRA.instantiate()
	tierra.altura_enredadera = 200.0
	tierra.position = Vector2(20, 0)
	add_child_autofree(tierra)
	await wait_physics_frames(3)
	guardian.entrada_interactuar = true
	await wait_physics_frames(2)
	await wait_for_signal(tierra.enredadera.termino_de_crecer, 3.0)
	return tierra


func test_plantar_hace_crecer_una_enredadera() -> void:
	var tierra := await _tierra_plantada()
	assert_true(tierra.esta_plantada)
	assert_true(tierra.enredadera.crecida)
	assert_true(tierra.enredadera.visible)


func test_se_trepa_hacia_arriba_y_se_llega_a_la_cima() -> void:
	await _tierra_plantada()
	await wait_physics_frames(15)
	guardian.entrada_vertical = -1.0
	await wait_physics_frames(3)
	assert_true(guardian.esta_trepando(), "↑ junto a la enredadera la agarra")
	await wait_seconds(1.6)
	assert_lt(guardian.global_position.y, -150.0, "Subió por la enredadera")
	guardian.entrada_vertical = 0.0
	await wait_physics_frames(10)
	assert_gt(guardian.global_position.y, -260.0, "No sube más allá de la cima")


func test_saltar_suelta_la_enredadera() -> void:
	await _tierra_plantada()
	await wait_physics_frames(15)
	guardian.entrada_vertical = -1.0
	await wait_seconds(0.5)
	guardian.entrada_vertical = 0.0
	guardian.entrada_salto_presionado = true
	await wait_physics_frames(2)
	assert_false(guardian.esta_trepando())


func test_sin_enredadera_arriba_no_hace_nada() -> void:
	guardian.entrada_vertical = -1.0
	await wait_physics_frames(5)
	assert_false(guardian.esta_trepando())


func test_la_fogata_cierra_el_paso_hasta_apagarla() -> void:
	var fogata: Fogata = ESCENA_FOGATA.instantiate()
	fogata.position = Vector2(90, 0)
	add_child_autofree(fogata)
	guardian.entrada_direccion = 1.0
	await wait_physics_frames(60)
	assert_lt(guardian.global_position.x, 90.0, "El fuego no deja pasar")
	fogata.interactuar(guardian)
	assert_true(fogata.esta_apagada)
	await wait_physics_frames(60)
	assert_gt(guardian.global_position.x, 120.0, "Apagada, ya se puede pasar")
	guardian.entrada_direccion = 0.0


func test_liberar_al_venado() -> void:
	var venado: VenadoAtrapado = ESCENA_VENADO.instantiate()
	venado.position = Vector2(30, 0)
	add_child_autofree(venado)
	watch_signals(venado)
	await wait_physics_frames(3)
	guardian.entrada_interactuar = true
	await wait_physics_frames(2)
	assert_signal_emitted(venado, "liberado")
	assert_true(venado.esta_libre)

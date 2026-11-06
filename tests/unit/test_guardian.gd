extends GutTest
## Movimiento del guardián sobre un suelo de prueba (sin depender del teclado).

const ESCENA_GUARDIAN := preload("res://scenes/player/Guardian.tscn")
const ALTURA_SUELO := 0.0

var guardian: Guardian


func before_each() -> void:
	var suelo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	forma.shape = rect
	forma.position = Vector2(0, ALTURA_SUELO + 20)
	suelo.add_child(forma)
	add_child_autofree(suelo)

	guardian = ESCENA_GUARDIAN.instantiate()
	guardian.leer_entrada_del_jugador = false
	guardian.position = Vector2(0, ALTURA_SUELO - 60)
	add_child_autofree(guardian)


func _aterrizar() -> void:
	await wait_until(func(): return guardian.is_on_floor(), 2.0)


func test_cae_por_gravedad_y_aterriza_en_el_suelo() -> void:
	await _aterrizar()
	assert_true(guardian.is_on_floor(), "Debería estar sobre el suelo")
	assert_almost_eq(guardian.global_position.y, ALTURA_SUELO, 2.0)


func test_camina_a_la_derecha() -> void:
	await _aterrizar()
	var x_inicial := guardian.global_position.x
	guardian.entrada_direccion = 1.0
	await wait_physics_frames(20)
	assert_gt(guardian.global_position.x, x_inicial + 20.0)
	assert_false(guardian.sprite.flip_h, "Mira a la derecha")


func test_camina_a_la_izquierda_y_voltea_el_sprite() -> void:
	await _aterrizar()
	var x_inicial := guardian.global_position.x
	guardian.entrada_direccion = -1.0
	await wait_physics_frames(20)
	assert_lt(guardian.global_position.x, x_inicial - 20.0)
	assert_true(guardian.sprite.flip_h, "Mira a la izquierda")


func test_se_detiene_al_soltar_la_direccion() -> void:
	await _aterrizar()
	guardian.entrada_direccion = 1.0
	await wait_physics_frames(15)
	guardian.entrada_direccion = 0.0
	await wait_physics_frames(15)
	assert_almost_eq(guardian.velocity.x, 0.0, 0.01)


func test_salta_desde_el_suelo() -> void:
	await _aterrizar()
	guardian.entrada_salto_presionado = true
	guardian.entrada_salto_mantenido = true
	await wait_physics_frames(8)
	assert_lt(guardian.global_position.y, ALTURA_SUELO - 30.0, "Debería estar en el aire")


func test_no_salta_en_el_aire() -> void:
	guardian.global_position = Vector2(0, ALTURA_SUELO - 600)
	await wait_physics_frames(15)
	assert_false(guardian.is_on_floor())
	guardian.entrada_salto_presionado = true
	guardian.entrada_salto_mantenido = true
	await wait_physics_frames(2)
	assert_gt(guardian.velocity.y, 0.0, "Sigue cayendo: no hay doble salto")


func test_reaparece_si_cae_fuera_del_nivel() -> void:
	watch_signals(guardian)
	guardian.punto_reaparicion = Vector2(0, ALTURA_SUELO - 60)
	guardian.limite_caida = 300.0
	guardian.global_position = Vector2(5000, 0)  # lejos del suelo
	await wait_for_signal(guardian.reaparecio, 3.0)
	assert_signal_emitted(guardian, "reaparecio")
	assert_almost_eq(guardian.global_position.x, 0.0, 1.0)


func test_animacion_idle_al_estar_quieto() -> void:
	await _aterrizar()
	await wait_physics_frames(2)
	assert_eq(guardian.sprite.animation, &"idle")


func test_animacion_correr_al_moverse_rapido() -> void:
	await _aterrizar()
	guardian.entrada_direccion = 1.0
	await wait_physics_frames(20)
	assert_eq(guardian.sprite.animation, &"correr")
	assert_true(guardian.sprite.is_playing())


func test_animacion_saltar_y_luego_caer() -> void:
	await _aterrizar()
	guardian.entrada_salto_presionado = true
	guardian.entrada_salto_mantenido = true
	await wait_physics_frames(3)
	assert_eq(guardian.sprite.animation, &"saltar")
	await wait_until(func(): return guardian.velocity.y > 0.0, 2.0)
	await wait_physics_frames(1)
	assert_eq(guardian.sprite.animation, &"caer")


func test_todas_las_animaciones_existen() -> void:
	for nombre in [&"idle", &"caminar", &"correr", &"saltar", &"caer", &"agachar", &"interactuar"]:
		assert_true(guardian.sprite.sprite_frames.has_animation(nombre), "Falta animación: %s" % nombre)


func test_ningun_cuadro_de_animacion_esta_recortado() -> void:
	# Si el dibujo toca el borde de su celda del atlas, se ve cortado en el juego.
	var frames := guardian.sprite.sprite_frames
	for anim in frames.get_animation_names():
		for i in frames.get_frame_count(anim):
			var img := frames.get_frame_texture(anim, i).get_image()
			var w := img.get_width()
			var h := img.get_height()
			assert_gt(w * h, 0, "Cuadro vacío")
			var tocado := false
			for x in w:
				if img.get_pixel(x, 0).a > 0.0:
					tocado = true
			for y in h:
				if img.get_pixel(0, y).a > 0.0 or img.get_pixel(w - 1, y).a > 0.0:
					tocado = true
			assert_false(tocado, "Cuadro %d de '%s' toca el borde de su celda" % [i, anim])


func test_interpolacion_de_fisica_activa() -> void:
	# Sin esto el movimiento se ve a saltos en monitores de más de 60 Hz.
	assert_true(ProjectSettings.get_setting("physics/common/physics_interpolation"))

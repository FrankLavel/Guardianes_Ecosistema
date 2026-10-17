extends GutTest
## Recoger basura con la acción "interactuar" y datos educativos de cada tipo.

const ESCENA_GUARDIAN := preload("res://scenes/player/Guardian.tscn")
const ESCENA_BASURA := preload("res://scenes/world/Basura.tscn")
const TIPOS := ["botella", "lata", "bolsa", "pila", "unicel"]

var guardian: Guardian
var basura: Basura


func before_each() -> void:
	var suelo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	forma.shape = rect
	forma.position = Vector2(0, 20)
	suelo.add_child(forma)
	add_child_autofree(suelo)

	guardian = ESCENA_GUARDIAN.instantiate()
	guardian.leer_entrada_del_jugador = false
	guardian.position = Vector2(0, -10)
	add_child_autofree(guardian)

	basura = ESCENA_BASURA.instantiate()
	basura.tipo = "lata"
	basura.position = Vector2(20, 0)
	add_child_autofree(basura)
	await wait_until(func(): return guardian.is_on_floor(), 2.0)
	await wait_physics_frames(2)


func test_cada_tipo_tiene_nombre_y_dato_educativo() -> void:
	for tipo in TIPOS:
		var datos := DatosBasura.obtener(tipo)
		assert_ne(str(datos.get("nombre", "")), "", "Falta nombre: %s" % tipo)
		assert_gt(str(datos.get("dato", "")).length(), 20, "Falta dato educativo: %s" % tipo)
		assert_true(ResourceLoader.exists("res://assets/objects/basura/%s.png" % tipo), "Falta imagen: %s" % tipo)


func test_muestra_aviso_cuando_el_guardian_esta_cerca() -> void:
	assert_true(basura.get_node("Aviso").visible)
	assert_eq(guardian.interactuable_mas_cercano(), basura)


func test_recoge_la_basura_al_interactuar() -> void:
	watch_signals(basura)
	guardian.entrada_interactuar = true
	await wait_physics_frames(2)
	assert_signal_emitted(basura, "recogida")
	assert_true(basura.fue_recogida)
	assert_eq(guardian.sprite.animation, &"interactuar")


func test_no_se_mueve_mientras_interactua() -> void:
	guardian.entrada_interactuar = true
	await wait_physics_frames(1)
	guardian.entrada_direccion = 1.0
	var x := guardian.global_position.x
	await wait_physics_frames(5)
	assert_almost_eq(guardian.global_position.x, x, 0.5)


func test_no_se_puede_recoger_dos_veces() -> void:
	watch_signals(basura)
	basura.interactuar(guardian)
	basura.interactuar(guardian)
	assert_signal_emit_count(basura, "recogida", 1)


func test_interactuar_sin_nada_cerca_no_hace_nada() -> void:
	basura.interactuar(guardian)  # ya no está disponible
	await wait_physics_frames(1)
	guardian.entrada_interactuar = true
	await wait_physics_frames(2)
	assert_false(guardian.esta_interactuando())


func test_ninguna_basura_es_desproporcionada() -> void:
	# Regresión: la lata (acostada) medía más de la mitad del personaje.
	for tipo in TIPOS:
		var b: Basura = ESCENA_BASURA.instantiate()
		b.tipo = tipo
		add_child_autofree(b)
		var sprite: Sprite2D = b.get_node("Sprite2D")
		var tam: Vector2 = sprite.texture.get_size() * sprite.scale
		assert_lt(maxf(tam.x, tam.y), 30.0, "%s mide %s" % [tipo, tam])
		assert_gt(maxf(tam.x, tam.y), 12.0, "%s mide %s" % [tipo, tam])

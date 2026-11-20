extends GutTest
## En el celular los mensajes no hablan de teclas sino de los botones en pantalla.


func test_cambia_las_teclas_por_los_botones() -> void:
	assert_eq(TextosTactiles.cambiar("E  Hablar"), "Hablar")
	assert_eq(TextosTactiles.cambiar("Acércate a la basura y presiona E para recogerla."),
		"Acércate a la basura y toca el botón de la mano para recogerla.")
	assert_eq(TextosTactiles.cambiar("Come algo de tu mochila (I)."), "Come algo de tu mochila (botón de la mochila).")
	assert_eq(TextosTactiles.cambiar("Presiona ← y → (o A y D) una y otra vez, o haz clic a cada lado."),
		"Toca un lado y luego el otro, una y otra vez.")


func test_no_toca_los_demas_textos() -> void:
	for texto in ["Especies descubiertas: 3 / 14", "Elote asado", "ESPACIO para todos", "Echa leña"]:
		assert_eq(TextosTactiles.cambiar(texto), texto)


func test_todos_los_avisos_de_teclas_tienen_cambio() -> void:
	for texto in Granja.INSTRUCCION.values():
		assert_false(TextosTactiles.cambiar(texto).contains("Presiona"), texto)

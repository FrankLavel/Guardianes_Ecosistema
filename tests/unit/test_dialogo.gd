extends GutTest
## Cuadro de diálogo: muestra las líneas en orden, bloquea el movimiento y avisa al terminar.


func after_each() -> void:
	Juego.entrada_bloqueada = false


func test_los_dialogos_del_valle_existen_y_tienen_personaje() -> void:
	for id in ["don_chucho_inicio", "don_chucho_repetir", "don_chucho_rio_limpio", "entrada_bloqueada_bosque", "entrada_bloqueada_lago"]:
		assert_true(Dialogo.existe(id), "Falta el diálogo %s" % id)
		for linea in Dialogo.lineas_de(id):
			assert_ne(str(linea.get("texto", "")), "")
			assert_has(Dialogo._datos["personajes"], linea.get("quien", ""))


func test_recorre_las_lineas_y_termina() -> void:
	watch_signals(Dialogo)
	var lineas := Dialogo.lineas_de("don_chucho_inicio").size()
	Dialogo.mostrar("don_chucho_inicio")
	assert_true(Dialogo.activo)
	assert_true(Juego.entrada_bloqueada, "Nadie se mueve durante el diálogo")
	# Cada línea: un toque completa el texto y otro pasa a la siguiente.
	for i in lineas * 2:
		Dialogo.avanzar()
	await wait_for_signal(Dialogo.terminado, 1.0)
	assert_false(Dialogo.activo)
	assert_false(Juego.entrada_bloqueada)
	assert_signal_emitted_with_parameters(Dialogo, "terminado", ["don_chucho_inicio"])
	assert_has(Juego.dialogos_vistos, "don_chucho_inicio")

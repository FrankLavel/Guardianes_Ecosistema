extends GutTest
## Pantalla de elección de personaje.

const ESCENA := preload("res://scenes/menu/SeleccionPersonaje.tscn")

var pantalla: Control


func before_each() -> void:
	pantalla = add_child_autofree(ESCENA.instantiate())


func test_empieza_con_el_nino_y_su_nombre_sugerido() -> void:
	assert_eq(pantalla.genero, "nino")
	assert_eq(pantalla.get_node("%Nombre").text, Juego.PERSONAJES["nino"]["nombre_sugerido"])


func test_elegir_nina_cambia_la_seleccion_y_la_sugerencia() -> void:
	pantalla.elegir("nina")
	assert_eq(pantalla.genero, "nina")
	assert_true(pantalla.get_node("%BtnNina").button_pressed)
	assert_false(pantalla.get_node("%BtnNino").button_pressed)
	assert_eq(pantalla.get_node("%Nombre").text, Juego.PERSONAJES["nina"]["nombre_sugerido"])


func test_un_nombre_escrito_no_se_borra_al_cambiar_de_personaje() -> void:
	pantalla.get_node("%Nombre").text = "Mateo"
	pantalla.elegir("nina")
	assert_eq(pantalla.get_node("%Nombre").text, "Mateo")

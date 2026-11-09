extends GutTest
## Verifica que las escenas a las que navega el juego existan y se puedan cargar.
## La comparación de nombres distingue mayúsculas: en Windows "nivel1.tscn"
## funciona en el editor, pero falla en Linux y en los builds exportados.

const MenuPrincipal = preload("res://scripts/menu_principal.gd")
const Opciones = preload("res://scripts/opciones.gd")
const RUTAS_EXTRA := [
	"res://scenes/valle/Valle.tscn",
	"res://scenes/valle/Casa.tscn",
	"res://scenes/world/Nivel2.tscn",
	"res://scenes/world/Nivel3.tscn",
	"res://scenes/ui/Final.tscn",
	"res://scenes/ui/Bitacora.tscn",
	"res://scenes/menu/SeleccionPersonaje.tscn",
	"res://scenes/ui/MenuPausa.tscn",
	"res://scenes/ui/Dialogo.tscn",
	"res://scenes/systems/Transicion.tscn",
]


func _existe_con_mayusculas_exactas(ruta: String) -> bool:
	return ruta.get_file() in DirAccess.get_files_at(ruta.get_base_dir())


func test_escena_principal_configurada_carga() -> void:
	var ruta: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_ne(ruta, "", "El proyecto no tiene escena principal configurada")
	assert_not_null(load(ruta), "No se pudo cargar la escena principal: %s" % ruta)


func test_rutas_de_navegacion_existen() -> void:
	for ruta in [MenuPrincipal.ESCENA_VALLE, MenuPrincipal.ESCENA_NIVEL1, MenuPrincipal.ESCENA_OPCIONES, MenuPrincipal.ESCENA_SELECCION,
			Opciones.ESCENA_MENU, NivelCompletado.ESCENA_VALLE, MenuPausa.ESCENA_VALLE, MenuPausa.ESCENA_MENU] + RUTAS_EXTRA:
		assert_true(_existe_con_mayusculas_exactas(ruta), "La escena no existe (revisar mayúsculas): %s" % ruta)


func test_rutas_de_navegacion_se_pueden_instanciar() -> void:
	for ruta in [MenuPrincipal.ESCENA_VALLE, MenuPrincipal.ESCENA_NIVEL1, MenuPrincipal.ESCENA_OPCIONES] + RUTAS_EXTRA:
		var escena: PackedScene = load(ruta)
		assert_not_null(escena, "No se pudo cargar: %s" % ruta)
		if escena:
			var nodo := escena.instantiate()
			assert_not_null(nodo, "No se pudo instanciar: %s" % ruta)
			nodo.free()


## (No se toca ninguna partida guardada: se abre el aviso directamente.)
func test_el_aviso_de_nueva_partida_deja_regresar() -> void:
	var menu = add_child_autofree(preload("res://scenes/menu/menu_principal.tscn").instantiate())
	await wait_process_frames(2)
	menu._confirmar_nueva()
	assert_not_null(menu._confirmacion, "Avisa que se va a borrar el progreso")
	assert_true(menu._confirmacion.find_child("BtnNo", true, false).has_focus(), "Lo seguro queda seleccionado")
	menu._confirmacion.find_child("BtnNo", true, false).pressed.emit()
	await wait_process_frames(2)
	assert_null(menu._confirmacion, "NO regresa al menú")

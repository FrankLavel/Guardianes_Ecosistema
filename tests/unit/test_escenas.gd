extends GutTest
## Verifica que las escenas a las que navega el juego existan y se puedan cargar.
## La comparación de nombres distingue mayúsculas: en Windows "nivel1.tscn"
## funciona en el editor, pero falla en Linux y en los builds exportados.

const MenuPrincipal = preload("res://scripts/menu_principal.gd")
const Opciones = preload("res://scripts/opciones.gd")
const RUTAS_EXTRA := [
	"res://scenes/valle/Valle.tscn",
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
	for ruta in [MenuPrincipal.ESCENA_VALLE, MenuPrincipal.ESCENA_NIVEL1, MenuPrincipal.ESCENA_OPCIONES,
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

extends GutTest
## Puzzles de la Zona 1: compuertas y filtro de agua.

const ESCENA_COMPUERTAS := preload("res://scenes/puzzles/PuzzleCompuertas.tscn")
const ESCENA_FILTRO := preload("res://scenes/puzzles/PuzzleFiltro.tscn")


## Los puzzles pausan el juego; con el árbol en pausa GUT tampoco avanza, así que en las pruebas
## se quita la pausa justo después de abrirlos (el puzzle sigue funcionando: no se pausa).
func _sin_pausa() -> void:
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false
	Juego.entrada_bloqueada = false


# ------------------------------------------------------------------ compuertas

func _compuertas() -> PuzzleCompuertas:
	var p: PuzzleCompuertas = add_child_autofree(ESCENA_COMPUERTAS.instantiate())
	p.abrir()
	_sin_pausa()
	return p


func _fijar(p: PuzzleCompuertas, a: bool, b: bool, c: bool) -> void:
	for datos in [["a", a], ["b", b], ["c", c]]:
		if p.valvulas[datos[0]] != datos[1]:
			p.alternar(datos[0])


func test_abrir_un_puzzle_pausa_y_bloquea_el_movimiento() -> void:
	var p: PuzzleCompuertas = add_child_autofree(ESCENA_COMPUERTAS.instantiate())
	p.abrir()
	var pausado := get_tree().paused
	_sin_pausa()
	assert_true(pausado)
	assert_true(Juego.entrada_bloqueada)
	p.cerrar()
	await wait_process_frames(2)
	assert_false(get_tree().paused)
	assert_false(Juego.entrada_bloqueada)


func test_cada_combinacion_equivocada_explica_el_problema() -> void:
	var p := _compuertas()
	var casos := {
		[true, false, false]: "sucia_al_rio",
		[true, true, true]: "sucia_al_rio",
		[false, false, false]: "sin_salida",
		[false, false, true]: "sin_salida",
		[false, true, false]: "planta_llena",
	}
	for combinacion in casos:
		_fijar(p, combinacion[0], combinacion[1], combinacion[2])
		assert_eq(p.calcular()["resultado"], casos[combinacion], str(combinacion))


func test_la_solucion_manda_el_agua_por_la_planta() -> void:
	var p := _compuertas()
	_fijar(p, false, true, true)
	var calculo := p.calcular()
	assert_eq(calculo["resultado"], "bien")
	assert_eq(calculo["colores"]["c"], PuzzleCompuertas.COLOR_LIMPIA, "Al río llega agua limpia")
	assert_false(calculo["colores"].has("a"), "No llega agua sucia directo al río")


func test_resolver_las_compuertas_avisa() -> void:
	var p := _compuertas()
	watch_signals(p)
	_fijar(p, false, true, true)
	p.abrir_agua()
	await wait_for_signal(p.resuelto, 3.0)
	assert_signal_emitted(p, "resuelto")
	assert_true(p.esta_resuelto)


func test_un_intento_fallido_no_resuelve() -> void:
	var p := _compuertas()
	watch_signals(p)
	_fijar(p, true, false, false)
	p.abrir_agua()
	await wait_seconds(1.2)
	assert_signal_not_emitted(p, "resuelto")
	assert_string_contains(p.mensaje.text, "río")


# ------------------------------------------------------------------ filtro

func _filtro() -> PuzzleFiltro:
	var p: PuzzleFiltro = add_child_autofree(ESCENA_FILTRO.instantiate())
	p.abrir()
	_sin_pausa()
	return p


func test_el_filtro_se_arma_de_abajo_hacia_arriba() -> void:
	assert_eq(PuzzleFiltro.ORDEN, ["algodon", "carbon", "arena", "grava"])


func test_una_capa_equivocada_se_rechaza_con_una_pista() -> void:
	var p := _filtro()
	p.poner("grava")
	assert_eq(p.capas.size(), 0, "La grava no puede ir hasta abajo")
	assert_string_contains(p.mensaje.text, "suave", "La pista habla del algodón")


func test_armar_el_filtro_completo_lo_resuelve() -> void:
	var p := _filtro()
	watch_signals(p)
	for material in PuzzleFiltro.ORDEN:
		p.poner(material)
	await wait_for_signal(p.resuelto, 4.0)
	assert_signal_emitted(p, "resuelto")
	assert_eq(p.capas, ["algodon", "carbon", "arena", "grava"] as Array[String])
	assert_true(p.get_node("%GotaLimpia").visible, "Sale una gota limpia")


func test_reiniciar_vacia_el_filtro() -> void:
	var p := _filtro()
	p.poner("algodon")
	p.reiniciar()
	assert_eq(p.capas.size(), 0)
	assert_false(p.get_node("%CartaAlgodon").disabled)


# ------------------------------------------------------------------ reforestar y hábitats

const ESCENA_REFORESTAR := preload("res://scenes/puzzles/PuzzleReforestar.tscn")
const ESCENA_HABITAT := preload("res://scenes/puzzles/PuzzleHabitat.tscn")


func _asignar_puzzle(escena: PackedScene) -> PuzzleAsignar:
	var p: PuzzleAsignar = add_child_autofree(escena.instantiate())
	p.abrir()
	_sin_pausa()
	return p


func test_reforestar_rechaza_el_arbol_en_el_lugar_equivocado() -> void:
	var p := _asignar_puzzle(ESCENA_REFORESTAR)
	assert_false(p.asignar("encino", "arriba"))
	assert_string_contains(p.mensaje.text, "parte baja")
	assert_eq(p.colocadas.size(), 0)


func test_reforestar_cada_arbol_a_su_altura_lo_resuelve() -> void:
	Juego.nueva_partida(93)
	var p := _asignar_puzzle(ESCENA_REFORESTAR)
	watch_signals(p)
	assert_true(p.asignar("oyamel", "arriba"))
	assert_true(p.asignar("pino", "medio"))
	assert_true(p.asignar("encino", "abajo"))
	assert_signal_emitted(p, "resuelto")
	assert_has(Juego.especies_descubiertas, "oyamel", "Se registra en la bitácora")
	Juego.nueva_partida()


func test_habitat_cada_animal_a_su_lugar() -> void:
	Juego.nueva_partida(93)
	var p := _asignar_puzzle(ESCENA_HABITAT)
	watch_signals(p)
	assert_false(p.asignar("venado", "copa"), "El venado no vive en la copa")
	assert_true(p.asignar("monarca", "copa"))
	assert_true(p.asignar("carpintero", "tronco"))
	assert_true(p.asignar("venado", "suelo"))
	assert_signal_emitted(p, "resuelto")
	assert_has(Juego.especies_descubiertas, "monarca")
	Juego.nueva_partida()


func test_elegir_una_tarjeta_y_luego_el_lugar() -> void:
	var p := _asignar_puzzle(ESCENA_REFORESTAR)
	p.colocar_en("arriba")
	assert_string_contains(p.mensaje.text, "Primero elige")
	p.elegir("oyamel")
	p.colocar_en("arriba")
	assert_eq(p.colocadas.get("arriba"), "oyamel")

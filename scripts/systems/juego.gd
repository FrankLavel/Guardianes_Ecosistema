extends Node
## Estado de la partida (autoload "Juego"): progreso de zonas, guardado y carga.
##
## La partida se guarda en user://partida_<ranura>.json. Se guarda sola al entrar y salir de
## una zona y al completar una zona (CP-09, CP-10).

signal zona_completada(zona: String)
signal partida_cargada
signal hojas_cambiaron(total: int)
## Cambia la hora entera (para el reloj de la interfaz) y cuando empieza o acaba la noche.
signal hora_cambio(hora: int)
signal noche_cambio(es_noche: bool)
signal dia_cambio(dia: int)

## Orden de las zonas: cada una se desbloquea al completar la anterior.
const ZONAS := ["rio", "bosque", "lago"]
const VERSION_GUARDADO := 7
## La energía (0-100) se acaba en este número de horas del juego si no se come nada.
const HORAS_DE_ENERGIA := 36.0
## Reloj del valle: un día completo dura 24 * SEGUNDOS_POR_HORA (unos 12 minutos).
const SEGUNDOS_POR_HORA := 30.0
const EMPIEZA_NOCHE := 20.0
const EMPIEZA_DIA := 6.0
const HORA_DESPERTAR := 7.0
const COLOR_NOCHE := Color(0.5, 0.56, 0.82)
const COLOR_ATARDECER := Color(1.0, 0.82, 0.68)
## Habilidad que se gana al restaurar cada zona.
const HABILIDAD_POR_ZONA := {"rio": "nadar", "bosque": "enredaderas"}

## Personajes que se pueden elegir. "plataformas" vacío = todavía no hay arte lateral propio
## y se usa el del niño mientras tanto.
const PERSONAJES := {
	"nino": {
		"aereo": "res://assets/characters/gara/aerea/gara_aerea_frames.tres",
		"plataformas": "res://assets/characters/gara/gara_frames.tres",
		"retrato": "res://assets/characters/gara/gara_retrato.png",
		"nombre_sugerido": "Gara",
	},
	"nina": {
		"aereo": "res://assets/characters/nina/aerea/nina_aerea_frames.tres",
		"plataformas": "res://assets/characters/nina/nina_frames.tres",
		"retrato": "res://assets/characters/nina/nina_retrato.png",
		"nombre_sugerido": "",
	},
}

## Palabras que cambian según el personaje elegido. En los textos se escriben entre llaves:
## "¡Gracias, {guardian}!" -> "¡Gracias, guardián!" / "¡Gracias, guardiana!"
const PALABRAS := {
	"guardian": ["guardián", "guardiana"],
	"Guardian": ["Guardián", "Guardiana"],
	"muchacho": ["muchacho", "muchacha"],
	"el": ["el", "la"],
	"nuevo": ["nuevo", "nueva"],
	"o": ["o", "a"],
}

var ranura := 1
## Hay una partida en juego (empezada o cargada): solo entonces se guarda sola (ver _notification).
var partida_activa := false
## Cada cuánto se guarda sola mientras se juega en el valle o la casa (segundos reales).
const GUARDADO_AUTOMATICO := 60.0
var _desde_guardado := 0.0
## "nino" o "nina".
var genero := "nino"
var nombre := ""
var zonas_completadas: Array[String] = []
var especies_descubiertas: Array[String] = []
var dialogos_vistos: Array[String] = []
## Metas dentro de una zona ("rio_nivel", "rio_compuertas"...).
var marcas: Array[String] = []
var habilidades: Array[String] = []
## Posición de Gara en el valle para volver al mismo lugar al salir de una zona.
var posicion_valle := Vector2.ZERO
var tiene_posicion_valle := false

## Después del final: hojas que regalan los animales al ayudarlos (se gastan en muebles),
## cuántas veces se ayudó con cada tipo de pedido, muebles comprados para la casa y el pedido
## de ayuda en curso ({} si no hay).
var hojas := 0
var ayudas: Dictionary = {}
var muebles: Array[String] = []
var pedido: Dictionary = {}
## Hora del juego (ver horas_totales) en que un animal vuelve a pedir ayuda; -1 si no se ha decidido.
var siguiente_pedido := -1.0
var dia := 1
## Granja (ver granja.gd): objeto -> cantidad, parcelas de la milpa, energía del guardián,
## platillos ya cocinados, corral (animal -> {"comio": día, "listo": bool}), pesca del día y
## plantas silvestres que hay hoy en el valle ({"tipo", "pos"}).
var inventario: Dictionary = {}
var parcelas: Array = []
var energia := 100.0
var recetario: Array[String] = []
var corral: Dictionary = {}
## Animales que se compraron en el tianguis (una entrada por animal, con su especie).
var comprados: Array[String] = []
var pesca: Dictionary = {"dia": 0, "veces": 0}
var silvestres: Array = []
var silvestres_dia := 0
## Talleres (molino, quesería, colmena): id -> {"horas", "trabajando", "listo"}.
var talleres: Dictionary = {}
## Fogón de la casa: si está prendido y cuántas horas de juego de leña le quedan.
var fogon: Dictionary = {"prendido": false, "horas": 0.0}
## Decoraciones de la granja: "puestas" ([{"id", "x", "y"}] en el valle) y "guardadas" (id -> cuántas).
var decoraciones: Dictionary = {"puestas": [], "guardadas": {}}
## Dónde puso el jugador el corral y los talleres (id -> [x, y]); si no está, va en su lugar de siempre.
var posiciones: Dictionary = {}
## Terrenos del valle que se compraron para agrandar la granja ("columna,fila"; ver Granja.expandir).
var terrenos: Array[String] = []
## Cuadros de la milpa que puso el jugador ("columna,fila"; la parcela i está en el cuadro i) y si ya
## se pusieron los de siempre. Árboles frutales plantados ({"id", "x", "y", "etapa", "horas", "abonado"}).
var milpa: Array[String] = []
var milpa_lista := false
var frutales: Array = []
## Caminos que pintó el jugador ("columna,fila" -> "arena" o "piedra"; ver Granja.poner_camino) y si ya
## se pusieron los caminos rectos de siempre (al crear la granja).
var caminos: Dictionary = {}
var caminos_listos := false
## Experiencia de la granja (el nivel se calcula con Granja.nivel()) y pedidos del tianguis.
var xp := 0
var tianguis: Array = []
## De 0 a 24. Solo avanza en las escenas del grupo "con_reloj" (el valle y la casa).
var hora := 8.0
var es_de_noche: bool:
	get:
		return hora >= EMPIEZA_NOCHE or hora < EMPIEZA_DIA
	set(valor):
		hora = 22.0 if valor else 8.0

## Mientras haya un diálogo o menú abierto, los personajes no se mueven.
var entrada_bloqueada := false


func nueva_partida(nueva_ranura := 1, nuevo_genero := "nino", nuevo_nombre := "") -> void:
	ranura = nueva_ranura
	partida_activa = true
	genero = nuevo_genero if nuevo_genero in PERSONAJES else "nino"
	nombre = nuevo_nombre.strip_edges()
	zonas_completadas.clear()
	especies_descubiertas.clear()
	dialogos_vistos.clear()
	marcas.clear()
	habilidades.clear()
	tiene_posicion_valle = false
	posicion_valle = Vector2.ZERO
	hojas = 0
	ayudas.clear()
	muebles.clear()
	siguiente_pedido = -1.0
	pedido.clear()
	dia = 1
	hora = 8.0
	inventario.clear()
	parcelas.clear()
	energia = 100.0
	recetario.clear()
	corral.clear()
	comprados.clear()
	talleres.clear()
	fogon = {"prendido": false, "horas": 0.0}
	decoraciones = {"puestas": [], "guardadas": {}}
	posiciones.clear()
	terrenos.clear()
	milpa.clear()
	milpa_lista = false
	frutales.clear()
	caminos.clear()
	caminos_listos = false
	pesca = {"dia": 0, "veces": 0}
	silvestres.clear()
	silvestres_dia = 0
	xp = 0
	tianguis.clear()


func datos_personaje() -> Dictionary:
	return PERSONAJES[genero]


## Nombre que escribió el jugador o, si lo dejó vacío, "Guardián"/"Guardiana".
func nombre_jugador() -> String:
	return nombre if not nombre.is_empty() else reemplazar("{Guardian}")


## Sustituye {nombre} y las palabras de PALABRAS según el personaje elegido.
func reemplazar(texto: String) -> String:
	var indice := 0 if genero == "nino" else 1
	for clave in PALABRAS:
		texto = texto.replace("{%s}" % clave, PALABRAS[clave][indice])
	if texto.contains("{nombre}"):
		texto = texto.replace("{nombre}", nombre_jugador())
	return texto


func zona_desbloqueada(zona: String) -> bool:
	var indice := ZONAS.find(zona)
	if indice <= 0:
		return indice == 0
	return ZONAS[indice - 1] in zonas_completadas


func zona_esta_completa(zona: String) -> bool:
	return zona in zonas_completadas


func completar_zona(zona: String) -> void:
	if zona in zonas_completadas:
		return
	zonas_completadas.append(zona)
	if HABILIDAD_POR_ZONA.has(zona):
		dar_habilidad(HABILIDAD_POR_ZONA[zona])
	zona_completada.emit(zona)
	guardar()


## El tiempo solo corre en el valle y la casa, y no con un menú o diálogo abierto.
func reloj_corre() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.is_in_group(&"con_reloj") and not get_tree().paused and not entrada_bloqueada


func _process(delta: float) -> void:
	if not reloj_corre():
		return
	_desde_guardado += delta
	if _desde_guardado >= GUARDADO_AUTOMATICO:
		guardar()
	avanzar_hora(delta / SEGUNDOS_POR_HORA)
	# Después del final el guardián se cansa poco a poco (comer recupera la energía).
	if juego_terminado():
		energia = maxf(energia - delta / SEGUNDOS_POR_HORA * 100.0 / HORAS_DE_ENERGIA, 0.0)


func avanzar_hora(horas: float) -> void:
	var noche_antes := es_de_noche
	var entera := int(hora)
	if hora + horas >= 24.0:
		dia += 1
		dia_cambio.emit(dia)
	hora = fmod(hora + horas, 24.0)
	if int(hora) != entera:
		hora_cambio.emit(int(hora))
	if es_de_noche != noche_antes:
		noche_cambio.emit(es_de_noche)


## Horas de juego desde que empezó la partida (no se reinicia cada día).
func horas_totales() -> float:
	return (dia - 1) * 24.0 + hora


## Dormir en la cama: empieza un día nuevo en la mañana.
func pasar_la_noche() -> void:
	# Si ya pasó la medianoche, el día ya cambió.
	if hora >= EMPIEZA_NOCHE:
		dia += 1
		dia_cambio.emit(dia)
	hora = HORA_DESPERTAR
	hora_cambio.emit(int(hora))
	noche_cambio.emit(false)


## "7 de la mañana", "12 del día", "3 de la tarde", "9 de la noche".
func texto_hora() -> String:
	var h := int(hora)
	if h == 12:
		return "12 del día"
	var parte := "de la mañana" if h >= 6 and h < 12 else ("de la tarde" if h >= 12 and h < 19 else "de la noche")
	var doce := h % 12
	return "%d %s" % [12 if doce == 0 else doce, parte]


## Color del mundo según la hora: día normal, atardecer naranja, noche azul y amanecer.
func color_del_cielo() -> Color:
	if hora >= 7.0 and hora < 17.0:
		return Color.WHITE
	if hora >= 17.0 and hora < 18.5:
		return Color.WHITE.lerp(COLOR_ATARDECER, (hora - 17.0) / 1.5)
	if hora >= 18.5 and hora < EMPIEZA_NOCHE:
		return COLOR_ATARDECER.lerp(COLOR_NOCHE, (hora - 18.5) / (EMPIEZA_NOCHE - 18.5))
	if hora >= 5.0 and hora < 7.0:
		return COLOR_NOCHE.lerp(Color.WHITE, (hora - 5.0) / 2.0)
	return COLOR_NOCHE


## Las tres zonas restauradas: empieza la parte libre (animales que piden ayuda, la casa).
func juego_terminado() -> bool:
	return zonas_completadas.size() == ZONAS.size()


func dar_hojas(cantidad: int) -> void:
	hojas += cantidad
	hojas_cambiaron.emit(hojas)


## Devuelve false (y no gasta nada) si no alcanzan.
func gastar_hojas(cantidad: int) -> bool:
	if cantidad > hojas:
		return false
	hojas -= cantidad
	hojas_cambiaron.emit(hojas)
	return true


func contar_ayuda(tipo: String) -> void:
	ayudas[tipo] = int(ayudas.get(tipo, 0)) + 1


func total_ayudas() -> int:
	var total := 0
	for tipo in ayudas:
		total += int(ayudas[tipo])
	return total


## De 0 a 1: qué tanto del valle está restaurado.
func progreso() -> float:
	return float(zonas_completadas.size()) / ZONAS.size()


func marcar(id: String) -> void:
	if id not in marcas:
		marcas.append(id)


func tiene_marca(id: String) -> bool:
	return id in marcas


func dar_habilidad(id: String) -> void:
	if id not in habilidades:
		habilidades.append(id)


func tiene_habilidad(id: String) -> bool:
	return id in habilidades


func marcar_dialogo_visto(id: String) -> void:
	if id not in dialogos_vistos:
		dialogos_vistos.append(id)


func descubrir_especie(id: String) -> void:
	if id not in especies_descubiertas:
		especies_descubiertas.append(id)


# ---------------------------------------------------------------- Guardado

static func ruta_ranura(numero: int) -> String:
	return "user://partida_%d.json" % numero


static func existe_partida(numero := 1) -> bool:
	return FileAccess.file_exists(ruta_ranura(numero)) or FileAccess.file_exists(ruta_ranura(numero) + ".bak")


## En el celular la app se puede cerrar en cualquier momento: se guarda al mandarla a segundo plano,
## al cerrarla y con el botón "atrás" (que abre la pausa en lugar de salir del juego).
func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			if partida_activa:
				guardar()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_atras()


## Botón "atrás" de Android: en el juego hace lo mismo que Esc (cierra lo abierto o abre la pausa); en el
## menú principal sale del juego.
func _atras() -> void:
	var escena := get_tree().current_scene
	if escena == null or not escena.is_in_group(&"jugable"):
		if partida_activa:
			guardar()
		get_tree().quit()
		return
	if partida_activa:
		guardar()
	for presionado in [true, false]:
		var evento := InputEventAction.new()
		evento.action = &"pausa"
		evento.pressed = presionado
		Input.parse_input_event(evento)


func a_diccionario() -> Dictionary:
	return {
		"version": VERSION_GUARDADO,
		"genero": genero,
		"nombre": nombre,
		"zonas_completadas": zonas_completadas,
		"especies_descubiertas": especies_descubiertas,
		"dialogos_vistos": dialogos_vistos,
		"marcas": marcas,
		"habilidades": habilidades,
		"posicion_valle": [posicion_valle.x, posicion_valle.y] if tiene_posicion_valle else null,
		"hojas": hojas,
		"ayudas": ayudas,
		"muebles": muebles,
		"siguiente_pedido": siguiente_pedido,
		"pedido": pedido,
		"dia": dia,
		"hora": hora,
		"inventario": inventario,
		"parcelas": parcelas,
		"energia": energia,
		"recetario": recetario,
		"corral": corral,
		"comprados": comprados,
		"talleres": talleres,
		"fogon": fogon,
		"decoraciones": decoraciones,
		"posiciones": posiciones,
		"terrenos": terrenos,
		"milpa": milpa,
		"milpa_lista": milpa_lista,
		"frutales": frutales,
		"caminos": caminos,
		"caminos_listos": caminos_listos,
		"pesca": pesca,
		"silvestres": silvestres.map(func(s): return {"tipo": s["tipo"], "pos": [s["pos"].x, s["pos"].y]}),
		"silvestres_dia": silvestres_dia,
		"xp": xp,
		"tianguis": tianguis,
	}


func desde_diccionario(datos: Dictionary) -> void:
	genero = datos.get("genero", "nino")
	if genero not in PERSONAJES:
		genero = "nino"
	nombre = datos.get("nombre", "")
	zonas_completadas.assign(datos.get("zonas_completadas", []))
	especies_descubiertas.assign(datos.get("especies_descubiertas", []))
	dialogos_vistos.assign(datos.get("dialogos_vistos", []))
	marcas.assign(datos.get("marcas", []))
	habilidades.assign(datos.get("habilidades", []))
	var pos = datos.get("posicion_valle")
	tiene_posicion_valle = pos is Array and pos.size() == 2
	posicion_valle = Vector2(pos[0], pos[1]) if tiene_posicion_valle else Vector2.ZERO
	# Partidas de antes de la versión 4 no tienen estos datos.
	hojas = int(datos.get("hojas", 0))
	ayudas = datos.get("ayudas", {}) if datos.get("ayudas") is Dictionary else {}
	muebles.assign(datos.get("muebles", []))
	siguiente_pedido = float(datos.get("siguiente_pedido", -1.0))
	pedido = datos.get("pedido", {}) if datos.get("pedido") is Dictionary else {}
	dia = int(datos.get("dia", 1))
	hora = float(datos.get("hora", 22.0 if datos.get("es_de_noche", false) else 8.0))
	# Granja (partidas de antes de la versión 6 no la tienen). JSON guarda los números como float.
	inventario = {}
	for id in datos.get("inventario", {}):
		inventario[id] = int(datos["inventario"][id])
	parcelas = datos.get("parcelas", []).duplicate(true)
	energia = float(datos.get("energia", 100.0))
	recetario.assign(datos.get("recetario", []))
	corral = datos.get("corral", {}) if datos.get("corral") is Dictionary else {}
	comprados.assign(datos.get("comprados", []))
	talleres = datos.get("talleres", {}).duplicate(true) if datos.get("talleres") is Dictionary else {}
	fogon = datos.get("fogon", {}).duplicate() if datos.get("fogon") is Dictionary else {}
	fogon = {"prendido": bool(fogon.get("prendido", false)), "horas": float(fogon.get("horas", 0.0))}
	var deco: Dictionary = datos.get("decoraciones") if datos.get("decoraciones") is Dictionary else {}
	decoraciones = {"puestas": deco.get("puestas", []).duplicate(true), "guardadas": deco.get("guardadas", {}).duplicate()}
	# Partidas de cuando había lugares fijos: lo que estaba puesto se guarda para ponerlo donde quieran.
	for id in deco.get("lugares", {}).values():
		decoraciones["guardadas"][id] = int(decoraciones["guardadas"].get(id, 0)) + 1
	posiciones = datos.get("posiciones", {}).duplicate(true) if datos.get("posiciones") is Dictionary else {}
	terrenos.assign(datos.get("terrenos", []))
	milpa.assign(datos.get("milpa", []))
	milpa_lista = bool(datos.get("milpa_lista", false))
	frutales = datos.get("frutales", []).duplicate(true) if datos.get("frutales") is Array else []
	caminos = datos.get("caminos", {}).duplicate() if datos.get("caminos") is Dictionary else {}
	caminos_listos = bool(datos.get("caminos_listos", false))
	pesca = datos.get("pesca", {"dia": 0, "veces": 0}) if datos.get("pesca") is Dictionary else {"dia": 0, "veces": 0}
	silvestres = datos.get("silvestres", []).map(func(s): return {"tipo": s["tipo"], "pos": Vector2(s["pos"][0], s["pos"][1])})
	silvestres_dia = int(datos.get("silvestres_dia", 0))
	xp = int(datos.get("xp", 0))
	tianguis = datos.get("tianguis", []).duplicate(true)


## Se escribe primero un archivo aparte y luego se cambia por el bueno; el anterior queda de respaldo
## (.bak). Así, si la app se cierra a medio guardar, la partida no se pierde.
func guardar() -> bool:
	_desde_guardado = 0.0
	var ruta := ruta_ranura(ranura)
	var archivo := FileAccess.open(ruta + ".tmp", FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar la partida: %s" % FileAccess.get_open_error())
		return false
	archivo.store_string(JSON.stringify(a_diccionario(), "\t"))
	archivo.close()
	var global := ProjectSettings.globalize_path(ruta)
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(global + ".bak")
		DirAccess.rename_absolute(global, global + ".bak")
	if DirAccess.rename_absolute(global + ".tmp", global) != OK:
		push_error("No se pudo guardar la partida en %s" % ruta)
		return false
	return true


func cargar(numero := 1) -> bool:
	if not existe_partida(numero):
		return false
	var datos = _leer(ruta_ranura(numero))
	if not datos is Dictionary:
		# Si la partida se dañó, se usa la que se guardó antes.
		datos = _leer(ruta_ranura(numero) + ".bak")
	if not datos is Dictionary:
		push_error("Partida dañada en la ranura %d" % numero)
		return false
	ranura = numero
	partida_activa = true
	desde_diccionario(datos)
	partida_cargada.emit()
	return true


func _leer(ruta: String) -> Variant:
	if not FileAccess.file_exists(ruta):
		return null
	# Sin aviso de error en la consola: que la partida esté dañada se maneja usando el respaldo.
	var json := JSON.new()
	return json.data if json.parse(FileAccess.get_file_as_string(ruta)) == OK else null


func borrar_partida(numero := 1) -> void:
	var global := ProjectSettings.globalize_path(ruta_ranura(numero))
	for final in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ruta_ranura(numero) + final):
			DirAccess.remove_absolute(global + final)
	if numero == ranura:
		partida_activa = false

extends Node
## Estado de la partida (autoload "Juego"): progreso de zonas, guardado y carga.
##
## La partida se guarda en user://partida_<ranura>.json. Se guarda sola al entrar y salir de
## una zona y al completar una zona (CP-09, CP-10).

signal zona_completada(zona: String)
signal partida_cargada
signal hojas_cambiaron(total: int)

## Orden de las zonas: cada una se desbloquea al completar la anterior.
const ZONAS := ["rio", "bosque", "lago"]
const VERSION_GUARDADO := 4
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
var es_de_noche := false

## Mientras haya un diálogo o menú abierto, los personajes no se mueven.
var entrada_bloqueada := false


func nueva_partida(nueva_ranura := 1, nuevo_genero := "nino", nuevo_nombre := "") -> void:
	ranura = nueva_ranura
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
	pedido.clear()
	es_de_noche = false


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
	return FileAccess.file_exists(ruta_ranura(numero))


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
		"pedido": pedido,
		"es_de_noche": es_de_noche,
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
	pedido = datos.get("pedido", {}) if datos.get("pedido") is Dictionary else {}
	es_de_noche = bool(datos.get("es_de_noche", false))


func guardar() -> bool:
	var archivo := FileAccess.open(ruta_ranura(ranura), FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar la partida: %s" % FileAccess.get_open_error())
		return false
	archivo.store_string(JSON.stringify(a_diccionario(), "\t"))
	return true


func cargar(numero := 1) -> bool:
	if not existe_partida(numero):
		return false
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta_ranura(numero)))
	if not datos is Dictionary:
		push_error("Partida dañada en la ranura %d" % numero)
		return false
	ranura = numero
	desde_diccionario(datos)
	partida_cargada.emit()
	return true


func borrar_partida(numero := 1) -> void:
	if existe_partida(numero):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_ranura(numero)))

extends CanvasLayer
## Granja del guardián (autoload "Granja"): milpa, corral, recolección, pesca, cocina y energía.
## El estado vive en Juego (inventario, parcelas, corral...) para que se guarde con la partida.
## Los datos (objetos, cultivos, recetas) están en data/granja.json.
##
##     Granja.dar("maiz", 2)       Granja.plantar(0, "maiz")      Granja.cocinar("atole")
##
## También es el menú de la mochila (tecla I), de la cocina y del tianguis.
##
## Niveles: todo lo que se hace en la granja da experiencia (datos["xp"]); al subir de nivel se
## desbloquean surcos, la cabra, recetas y más pedidos del tianguis (datos["niveles"]).

signal inventario_cambio
signal energia_cambio(valor: float)
signal nivel_subio(nivel: int, texto: String)
signal parcelas_cambio
signal talleres_cambio
signal fogon_cambio
signal corral_cambio
signal terrenos_cambio
signal caminos_cambio
signal milpa_cambio
signal frutales_cambio

const RUTA := "res://data/granja.json"
const ICONO := "res://assets/ui/granja/%s.png"
const PLANTA := "res://assets/objects/granja/%s_%d.png"
## Surcos de la milpa: se empieza con 6 y se desbloquean más al subir de nivel.
const PARCELAS_MAX := 12
## La milpa son cuadros de 136 x 96 que pone el jugador (cuántos, según su nivel). La cuadrícula empieza
## donde estaba la milpa de siempre, así los primeros cuadros quedan en el mismo lugar.
const CELDA_MILPA := Vector2(136, 96)
const ORIGEN_MILPA := Vector2(1488, 246)
## Etapas de los árboles frutales: 0 arbolito, 1 joven, 2 adulto, 3 con fruta.
const ADULTO := 2
const CON_FRUTA := 3
## Etapa final de un cultivo (0 sembrado, 1 y 2 creciendo, 3 listo para cosechar).
const LISTO := 3
const PESCA_POR_DIA := 3
## Probabilidad de que lo que pica sea una cría (se regresa al agua).
const PROB_CRIA := 0.3
const SILVESTRES_POR_DIA := 6
## Tandas que un taller guarda listas antes de pararse (la colmena deja de hacer miel si no la recoges).
const TANDAS_MAX := 3
## Cuántos animales de cada especie caben en su corral y cuánto más rápido se camina con caballo.
const ANIMALES_POR_ESPECIE := 4
const VELOCIDAD_CABALLO := 1.35
const CUADROS_ANIMAL := "res://assets/characters/animales/valle/%s_frames.tres"
## El valle (2800 x 1800) en terrenos de 350 x 300. La granja empieza con los del centro (donde están la
## casa, la milpa, el corral, los talleres y el tianguis) y crece comprando los de al lado.
const TERRENO := Vector2(350, 300)
const COLUMNAS_TERRENO := 8
const FILAS_TERRENO := 6
const TERRENOS_INICIALES := Rect2i(2, 0, 5, 5)
const HOJA := preload("res://assets/ui/iconos/escalado/icono_hoja.png")
## Caminos: cuadritos de 50 px (los mismos de la cuadrícula del modo decorar). El de tierra es gratis y el
## de piedra cuesta una hoja por cuadrito.
const CELDA_CAMINO := 50.0
const CAMINOS := {
	"arena": {"nombre": "Camino de tierra", "costo": 0, "dato": "Gratis. Así eran los caminos del campo."},
	"piedra": {"nombre": "Camino de piedra", "costo": 1, "dato": "Una hoja por cuadrito. El empedrado no se hace lodo cuando llueve."},
}
## Horas de juego que arde un leño (4 h = 2 minutos reales) y cuántos caben en el fogón.
const HORAS_POR_LENO := 4.0
const LENOS_MAX := 3

var datos: Dictionary = {}
var abierto := ""

## Donde vuelan los productos recogidos (esquina del panel del valle, junto a "Hojas").
const DESTINO_RECOGIDOS := Vector2(140, 90)
const FOGON := preload("res://assets/maps/casa/fogon.png")
const FOGON_APAGADO := preload("res://assets/maps/casa/fogon_apagado.png")
const PUESTO := preload("res://assets/maps/valle/objetos/tianguis.png")
## Quién hace los pedidos del tianguis.
const VECINOS := ["Doña Rosa", "Don Tacho", "Doña Chela", "Don Lencho", "Doña Mari", "Don Pancho", "Doña Lupe", "Don Beto"]
## Cómo se juega cada minijuego y cuántas veces hay que lograrlo.
const INSTRUCCION := {
	"machacar": "Presiona E o haz clic muchas veces.",
	"revolver": "Presiona ← y → (o A y D) una y otra vez, o haz clic a cada lado.",
	"atinar": "Presiona E o haz clic cuando la marca blanca esté en lo verde.",
}
const META := {"machacar": 12, "revolver": 10, "atinar": 3}

var _efectos: Node2D
var _avisos: VBoxContainer
var _capa_cocina: Control
var _fondo: Control
var _titulo: Label
var _contenido: VBoxContainer
var _cerrar: Button


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA))
	_efectos = Node2D.new()
	add_child(_efectos)
	_construir_panel()
	# Avisos de logros: arriba al centro, encima de todo.
	_avisos = VBoxContainer.new()
	_avisos.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_avisos.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_avisos.position.y = 24
	_avisos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_avisos)
	Juego.dia_cambio.connect(func(_d): nuevo_dia())
	Juego.zona_completada.connect(_al_completar_zona)


func _process(delta: float) -> void:
	if Juego.reloj_corre():
		crecer(delta / Juego.SEGUNDOS_POR_HORA)
		avanzar_talleres(delta / Juego.SEGUNDOS_POR_HORA)
		quemar_lena(delta / Juego.SEGUNDOS_POR_HORA)
		avanzar_frutales(delta / Juego.SEGUNDOS_POR_HORA)


# ---------------------------------------------------------------- Inventario

func cantidad(id: String) -> int:
	return int(Juego.inventario.get(id, 0))


func dar(id: String, n := 1) -> void:
	Juego.inventario[id] = cantidad(id) + n
	inventario_cambio.emit()


## Devuelve false (y no quita nada) si no alcanza.
func quitar(id: String, n := 1) -> bool:
	if cantidad(id) < n:
		return false
	Juego.inventario[id] = cantidad(id) - n
	if Juego.inventario[id] == 0:
		Juego.inventario.erase(id)
	inventario_cambio.emit()
	return true


func nombre(id: String) -> String:
	return datos["objetos"].get(id, {}).get("nombre", id)


func icono(id: String) -> Texture2D:
	var ruta: String = ICONO % datos["objetos"].get(id, {}).get("icono", id)
	return load(ruta) if ResourceLoader.exists(ruta) else null


## Al restaurar cada zona te regalan semillas de la milpa (y las partidas viejas las reciben al cargar).
func _al_completar_zona(zona: String) -> void:
	dar_semillas_de(zona)


func dar_semillas_de(zona: String) -> void:
	if Juego.tiene_marca("semillas_" + zona) or not datos["zonas_semillas"].has(zona):
		return
	Juego.marcar("semillas_" + zona)
	for id in datos["zonas_semillas"][zona]:
		dar(id, int(datos["zonas_semillas"][zona][id]))


## Lo recogido se ve: los íconos saltan desde donde salieron (en el mundo) y vuelan a la esquina
## de la pantalla, con un "+3 Maíz" que sube y se desvanece.
## `fila`: si salen varias cosas a la vez, cada etiqueta va un renglón más arriba.
func mostrar_recogida(id: String, n: int, en_mundo: Vector2, fila := 0) -> void:
	var textura := icono(id)
	if textura == null or not is_inside_tree():
		return
	var inicio: Vector2 = get_viewport().get_canvas_transform() * en_mundo
	for k in mini(n, 5):
		var pieza := Sprite2D.new()
		pieza.texture = textura
		var lado := 64.0 / maxf(textura.get_width(), textura.get_height())
		pieza.position = inicio
		pieza.scale = Vector2.ZERO
		_efectos.add_child(pieza)
		var salto := inicio + Vector2(randf_range(-50, 50) + (k - n / 2.0) * 22.0, randf_range(-110, -80))
		var vuelo := pieza.create_tween()
		vuelo.tween_interval(k * 0.08)
		vuelo.tween_property(pieza, "scale", Vector2.ONE * lado, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		vuelo.parallel().tween_property(pieza, "position", salto, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		vuelo.tween_interval(0.3)
		vuelo.tween_property(pieza, "position", DESTINO_RECOGIDOS, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		vuelo.parallel().tween_property(pieza, "scale", Vector2.ONE * lado * 0.5, 0.55)
		vuelo.tween_callback(pieza.queue_free)
	var etiqueta := _texto("+%d %s" % [n, nombre(id)], 30, Color(0.99, 0.95, 0.6))
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	etiqueta.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.05))
	etiqueta.add_theme_constant_override("outline_size", 10)
	etiqueta.position = inicio + Vector2(-80, -170 - fila * 40)
	_efectos.add_child(etiqueta)
	var subir := etiqueta.create_tween()
	subir.tween_property(etiqueta, "position:y", etiqueta.position.y - 50, 1.2)
	subir.parallel().tween_property(etiqueta, "modulate:a", 0.0, 1.2).set_delay(0.6)
	subir.tween_callback(etiqueta.queue_free)


# ---------------------------------------------------------------- Energía

func fijar_energia(valor: float) -> void:
	Juego.energia = clampf(valor, 0.0, 100.0)
	energia_cambio.emit(Juego.energia)


## Con poca energía el guardián camina más despacio (nunca se pierde ni se muere).
func factor_velocidad() -> float:
	var factor := 0.65 if Juego.juego_terminado() and Juego.energia < 25.0 else 1.0
	return factor * (VELOCIDAD_CABALLO if animales_de("caballo") > 0 else 1.0)


func comer(id: String) -> bool:
	var energia := int(datos["objetos"].get(id, {}).get("energia", 0))
	if energia <= 0 or not quitar(id):
		return false
	fijar_energia(Juego.energia + energia)
	Sonido.efecto("correcto")
	return true


# ---------------------------------------------------------------- Milpa

func parcela(i: int) -> Dictionary:
	while Juego.parcelas.size() < PARCELAS_MAX:
		Juego.parcelas.append({"cultivo": "", "etapa": 0, "regada": false, "horas": 0.0})
	return Juego.parcelas[i]


## La granja (milpa, corral, talleres, tianguis) aparece cuando el valle ya está restaurado: las tres zonas.
func granja_abierta() -> bool:
	return Juego.juego_terminado()


# ---------------------------------------------------------------- Cuadros de la milpa

## Los cuadros de la milpa en orden (el de la parcela i es el i). La primera vez se ponen los de siempre,
## tantos como permite el nivel (así las partidas viejas no pierden lo sembrado).
func celdas_milpa() -> Array[Vector2i]:
	if not Juego.milpa_lista:
		Juego.milpa_lista = true
		if Juego.milpa.is_empty():
			for i in surcos():
				Juego.milpa.append("%d,%d" % [i % 4, i / 4])
	var lista: Array[Vector2i] = []
	for clave in Juego.milpa:
		var p := clave.split(",")
		lista.append(Vector2i(int(p[0]), int(p[1])))
	return lista


func celda_milpa_de(punto: Vector2) -> Vector2i:
	return Vector2i(((punto - ORIGEN_MILPA) / CELDA_MILPA).floor())


func rect_de_milpa(celda: Vector2i) -> Rect2:
	return Rect2(ORIGEN_MILPA + Vector2(celda) * CELDA_MILPA, CELDA_MILPA)


func centro_de_milpa(celda: Vector2i) -> Vector2:
	return rect_de_milpa(celda).get_center()


## Si algún cuadro de la milpa toca `zona`.
func milpa_toca(zona: Rect2) -> bool:
	for celda in celdas_milpa():
		if rect_de_milpa(celda).intersects(zona):
			return true
	return false


## Pone un cuadro de tierra (el modo decorar revisa que no estorbe nada).
func poner_milpa(celda: Vector2i) -> bool:
	var celdas := celdas_milpa()
	if celdas.size() >= surcos() or celda in celdas or not en_la_granja(rect_de_milpa(celda)):
		return false
	parcela(celdas.size())
	Juego.milpa.append("%d,%d" % [celda.x, celda.y])
	Sonido.efecto("recoger")
	milpa_cambio.emit()
	return true


## Quita un cuadro de tierra, solo si no tiene nada sembrado.
func quitar_milpa(celda: Vector2i) -> bool:
	var i := celdas_milpa().find(celda)
	if i < 0 or not parcela(i)["cultivo"].is_empty():
		return false
	Juego.milpa.remove_at(i)
	Juego.parcelas.remove_at(i)
	parcela(0)
	Sonido.efecto("boton")
	milpa_cambio.emit()
	return true


## Elegir si se agrega o se quita tierra: `al_elegir(tipo)` recibe "milpa" o "quitar_milpa".
func abrir_milpa(al_elegir: Callable) -> void:
	_abrir("milpa", "Tu milpa")
	var hay := celdas_milpa().size()
	var nota := "Tienes %d de %d cuadros." % [hay, surcos()]
	if surcos() < PARCELAS_MAX:
		nota += " En el nivel %d puedes tener más." % nivel_del_surco(surcos())
	_contenido.add_child(_texto(nota + " Pon la tierra donde quieras, cuadro por cuadro.", 24, Color(0.85, 0.95, 0.8)))
	var rejilla := _rejilla()
	rejilla.add_child(_tarjeta("semilla_maiz", "Agregar tierra", {}, "%d disponibles" % (surcos() - hay), "AGREGAR",
		hay < surcos(), 1, func(): cerrar(); al_elegir.call("milpa"), "Toca o arrastra sobre el pasto para arar un cuadro nuevo."))
	rejilla.add_child(_tarjeta("camino_quitar", "Quitar tierra", {}, "", "QUITAR", true, 1,
		func(): cerrar(); al_elegir.call("quitar_milpa"), "Solo se quitan los cuadros que no tienen nada sembrado."))


func surcos() -> int:
	return int(desbloqueado("surcos", 6))


## Nivel en el que se abre el surco i (1 si ya está desde el principio).
func nivel_del_surco(i: int) -> int:
	var n := 1
	var abiertos := 6
	while abiertos <= i and n < datos["niveles"]["xp"].size():
		n += 1
		abiertos = int(datos["niveles"]["desbloqueos"].get(str(n), {}).get("surcos", abiertos))
	return n


func plantar(i: int, cultivo: String) -> bool:
	var p := parcela(i)
	if not p["cultivo"].is_empty() or not quitar(datos["cultivos"][cultivo]["semilla"]):
		return false
	p["cultivo"] = cultivo
	p["etapa"] = 0
	p["regada"] = false
	p["abonada"] = false
	p["horas"] = 0.0
	Sonido.efecto("correcto")
	parcelas_cambio.emit()
	return true


func regar(i: int) -> bool:
	var p := parcela(i)
	if p["cultivo"].is_empty() or p["regada"] or int(p["etapa"]) >= LISTO:
		return false
	p["regada"] = true
	Sonido.efecto("chapoteo")
	parcelas_cambio.emit()
	return true


## Echarle abono (del cerdo) a lo que está creciendo: crece el doble de rápido.
func abonar(i: int) -> bool:
	var p := parcela(i)
	if p["cultivo"].is_empty() or p.get("abonada", false) or int(p["etapa"]) >= LISTO or not quitar("abono"):
		return false
	p["abonada"] = true
	Sonido.efecto("recoger")
	parcelas_cambio.emit()
	return true


func puede_abonar(i: int) -> bool:
	var p := parcela(i)
	return not p["cultivo"].is_empty() and not p.get("abonada", false) and int(p["etapa"]) < LISTO and cantidad("abono") > 0


## Lo que se sembró y se regó crece con el tiempo (en horas del juego: 1 hora = 30 s).
func crecer(horas: float) -> void:
	var cambio := false
	for p in Juego.parcelas:
		if p["cultivo"].is_empty() or not p["regada"] or int(p["etapa"]) >= LISTO:
			continue
		p["horas"] = float(p.get("horas", 0.0)) + horas * (2.0 if p.get("abonada", false) else 1.0)
		var etapa := mini(int(p["horas"] * LISTO / float(datos["cultivos"][p["cultivo"]]["horas"])), LISTO)
		if etapa != int(p["etapa"]):
			p["etapa"] = etapa
			cambio = true
	if cambio:
		parcelas_cambio.emit()


## Minutos reales que faltan para cosechar la parcela `i` (0 si no está creciendo).
func minutos_restantes(i: int) -> int:
	var p := parcela(i)
	if p["cultivo"].is_empty() or not p["regada"]:
		return 0
	var falta: float = float(datos["cultivos"][p["cultivo"]]["horas"]) - float(p.get("horas", 0.0))
	if p.get("abonada", false):
		falta /= 2.0
	return maxi(ceili(falta * Juego.SEGUNDOS_POR_HORA / 60.0), 0)


## Devuelve lo que se cosechó ({objeto: cantidad}) o {} si aún no está lista.
func cosechar(i: int) -> Dictionary:
	var p := parcela(i)
	if p["cultivo"].is_empty() or int(p["etapa"]) < LISTO:
		return {}
	var cosecha: Dictionary = datos["cultivos"][p["cultivo"]]["cosecha"]
	for id in cosecha:
		dar(id, int(cosecha[id]))
	p["cultivo"] = ""
	p["etapa"] = 0
	p["regada"] = false
	p["abonada"] = false
	p["horas"] = 0.0
	Sonido.efecto("recoger")
	dar_xp(int(datos["xp"]["cosechar"]))
	parcelas_cambio.emit()
	return cosecha


func textura_planta(i: int) -> Texture2D:
	var p := parcela(i)
	if p["cultivo"].is_empty():
		return null
	return load(PLANTA % [p["cultivo"], int(p["etapa"])])


## Cada mañana el corral da huevos y leche (las plantas silvestres cambian solas al pedirlas).
func nuevo_dia() -> void:
	for animal in Juego.corral:
		if int(Juego.corral[animal].get("comio", -1)) == Juego.dia - 1:
			Juego.corral[animal]["listo"] = true


# ---------------------------------------------------------------- Corral

## Cuántos animales de una especie hay: el que regala el nivel (la gallina desde el principio, la cabra y
## el guajolote al subir) más los que se compraron.
func animales_de(especie: String) -> int:
	var regalado: bool = especie == "gallina" or (especie in ["cabra", "guajolote"] and desbloqueado(especie, false))
	return (1 if regalado else 0) + Juego.comprados.count(especie)


## Todos los animales del corral por su nombre: el primero de cada especie se llama como ella
## ("vaca") y los demás llevan número ("vaca_2"); así cada uno come y produce por su cuenta.
func animales_del_corral() -> Array[String]:
	var lista: Array[String] = []
	for especie in datos["corral"]:
		for k in animales_de(especie):
			lista.append(especie if k == 0 else "%s_%d" % [especie, k + 1])
	return lista


func especie_de(animal: String) -> String:
	return animal.get_slice("_", 0)


## Solo se venden los animales que ya tienen su dibujo.
func se_vende(especie: String) -> bool:
	return ResourceLoader.exists(CUADROS_ANIMAL % especie)


func comprar_animal(especie: String) -> bool:
	var dato: Dictionary = datos["corral"][especie]
	if nivel() < int(dato["nivel"]) or animales_de(especie) >= ANIMALES_POR_ESPECIE \
			or not Juego.gastar_hojas(int(dato["costo"])):
		return false
	Juego.comprados.append(especie)
	Sonido.efecto("zona_restaurada")
	dar_xp(int(datos["xp"]["comprar_animal"]))
	corral_cambio.emit()
	return true


## El comedero de un corral: a cada animal se le recoge lo que tenga listo y se le da de comer si no ha
## comido hoy. Devuelve {"recogido": {producto: cantidad}, "comieron": cuántos comieron}.
func atender_todos(animales: Array[String]) -> Dictionary:
	var recogido := {}
	var comieron := 0
	for animal in animales:
		var producto: String = datos["corral"][especie_de(animal)]["producto"]
		var antes := cantidad(producto) if not producto.is_empty() else 0
		var estado: Dictionary = Juego.corral.get(animal, {"comio": -1, "listo": false})
		var comio_antes := int(estado["comio"]) == Juego.dia
		atender(animal)
		if not producto.is_empty() and cantidad(producto) > antes:
			recogido[producto] = int(recogido.get(producto, 0)) + cantidad(producto) - antes
			# Si se recogió, también come (así con un solo toque queda listo para mañana).
			atender(animal)
		if not comio_antes and int(Juego.corral[animal]["comio"]) == Juego.dia:
			comieron += 1
	return {"recogido": recogido, "comieron": comieron}


## Hablar con un animal del corral: si tiene huevo, leche, abono o lana se recoge; si no ha comido hoy
## se le da de comer (al día siguiente tendrá). Devuelve el texto que se le muestra al jugador.
func atender(animal: String) -> String:
	var estado: Dictionary = Juego.corral.get(animal, {"comio": -1, "listo": false})
	Juego.corral[animal] = estado
	var dato: Dictionary = datos["corral"][especie_de(animal)]
	var producto: String = dato["producto"]
	if producto.is_empty():
		# El caballo no da nada: con darle de comer basta para que te lleve más rápido.
		if int(estado["comio"]) == Juego.dia:
			return "Ya comió hoy. Con el %s caminas más rápido por el valle." % dato["nombre"].to_lower()
		estado["comio"] = Juego.dia
		Sonido.efecto("correcto")
		dar_xp(int(datos["xp"]["corral"]))
		return "Le diste de comer. ¡Está contento!"
	if estado["listo"]:
		estado["listo"] = false
		dar(producto, maxi(int(dato["cantidad"]), 1))
		Sonido.efecto("recoger")
		dar_xp(int(datos["xp"]["corral"]))
		return "¡Recogiste %s!" % nombre(producto).to_lower()
	if int(estado["comio"]) == Juego.dia:
		return "Ya comió hoy. Mañana tendrá %s." % nombre(producto).to_lower()
	estado["comio"] = Juego.dia
	Sonido.efecto("correcto")
	return "Le diste de comer. Mañana tendrá %s." % nombre(producto).to_lower()


# ---------------------------------------------------------------- Pesca

func pescas_de_hoy() -> int:
	return int(Juego.pesca.get("veces", 0)) if int(Juego.pesca.get("dia", 0)) == Juego.dia else 0


func puede_pescar() -> bool:
	return pescas_de_hoy() < PESCA_POR_DIA


## Resultado de una pesca que salió bien: "pescado" o "cria" (la cría se regresa al agua y no cuenta).
func sacar_pez(es_cria: bool) -> String:
	if es_cria:
		return "cria"
	Juego.pesca = {"dia": Juego.dia, "veces": pescas_de_hoy() + 1}
	dar("pescado")
	dar_xp(int(datos["xp"]["pescar"]))
	return "pescado"


# ---------------------------------------------------------------- Recolección

## Plantas silvestres y leña de hoy (dentro de `area`, fuera de `prohibido`); cambian cada día.
func silvestres_de_hoy(area: Rect2, prohibido: Array[Rect2] = []) -> Array:
	if Juego.silvestres_dia != Juego.dia:
		Juego.silvestres_dia = Juego.dia
		Juego.silvestres.clear()
		for i in SILVESTRES_POR_DIA:
			var pos := Vector2.ZERO
			for intento in 20:
				pos = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
				if not prohibido.any(func(r: Rect2): return r.has_point(pos)):
					break
			Juego.silvestres.append({"tipo": datos["silvestres"].pick_random(), "pos": pos})
	return Juego.silvestres


func recolectar(dato: Dictionary) -> void:
	Juego.silvestres.erase(dato)
	dar(dato["tipo"])
	Sonido.efecto("recoger")
	dar_xp(int(datos["xp"]["recolectar"]))


# ---------------------------------------------------------------- Cocina

# ---------------------------------------------------------------- Fogón

func fogon_prendido() -> bool:
	return bool(Juego.fogon["prendido"])


## Prende el fogón: si no le queda leña adentro, gasta un leño de la mochila.
func prender_fogon() -> bool:
	if fogon_prendido():
		return false
	if float(Juego.fogon["horas"]) <= 0.0:
		if not quitar("lena"):
			return false
		Juego.fogon["horas"] = HORAS_POR_LENO
	Juego.fogon["prendido"] = true
	Sonido.efecto("correcto")
	fogon_cambio.emit()
	return true


## Echa otro leño para que dure más (hasta LENOS_MAX).
func echar_lena() -> bool:
	if not fogon_prendido() or float(Juego.fogon["horas"]) > HORAS_POR_LENO * (LENOS_MAX - 1) or not quitar("lena"):
		return false
	Juego.fogon["horas"] = float(Juego.fogon["horas"]) + HORAS_POR_LENO
	fogon_cambio.emit()
	return true


## Apagar guarda la leña que no se quemó: la próxima vez prende sin gastar otro leño.
func apagar_fogon() -> void:
	if not fogon_prendido():
		return
	Juego.fogon["prendido"] = false
	fogon_cambio.emit()


func quemar_lena(horas: float) -> void:
	if not fogon_prendido():
		return
	Juego.fogon["horas"] = maxf(float(Juego.fogon["horas"]) - horas, 0.0)
	if Juego.fogon["horas"] <= 0.0:
		Juego.fogon["prendido"] = false
		fogon_cambio.emit()


func minutos_de_lena() -> int:
	return ceili(float(Juego.fogon["horas"]) * Juego.SEGUNDOS_POR_HORA / 60.0)


func puede_cocinar(receta: Dictionary) -> bool:
	if nivel() < int(receta.get("nivel", 1)) or not fogon_prendido():
		return false
	for id in receta["ingredientes"]:
		if cantidad(id) < int(receta["ingredientes"][id]):
			return false
	return true


func cocinar(id_receta: String) -> bool:
	var receta: Dictionary = {}
	for r in datos["recetas"]:
		if r["id"] == id_receta:
			receta = r
	if receta.is_empty() or not puede_cocinar(receta):
		return false
	for id in receta["ingredientes"]:
		quitar(id, int(receta["ingredientes"][id]))
	dar(id_receta)
	if id_receta not in Juego.recetario:
		Juego.recetario.append(id_receta)
	Sonido.efecto("zona_restaurada")
	dar_xp(int(datos["xp"]["cocinar"]))
	return true


# ---------------------------------------------------------------- Talleres

## Estado del taller: {"horas": avance de la tanda, "trabajando": bool, "listo": tandas por recoger}.
## La colmena no necesita nada: trabaja sola.
func taller(id: String) -> Dictionary:
	if not Juego.talleres.has(id):
		Juego.talleres[id] = {"horas": 0.0, "trabajando": datos["talleres"][id]["entrada"].is_empty(), "listo": 0}
	return Juego.talleres[id]


func taller_abierto(id: String) -> bool:
	return nivel() >= int(datos["talleres"][id]["nivel"])


func puede_hacer(id: String) -> bool:
	if not taller_abierto(id):
		return false
	var entrada: Dictionary = datos["talleres"][id]["entrada"]
	for ingrediente in entrada:
		if cantidad(ingrediente) < int(entrada[ingrediente]):
			return false
	return not entrada.is_empty()


## El molino y la quesería hacen su producto al terminar el minijuego (moler, revolver la leche).
func hacer_en_taller(id: String) -> Dictionary:
	if not puede_hacer(id):
		return {}
	var dato: Dictionary = datos["talleres"][id]
	for ingrediente in dato["entrada"]:
		quitar(ingrediente, int(dato["entrada"][ingrediente]))
	var hecho := {}
	for producto in dato["salida"]:
		hecho[producto] = int(dato["salida"][producto])
		dar(producto, hecho[producto])
	Sonido.efecto("recoger")
	dar_xp(int(datos["xp"]["taller"]))
	talleres_cambio.emit()
	return hecho


## Solo la colmena trabaja sola con el tiempo (y los talleres de partidas viejas que dejaron una tanda).
func avanzar_talleres(horas: float) -> void:
	for id in datos["talleres"]:
		if not taller_abierto(id):
			continue
		var t := taller(id)
		if not t["trabajando"]:
			continue
		t["horas"] = float(t["horas"]) + horas
		if t["horas"] < float(datos["talleres"][id]["horas"]):
			continue
		t["horas"] = 0.0
		t["listo"] = mini(int(t["listo"]) + 1, TANDAS_MAX)
		t["trabajando"] = datos["talleres"][id]["entrada"].is_empty() and int(t["listo"]) < TANDAS_MAX
		talleres_cambio.emit()


## Minutos reales que faltan para la tanda que se está haciendo (0 si no trabaja).
func minutos_taller(id: String) -> int:
	var t := taller(id)
	if not t["trabajando"]:
		return 0
	var falta := float(datos["talleres"][id]["horas"]) - float(t["horas"])
	return maxi(ceili(falta * Juego.SEGUNDOS_POR_HORA / 60.0), 1)


## Recoge lo que está listo ({objeto: cantidad}, vacío si no hay nada).
func recoger_taller(id: String) -> Dictionary:
	var t := taller(id)
	var tandas := int(t["listo"])
	if tandas == 0:
		return {}
	var recogido := {}
	var salida: Dictionary = datos["talleres"][id]["salida"]
	for producto in salida:
		recogido[producto] = int(salida[producto]) * tandas
		dar(producto, recogido[producto])
	t["listo"] = 0
	t["trabajando"] = datos["talleres"][id]["entrada"].is_empty()
	Sonido.efecto("recoger")
	dar_xp(int(datos["xp"]["taller"]) * tandas)
	talleres_cambio.emit()
	return recogido


# ---------------------------------------------------------------- Niveles

func nivel() -> int:
	var n := 0
	for minimo in datos["niveles"]["xp"]:
		if Juego.xp >= int(minimo):
			n += 1
	return n


## Experiencia que falta para el siguiente nivel ([actual dentro del nivel, total del nivel]).
func progreso_nivel() -> Array:
	var tabla: Array = datos["niveles"]["xp"]
	var n := nivel()
	if n >= tabla.size():
		return [1, 1]
	var desde := int(tabla[n - 1])
	return [Juego.xp - desde, int(tabla[n]) - desde]


func dar_xp(n: int) -> void:
	var antes := nivel()
	Juego.xp += n
	for nuevo in range(antes + 1, nivel() + 1):
		var desbloqueo: Dictionary = datos["niveles"]["desbloqueos"].get(str(nuevo), {})
		Sonido.efecto("zona_restaurada")
		nivel_subio.emit(nuevo, desbloqueo.get("texto", ""))


## Valor de `clave` según lo que ya se desbloqueó (el del nivel más alto alcanzado).
func desbloqueado(clave: String, por_omision: Variant) -> Variant:
	var valor: Variant = por_omision
	for n in range(2, nivel() + 1):
		var desbloqueo: Dictionary = datos["niveles"]["desbloqueos"].get(str(n), {})
		if desbloqueo.has(clave):
			valor = desbloqueo[clave]
	return valor


# ---------------------------------------------------------------- Tianguis

## Pedidos que se pueden entregar en el tianguis; siempre hay tantos como permite el nivel.
func pedidos_tianguis() -> Array:
	while Juego.tianguis.size() < int(desbloqueado("pedidos", 3)):
		Juego.tianguis.append(nuevo_pedido())
	return Juego.tianguis


## Pide de 1 a 2 cosas que el guardián ya puede conseguir.
func nuevo_pedido() -> Dictionary:
	var posibles := ["pescado"]
	# Piden lo que dan los animales que tienes.
	for especie in datos["corral"]:
		var producto: String = datos["corral"][especie]["producto"]
		if animales_de(especie) > 0 and not producto.is_empty() and producto not in posibles:
			posibles.append(producto)
	for zona_cultivo in [["rio", "frijol"], ["bosque", "maiz"], ["lago", "calabaza"]]:
		if Juego.zona_esta_completa(zona_cultivo[0]):
			posibles.append(zona_cultivo[1])
	for id in datos["talleres"]:
		if taller_abierto(id):
			posibles.append_array(datos["talleres"][id]["salida"].keys())
	for arbol in Juego.frutales:
		var fruto: String = datos["frutales"][arbol["id"]]["fruto"]
		if int(arbol["etapa"]) >= ADULTO and fruto not in posibles:
			posibles.append(fruto)
	for receta in Juego.recetario:
		posibles.append(receta)
	posibles.shuffle()
	var cosas := {}
	var valor := 0
	for id in posibles.slice(0, randi_range(1, 2)):
		var es_platillo: bool = id in Juego.recetario
		var n := randi_range(1, 2) if es_platillo else randi_range(1, 3)
		cosas[id] = n
		valor += n * int(datos["objetos"][id].get("valor", 1))
	return {"cosas": cosas, "hojas": valor + 1, "xp": valor * 3, "quien": VECINOS.pick_random()}


func puede_entregar(pedido: Dictionary) -> bool:
	for id in pedido["cosas"]:
		if cantidad(id) < int(pedido["cosas"][id]):
			return false
	return true


func entregar(i: int) -> bool:
	var pedido: Dictionary = pedidos_tianguis()[i]
	if not puede_entregar(pedido):
		return false
	for id in pedido["cosas"]:
		quitar(id, int(pedido["cosas"][id]))
	Juego.dar_hojas(int(pedido["hojas"]))
	Juego.tianguis[i] = nuevo_pedido()
	Sonido.efecto("correcto")
	dar_xp(int(pedido["xp"]))
	return true


## Cambia un pedido difícil por otro (gratis: solo es para no atorarse).
func cambiar_pedido(i: int) -> void:
	pedidos_tianguis()[i] = nuevo_pedido()


func comprar_semilla(id: String) -> bool:
	if not Juego.gastar_hojas(int(datos["semillas_tianguis"][id])):
		return false
	dar(id)
	Sonido.efecto("recoger")
	return true


# ---------------------------------------------------------------- Decoraciones y lugares de la granja

func guardadas(id: String) -> int:
	return int(Juego.decoraciones["guardadas"].get(id, 0))


## Compra una decoración con hojas; queda guardada hasta que se pone en el valle.
func comprar_decoracion(id: String) -> bool:
	var dato: Dictionary = datos["decoraciones"][id]
	if nivel() < int(dato["nivel"]) or not Juego.gastar_hojas(int(dato["costo"])):
		return false
	Juego.decoraciones["guardadas"][id] = guardadas(id) + 1
	dar_xp(int(datos["xp"]["decorar"]))
	Sonido.efecto("recoger")
	return true


## Pone en el valle una decoración guardada. Devuelve lo que quedó puesto ({} si no había guardada);
## al moverla se cambian su "x" y su "y".
func poner_decoracion(id: String, pos: Vector2) -> Dictionary:
	if guardadas(id) <= 0:
		return {}
	Juego.decoraciones["guardadas"][id] = guardadas(id) - 1
	var puesta := {"id": id, "x": pos.x, "y": pos.y}
	Juego.decoraciones["puestas"].append(puesta)
	Sonido.efecto("correcto")
	return puesta


## Quita una decoración del valle y la guarda (no se pierde).
func guardar_decoracion(puesta: Dictionary) -> void:
	var i: int = Juego.decoraciones["puestas"].find(puesta)
	if i < 0:
		return
	Juego.decoraciones["puestas"].remove_at(i)
	Juego.decoraciones["guardadas"][puesta["id"]] = guardadas(puesta["id"]) + 1
	Sonido.efecto("recoger")


## Dónde está el corral o un taller: donde lo dejó el jugador o, si nunca lo movió, `por_omision`.
func posicion(id: String, por_omision: Vector2) -> Vector2:
	var p: Array = Juego.posiciones.get(id, [])
	return Vector2(float(p[0]), float(p[1])) if p.size() == 2 else por_omision


func fijar_posicion(id: String, pos: Vector2) -> void:
	Juego.posiciones[id] = [pos.x, pos.y]


## Tienda del modo decorar: se compra con hojas o se elige una guardada; `al_elegir(id)` la pone en la mano.
func abrir_tienda_decoraciones(al_elegir: Callable) -> void:
	_abrir("decorar", "Decoraciones")
	_contenido.add_child(_texto("Tienes %d hojas. Las ganas con los pedidos del tianguis." % Juego.hojas, 26, Color(0.8, 1, 0.7)))
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 16)
	rejilla.add_theme_constant_override("v_separation", 16)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_child(rejilla)
	for id in datos["decoraciones"]:
		var dato: Dictionary = datos["decoraciones"][id]
		var costo := int(dato["costo"])
		var tiene := guardadas(id)
		var nota := "Cuesta %d hojas" % costo
		if tiene > 0:
			nota = "Tienes %d guardada%s" % [tiene, "" if tiene == 1 else "s"]
		var elegir := func():
			if guardadas(id) > 0 or comprar_decoracion(id):
				cerrar()
				al_elegir.call(id)
		rejilla.add_child(_tarjeta(id, dato["nombre"], {}, nota, "PONER" if tiene > 0 else "COMPRAR",
			tiene > 0 or Juego.hojas >= costo, int(dato["nivel"]), elegir, dato["dato"]))
	_contenido.add_child(_texto("Árboles frutales", 28, Color(0.99, 0.86, 0.45)))
	var arboles := _rejilla()
	for id in datos["frutales"]:
		var dato: Dictionary = datos["frutales"][id]
		var costo := int(dato["costo"])
		var tiene := guardadas(id)
		var nota := "Tienes %d arbolito%s" % [tiene, "" if tiene == 1 else "s"] if tiene > 0 else "Cuesta %d hojas" % costo
		var elegir := func():
			if guardadas(id) > 0 or comprar_frutal(id):
				cerrar()
				al_elegir.call(id)
		arboles.add_child(_tarjeta(dato["fruto"], "Arbolito de " + dato["nombre"].to_lower(), {}, nota,
			"PLANTAR" if tiene > 0 else "COMPRAR", tiene > 0 or Juego.hojas >= costo, int(dato["nivel"]), elegir,
			dato["dato"] + " Crece, da %d frutas y vuelve a dar." % int(dato["cantidad"])))


# ---------------------------------------------------------------- Árboles frutales

func comprar_frutal(id: String) -> bool:
	var dato: Dictionary = datos["frutales"][id]
	if nivel() < int(dato["nivel"]) or not Juego.gastar_hojas(int(dato["costo"])):
		return false
	Juego.decoraciones["guardadas"][id] = guardadas(id) + 1
	Sonido.efecto("recoger")
	return true


## Planta un arbolito comprado. Devuelve lo plantado ({} si no había).
func plantar_frutal(id: String, pos: Vector2) -> Dictionary:
	if guardadas(id) <= 0:
		return {}
	Juego.decoraciones["guardadas"][id] = guardadas(id) - 1
	var arbol := {"id": id, "x": pos.x, "y": pos.y, "etapa": 0, "horas": 0.0, "abonado": false}
	Juego.frutales.append(arbol)
	dar_xp(int(datos["xp"]["frutal"]))
	Sonido.efecto("correcto")
	frutales_cambio.emit()
	return arbol


## Horas que le faltan a la etapa en que va (crecer o volver a dar fruta).
func _horas_de_etapa(arbol: Dictionary) -> float:
	var dato: Dictionary = datos["frutales"][arbol["id"]]
	var etapa := int(arbol["etapa"])
	return float(dato["horas"][etapa]) if etapa < ADULTO else float(dato["horas_fruto"])


## Crecen con el tiempo; ya adultos, dan fruta cada tanto (y esperan a que la cosechen). Con abono, el doble de rápido.
func avanzar_frutales(horas: float) -> void:
	var cambio := false
	for arbol in Juego.frutales:
		if int(arbol["etapa"]) >= CON_FRUTA:
			continue
		arbol["horas"] = float(arbol["horas"]) + horas * (2.0 if arbol["abonado"] else 1.0)
		if arbol["horas"] >= _horas_de_etapa(arbol):
			arbol["horas"] = 0.0
			arbol["etapa"] = int(arbol["etapa"]) + 1
			arbol["abonado"] = false
			cambio = true
	if cambio:
		frutales_cambio.emit()


func minutos_frutal(arbol: Dictionary) -> int:
	if int(arbol["etapa"]) >= CON_FRUTA:
		return 0
	var falta := (_horas_de_etapa(arbol) - float(arbol["horas"])) / (2.0 if arbol["abonado"] else 1.0)
	return maxi(ceili(falta * Juego.SEGUNDOS_POR_HORA / 60.0), 1)


func puede_abonar_frutal(arbol: Dictionary) -> bool:
	return int(arbol["etapa"]) < CON_FRUTA and not arbol["abonado"] and cantidad("abono") > 0


func abonar_frutal(arbol: Dictionary) -> bool:
	if not puede_abonar_frutal(arbol):
		return false
	quitar("abono")
	arbol["abonado"] = true
	Sonido.efecto("recoger")
	frutales_cambio.emit()
	return true


func cosechar_frutal(arbol: Dictionary) -> Dictionary:
	if int(arbol["etapa"]) < CON_FRUTA:
		return {}
	var dato: Dictionary = datos["frutales"][arbol["id"]]
	arbol["etapa"] = ADULTO
	arbol["horas"] = 0.0
	arbol["abonado"] = false
	dar(dato["fruto"], int(dato["cantidad"]))
	Sonido.efecto("recoger")
	dar_xp(int(datos["xp"]["cosechar"]))
	frutales_cambio.emit()
	return {dato["fruto"]: int(dato["cantidad"])}


# ---------------------------------------------------------------- Terrenos (expandir la granja)

func terreno_abierto(celda: Vector2i) -> bool:
	return TERRENOS_INICIALES.has_point(celda) or ("%d,%d" % [celda.x, celda.y]) in Juego.terrenos


func dentro_del_valle(celda: Vector2i) -> bool:
	return Rect2i(0, 0, COLUMNAS_TERRENO, FILAS_TERRENO).has_point(celda)


## Se puede comprar si está pegado (no en diagonal) a un terreno que ya es de la granja.
func se_puede_expandir(celda: Vector2i) -> bool:
	if not dentro_del_valle(celda) or terreno_abierto(celda):
		return false
	for lado in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if terreno_abierto(celda + lado):
			return true
	return false


func celda_de(punto: Vector2) -> Vector2i:
	return Vector2i(floori(punto.x / TERRENO.x), floori(punto.y / TERRENO.y))


func rect_de_terreno(celda: Vector2i) -> Rect2:
	return Rect2(Vector2(celda) * TERRENO, TERRENO)


## Si todo `zona` cae en terrenos de la granja (para poner o mover algo ahí).
func en_la_granja(zona: Rect2) -> bool:
	var desde := celda_de(zona.position)
	var hasta := celda_de(zona.end - Vector2(0.01, 0.01))
	for c in range(desde.x, hasta.x + 1):
		for f in range(desde.y, hasta.y + 1):
			if not terreno_abierto(Vector2i(c, f)):
				return false
	return true


## Cada terreno cuesta un poco más que el anterior: nivel, hojas y leña.
func costo_expansion() -> Dictionary:
	var n := Juego.terrenos.size()
	return {"nivel": mini(2 + n / 2, datos["niveles"]["xp"].size()), "hojas": 8 + 4 * n, "lena": 2 + n}


func puede_expandir(celda: Vector2i) -> bool:
	var costo := costo_expansion()
	return se_puede_expandir(celda) and nivel() >= int(costo["nivel"]) and Juego.hojas >= int(costo["hojas"]) \
		and cantidad("lena") >= int(costo["lena"])


func expandir(celda: Vector2i) -> bool:
	if not puede_expandir(celda):
		return false
	var costo := costo_expansion()
	Juego.gastar_hojas(int(costo["hojas"]))
	quitar("lena", int(costo["lena"]))
	Juego.terrenos.append("%d,%d" % [celda.x, celda.y])
	Sonido.efecto("zona_restaurada")
	dar_xp(5)
	terrenos_cambio.emit()
	return true


## Panel para comprar un terreno: tres círculos con lo que cuesta (verde si ya lo tienes, rojo si no).
func abrir_expandir(celda: Vector2i) -> void:
	_abrir("expandir", "Expandir la granja")
	var costo := costo_expansion()
	_contenido.add_child(_texto("Con este terreno tu granja crece y tienes más lugar para tus animales y decoraciones.",
		24, Color(0.85, 0.95, 0.8)))
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 40)
	_contenido.add_child(fila)
	fila.add_child(_circulo_costo(null, "Nivel %d" % int(costo["nivel"]), "Tu nivel: %d" % nivel(), nivel() >= int(costo["nivel"])))
	fila.add_child(_circulo_costo(HOJA, "%d hojas" % int(costo["hojas"]), "Tienes %d" % Juego.hojas, Juego.hojas >= int(costo["hojas"])))
	fila.add_child(_circulo_costo(icono("lena"), "%d de leña" % int(costo["lena"]), "Tienes %d" % cantidad("lena"),
		cantidad("lena") >= int(costo["lena"])))
	_contenido.add_child(_texto("Aquí no se tala: los árboles se quedan, porque dan sombra y son la casa de muchos animales.",
		22, Color(0.99, 0.86, 0.45)))
	var boton := _boton("EXPANDIR", puede_expandir(celda), func():
		expandir(celda)
		cerrar())
	boton.custom_minimum_size = Vector2(260, 60)
	boton.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_contenido.add_child(boton)


func _circulo_costo(dibujo: Texture2D, texto: String, nota: String, alcanza: bool) -> VBoxContainer:
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	var circulo := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.75, 0.3, 0.12) if not alcanza else Color(0.3, 0.55, 0.2)
	estilo.border_color = Color(0.45, 0.85, 0.3) if alcanza else Color(1, 0.55, 0.4)
	estilo.set_border_width_all(8)
	estilo.set_corner_radius_all(70)
	estilo.set_content_margin_all(28)
	circulo.add_theme_stylebox_override("panel", estilo)
	circulo.custom_minimum_size = Vector2(140, 140)
	circulo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if dibujo:
		var imagen := TextureRect.new()
		imagen.texture = dibujo
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.custom_minimum_size = Vector2(80, 80)
		circulo.add_child(imagen)
	else:
		var estrella := _texto("★", 64, Color(1, 0.86, 0.3))
		estrella.autowrap_mode = TextServer.AUTOWRAP_OFF
		estrella.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		estrella.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		circulo.add_child(estrella)
	columna.add_child(circulo)
	columna.add_child(_texto(texto, 26, Color(0.7, 1, 0.6) if alcanza else Color(1, 0.65, 0.55)))
	columna.add_child(_texto(nota, 20, Color(0.85, 0.95, 0.8)))
	return columna


# ---------------------------------------------------------------- Caminos

func camino_en(celda: Vector2i) -> String:
	return Juego.caminos.get("%d,%d" % [celda.x, celda.y], "")


func rect_de_camino(celda: Vector2i) -> Rect2:
	return Rect2(Vector2(celda) * CELDA_CAMINO, Vector2.ONE * CELDA_CAMINO)


## Pinta un cuadrito de camino (dentro de la granja). El de piedra cuesta; cambiarlo a tierra no devuelve nada.
func poner_camino(celda: Vector2i, tipo: String) -> bool:
	if camino_en(celda) == tipo or not en_la_granja(rect_de_camino(celda)):
		return false
	if not Juego.gastar_hojas(int(CAMINOS[tipo]["costo"])):
		return false
	Juego.caminos["%d,%d" % [celda.x, celda.y]] = tipo
	caminos_cambio.emit()
	return true


func quitar_camino(celda: Vector2i) -> bool:
	if not Juego.caminos.erase("%d,%d" % [celda.x, celda.y]):
		return false
	caminos_cambio.emit()
	return true


## Pinta un tramo recto de `desde` a `hasta` (en cuadritos, misma fila o columna), sin cobrar.
func trazar_camino(desde: Vector2i, hasta: Vector2i, tipo := "arena") -> void:
	var paso := (hasta - desde).sign()
	var c := desde
	while true:
		Juego.caminos["%d,%d" % [c.x, c.y]] = tipo
		if c == hasta:
			break
		c += paso


## Elegir con qué se pinta: `al_elegir(tipo)` recibe "arena", "piedra" o "quitar".
func abrir_caminos(al_elegir: Callable) -> void:
	_abrir("caminos", "Caminos")
	_contenido.add_child(_texto("Pinta caminos rectos sobre la cuadrícula de tu granja: haz clic o arrastra.", 24, Color(0.85, 0.95, 0.8)))
	var rejilla := _rejilla()
	for tipo in CAMINOS:
		var dato: Dictionary = CAMINOS[tipo]
		rejilla.add_child(_tarjeta("camino_" + tipo, dato["nombre"], {}, "Tienes %d hojas" % Juego.hojas if int(dato["costo"]) > 0 else "",
			"PINTAR", Juego.hojas >= int(dato["costo"]), 1, func(): cerrar(); al_elegir.call(tipo), dato["dato"]))
	rejilla.add_child(_tarjeta("camino_quitar", "Quitar camino", {}, "", "QUITAR", true, 1,
		func(): cerrar(); al_elegir.call("quitar"), "Vuelve a dejar pasto donde había camino."))


# ---------------------------------------------------------------- Menús (mochila, semillas, cocina)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("mochila"):
		if abierto == "mochila":
			cerrar()
		elif abierto.is_empty() and _se_puede_abrir():
			abrir_mochila()
		else:
			return
		get_viewport().set_input_as_handled()
	elif not abierto.is_empty() and evento.is_action_pressed("ui_cancel"):
		cerrar()
		get_viewport().set_input_as_handled()


func _se_puede_abrir() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.is_in_group(&"con_reloj") and not Dialogo.activo \
		and not Juego.entrada_bloqueada and not get_tree().paused


func abrir_mochila() -> void:
	_abrir("mochila", "Mochila")
	_contenido.add_child(_estado_energia())
	var cosas := Juego.inventario.keys().filter(func(id): return cantidad(id) > 0)
	if cosas.is_empty():
		_contenido.add_child(_texto("Tu mochila está vacía. Siembra, recolecta plantas en el valle o pesca en el muelle del río."))
		return
	var rejilla := _rejilla()
	for id in cosas:
		var energia := int(datos["objetos"].get(id, {}).get("energia", 0))
		var nota := "+%d de energía" % energia if energia > 0 else ""
		rejilla.add_child(_tarjeta(id, "%s  ×%d" % [nombre(id), cantidad(id)], {}, nota, "COMER" if energia > 0 else "",
			energia > 0, 1, func(): comer(id); abrir_mochila(), _para_que_sirve(id)))


func _para_que_sirve(id: String) -> String:
	if id.begins_with("semilla_"):
		return "Siémbrala en un surco de la milpa."
	if id in Juego.recetario or datos["recetas"].any(func(r): return r["id"] == id):
		return "Un platillo: cómetelo o entrégalo en el tianguis."
	match id:
		"abono":
			return "Échalo a la milpa o a un árbol frutal para que crezca el doble de rápido."
		"aguacate", "guayaba", "limon":
			return "Fruta de tus árboles: cómetela o entrégala en el tianguis."
		"lena":
			return "Para prender el fogón y para expandir la granja."
		"masa", "queso", "miel", "leche", "huevo":
			return "Para cocinar en el fogón o para los pedidos del tianguis."
	return "Para cocinar o para los pedidos del tianguis."


## Arriba de la mochila: la energía del guardián.
func _estado_energia() -> PanelContainer:
	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.14, 0.08, 0.9)
	estilo.border_color = Color(0.55, 0.38, 0.18)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(12)
	caja.add_theme_stylebox_override("panel", estilo)
	var columna := VBoxContainer.new()
	caja.add_child(columna)
	columna.add_child(_texto("Energía: %d / 100" % int(Juego.energia), 28, Color(0.99, 0.86, 0.45)))
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, 22)
	barra.max_value = 100
	barra.value = Juego.energia
	barra.show_percentage = false
	columna.add_child(barra)
	columna.add_child(_texto("Comer platillos te da más energía que comer cosas sueltas.", 20, Color(0.85, 0.95, 0.8)))
	return caja


## Elegir qué sembrar en la parcela `i`. `al_plantar` se llama después de sembrar.
func abrir_semillas(i: int, al_plantar: Callable) -> void:
	_abrir("semillas", "¿Qué siembras?")
	_contenido.add_child(_texto(datos["milpa"], 24, Color(0.85, 0.95, 0.8)))
	var alguna := false
	for cultivo in datos["cultivos"]:
		var semilla: String = datos["cultivos"][cultivo]["semilla"]
		if cantidad(semilla) == 0:
			continue
		alguna = true
		_contenido.add_child(_fila(semilla, "%s  x%d" % [nombre(semilla), cantidad(semilla)], "SEMBRAR",
			func(): plantar(i, cultivo); cerrar(); al_plantar.call()))
	if not alguna:
		_contenido.add_child(_texto("No tienes semillas. Cosecha lo que sembraste: cada cosecha te da una semilla nueva."))


func abrir_cocina() -> void:
	_abrir("cocina", "Fogón")
	_contenido.add_child(_estado_fogon())
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 16)
	rejilla.add_theme_constant_override("v_separation", 16)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_child(rejilla)
	for receta in datos["recetas"]:
		var id: String = receta["id"]
		var energia := int(datos["objetos"][id].get("energia", 0))
		rejilla.add_child(_tarjeta(id, nombre(id) + ("  ★" if id in Juego.recetario else ""), receta["ingredientes"],
			"+%d de energía" % energia, "COCINAR", puede_cocinar(receta), int(receta.get("nivel", 1)),
			func(): _preparar(receta)))


## Arriba del fogón: si está prendido, cuánta leña le queda y los botones para prenderlo,
## echarle leña o apagarlo.
func _estado_fogon() -> PanelContainer:
	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.3, 0.14, 0.05, 0.9) if fogon_prendido() else Color(0.14, 0.12, 0.11, 0.9)
	estilo.border_color = Color(0.99, 0.6, 0.2) if fogon_prendido() else Color(0.4, 0.33, 0.27)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(12)
	caja.add_theme_stylebox_override("panel", estilo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	caja.add_child(fila)
	var dibujo := TextureRect.new()
	dibujo.custom_minimum_size = Vector2(90, 76)
	dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dibujo.texture = FOGON if fogon_prendido() else FOGON_APAGADO
	fila.add_child(dibujo)
	var texto := "Fogón apagado. Préndelo con un leño para cocinar."
	if fogon_prendido():
		texto = "Fogón prendido: tiene leña para unos %d min." % minutos_de_lena()
	elif float(Juego.fogon["horas"]) > 0.0:
		texto = "Fogón apagado. Todavía tiene leña adentro."
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(_texto(texto, 26, Color(0.99, 0.86, 0.45)))
	columna.add_child(_texto("Tienes %d de leña. Apágalo al terminar: no gastas leña y evitas un incendio." % cantidad("lena"),
		20, Color(0.85, 0.95, 0.8)))
	fila.add_child(columna)
	if fogon_prendido():
		fila.add_child(_boton("ECHAR LEÑA", cantidad("lena") > 0 and float(Juego.fogon["horas"]) <= HORAS_POR_LENO * (LENOS_MAX - 1),
			func(): echar_lena(); abrir_cocina()))
		fila.add_child(_boton("APAGAR", true, func(): apagar_fogon(); abrir_cocina()))
	else:
		fila.add_child(_boton("PRENDER", cantidad("lena") > 0 or float(Juego.fogon["horas"]) > 0.0,
			func(): prender_fogon(); abrir_cocina()))
	return caja


## Botón chico de los paneles; apagado si no se puede usar.
func _boton(texto: String, habilitado: bool, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(170, 48)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not habilitado
	if not habilitado:
		# El tema no trae estilo para "deshabilitado": el mismo botón, apagado.
		b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("normal"))
		b.modulate = Color(0.55, 0.55, 0.55)
	b.pressed.connect(accion)
	return b


## Tarjeta de receta o de taller: ícono grande, nombre, ingredientes con ícono y cuántos tienes
## (verde si alcanza, rojo si falta), una nota y el botón. Bloqueada: gris y dice en qué nivel se abre.
func _tarjeta(id: String, titulo: String, ingredientes: Dictionary, nota: String, boton: String,
		habilitado: bool, nivel_minimo: int, accion: Callable, descripcion := "", boton2 := "",
		accion2 := Callable()) -> PanelContainer:
	var bloqueada := nivel() < nivel_minimo
	var tarjeta := PanelContainer.new()
	tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.14, 0.08, 0.9) if not bloqueada else Color(0.16, 0.13, 0.11, 0.9)
	estilo.border_color = Color(0.55, 0.38, 0.18) if habilitado else Color(0.38, 0.27, 0.15)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(14)
	tarjeta.add_theme_stylebox_override("panel", estilo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	tarjeta.add_child(fila)
	var imagen := TextureRect.new()
	imagen.custom_minimum_size = Vector2(96, 96)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture = icono(id)
	imagen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bloqueada:
		imagen.modulate = Color(0.2, 0.2, 0.2)
	fila.add_child(imagen)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.add_theme_constant_override("separation", 6)
	fila.add_child(columna)
	columna.add_child(_texto(titulo, 28, Color(0.99, 0.86, 0.45) if not bloqueada else Color(0.6, 0.55, 0.5)))
	if bloqueada:
		columna.add_child(_texto("Se abre en el nivel %d" % nivel_minimo, 24, Color(0.75, 0.7, 0.65)))
		return tarjeta
	if not descripcion.is_empty():
		columna.add_child(_texto(descripcion, 20, Color(0.85, 0.95, 0.8)))
	var lista := HBoxContainer.new()
	lista.add_theme_constant_override("separation", 6)
	for ingrediente in ingredientes:
		var pide := int(ingredientes[ingrediente])
		var cuadro := TextureRect.new()
		cuadro.custom_minimum_size = Vector2(40, 40)
		cuadro.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cuadro.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cuadro.texture = icono(ingrediente)
		cuadro.tooltip_text = nombre(ingrediente)
		lista.add_child(cuadro)
		var cuenta := _texto("%d/%d" % [cantidad(ingrediente), pide], 22,
			Color(0.65, 1, 0.55) if cantidad(ingrediente) >= pide else Color(1, 0.6, 0.5))
		cuenta.autowrap_mode = TextServer.AUTOWRAP_OFF
		cuenta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lista.add_child(cuenta)
		lista.add_child(Control.new())
	columna.add_child(lista)
	var abajo := HBoxContainer.new()
	var etiqueta := _texto(nota, 20, Color(0.85, 0.95, 0.8))
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	abajo.add_child(etiqueta)
	if not boton2.is_empty():
		var otro := _boton(boton2, true, accion2)
		otro.custom_minimum_size = Vector2(130, 48)
		otro.add_theme_font_size_override("font_size", 20)
		abajo.add_child(otro)
	if not boton.is_empty():
		abajo.add_child(_boton(boton, habilitado, accion))
	columna.add_child(abajo)
	return tarjeta


## Antes de cocinar se prepara el platillo con su minijuego (revolver, voltear, palmear...).
func _preparar(receta: Dictionary) -> void:
	var juego: Dictionary = receta.get("juego", {})
	var primero: String = receta["ingredientes"].keys()[0]
	jugar({"tipo": juego.get("tipo", "revolver"), "escena": juego.get("escena", "olla"), "titulo": nombre(receta["id"]),
		"texto": juego.get("texto", ""), "iconos": [icono(primero), icono(receta["id"])]},
		func(exito: bool):
			if exito and abierto == "cocina":
				_cocinar_con_fuego(receta))


## Abre un minijuego (ver Minijuego) encima de todo; `al_terminar(exito)` decide qué pasa después.
## Esc o SALIR lo cancelan sin gastar nada.
func jugar(config: Dictionary, al_terminar: Callable) -> void:
	var juego := Minijuego.new()
	juego.tipo = config.get("tipo", "machacar")
	juego.escena = config.get("escena", "olla")
	juego.titulo = config.get("titulo", "")
	juego.instruccion = (config.get("texto", "") + "\n" + INSTRUCCION[juego.tipo]).strip_edges()
	juego.iconos = config.get("iconos", [])
	juego.meta = int(config.get("meta", META[juego.tipo]))
	juego.fallas_max = int(config.get("fallas_max", 0))
	# Si no hay un panel abierto (al pescar), el minijuego bloquea al guardián por su cuenta.
	var propio := abierto.is_empty()
	if propio:
		abierto = "juego"
		Juego.entrada_bloqueada = true
	add_child(juego)
	juego.terminado.connect(func(exito: bool):
		juego.queue_free()
		if propio and abierto == "juego":
			abierto = ""
			await get_tree().process_frame
			Juego.entrada_bloqueada = false
		al_terminar.call(exito))


## Al cocinar: el fuego se aviva un momento, luego aparece el platillo con su dato y queda un aviso.
func _cocinar_con_fuego(receta: Dictionary) -> void:
	var id: String = receta["id"]
	var capa := ColorRect.new()
	capa.color = Color(0.05, 0.03, 0.02, 0.92)
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.add_child(capa)
	_capa_cocina = capa
	var centro := VBoxContainer.new()
	centro.set_anchors_preset(Control.PRESET_CENTER)
	centro.grow_horizontal = Control.GROW_DIRECTION_BOTH
	centro.grow_vertical = Control.GROW_DIRECTION_BOTH
	centro.custom_minimum_size = Vector2(900, 0)
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	centro.add_theme_constant_override("separation", 16)
	capa.add_child(centro)
	var dibujo := TextureRect.new()
	dibujo.custom_minimum_size = Vector2(260, 260)
	dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dibujo.texture = FOGON
	dibujo.pivot_offset = Vector2(130, 130)
	dibujo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(dibujo)
	# Chispas que suben del comal (cuadritos, como el resto del pixel art).
	for k in 24:
		var chispa := ColorRect.new()
		chispa.size = Vector2.ONE * randf_range(5, 10)
		chispa.color = Color(1, randf_range(0.5, 0.9), 0.2)
		chispa.position = Vector2(randf_range(80, 180), 80)
		chispa.modulate.a = 0.0
		dibujo.add_child(chispa)
		var subir := chispa.create_tween()
		subir.tween_interval(k * 0.045)
		subir.tween_property(chispa, "modulate:a", 1.0, 0.05)
		subir.tween_property(chispa, "position", chispa.position + Vector2(randf_range(-30, 30), randf_range(-120, -70)), 0.6)
		subir.parallel().tween_property(chispa, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
		subir.tween_callback(chispa.queue_free)
	var texto := _texto("Cocinando %s…" % nombre(id).to_lower(), 34, Color(0.99, 0.86, 0.45))
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(texto)
	var avivar := dibujo.create_tween().set_loops(4)
	avivar.tween_property(dibujo, "modulate", Color(1.25, 1.1, 0.9), 0.14)
	avivar.tween_property(dibujo, "modulate", Color.WHITE, 0.14)
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(capa) or not cocinar(id):
		if is_instance_valid(capa):
			capa.queue_free()
		return
	avivar.kill()
	dibujo.texture = icono(id)
	dibujo.scale = Vector2.ZERO
	dibujo.modulate = Color.WHITE
	var salto := dibujo.create_tween()
	salto.tween_property(dibujo, "scale", Vector2.ONE * 1.15, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	salto.tween_property(dibujo, "scale", Vector2.ONE, 0.12)
	texto.text = "¡Preparaste %s!" % nombre(id).to_lower()
	texto.add_theme_font_size_override("font_size", 40)
	var premio := _texto("+%d de experiencia  ·  ya está en tu mochila" % int(datos["xp"]["cocinar"]), 26, Color(0.65, 1, 0.55))
	premio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(premio)
	var dato := _texto(receta["dato"], 26)
	dato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	centro.add_child(dato)
	var seguir := Button.new()
	seguir.text = "SEGUIR"
	seguir.custom_minimum_size = Vector2(300, 66)
	seguir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seguir.pressed.connect(func():
		capa.queue_free()
		abrir_cocina())
	centro.add_child(seguir)
	seguir.grab_focus()
	avisar_logro(id, "¡Preparaste %s!" % nombre(id).to_lower())


## Aviso pequeño arriba de la pantalla (ícono y texto) que entra, se queda un momento y se va.
func avisar_logro(id: String, texto: String) -> void:
	var aviso := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.2, 0.13, 0.07, 0.95)
	estilo.border_color = Color(0.99, 0.86, 0.45)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(12)
	aviso.add_theme_stylebox_override("panel", estilo)
	aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	aviso.add_child(fila)
	var imagen := TextureRect.new()
	imagen.custom_minimum_size = Vector2(48, 48)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture = icono(id)
	fila.add_child(imagen)
	var etiqueta := _texto(texto, 28, Color(0.99, 0.95, 0.75))
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_OFF
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(etiqueta)
	_avisos.add_child(aviso)
	aviso.modulate.a = 0.0
	var mostrar := aviso.create_tween()
	mostrar.tween_property(aviso, "modulate:a", 1.0, 0.25)
	mostrar.tween_interval(2.8)
	mostrar.tween_property(aviso, "modulate:a", 0.0, 0.4)
	mostrar.tween_callback(aviso.queue_free)


## Panel de un taller: la misma tarjeta que el fogón (qué pide, qué da) y su estado.
func abrir_taller(id: String) -> void:
	var dato: Dictionary = datos["talleres"][id]
	_abrir("taller", dato["nombre"])
	_contenido.add_child(_texto(dato["dato"], 24, Color(0.85, 0.95, 0.8)))
	var producto: String = dato["salida"].keys()[0]
	var cuantos := int(dato["salida"][producto])
	var juego: Dictionary = dato["juego"]
	var entra: String = dato["entrada"].keys()[0] if not dato["entrada"].is_empty() else producto
	var config := {"tipo": juego["tipo"], "escena": juego["escena"], "titulo": dato["nombre"], "texto": juego["texto"],
		"iconos": [icono(entra), icono(producto)]}
	if dato["entrada"].is_empty():
		# La colmena trabaja sola: se juega para sacar la miel que ya hicieron las abejas.
		var listo := int(taller(id)["listo"]) * cuantos
		var minutos := ceili(float(dato["horas"]) * Juego.SEGUNDOS_POR_HORA / 60.0)
		var nota := "Las abejas hacen %d de %s cada %d min." % [cuantos, nombre(producto).to_lower(), minutos]
		if listo > 0:
			nota = "Hay %d de %s lista para sacar." % [listo, nombre(producto).to_lower()]
		elif taller_abierto(id):
			nota += " Faltan unos %d min." % minutos_taller(id)
		_contenido.add_child(_tarjeta(producto, nombre(producto), {}, nota, dato["accion"], listo > 0, int(dato["nivel"]),
			func(): _jugar_taller(id, config)))
		return
	_contenido.add_child(_tarjeta(producto, nombre(producto), dato["entrada"],
		"Da %d de %s" % [cuantos, nombre(producto).to_lower()], dato["accion"], puede_hacer(id), int(dato["nivel"]),
		func(): _jugar_taller(id, config)))


## Al ganar el minijuego: el molino y la quesería hacen su producto; en la colmena se saca la miel.
func _jugar_taller(id: String, config: Dictionary) -> void:
	jugar(config, func(exito: bool):
		if exito:
			_mostrar_hecho(recoger_taller(id) if datos["talleres"][id]["entrada"].is_empty() else hacer_en_taller(id))
			abrir_taller(id))


func _mostrar_hecho(hecho: Dictionary) -> void:
	for producto in hecho:
		avisar_logro(producto, "¡Hiciste %d de %s!" % [int(hecho[producto]), nombre(producto).to_lower()])


func abrir_tianguis() -> void:
	_abrir("tianguis", "Tianguis del valle")
	_contenido.add_child(_estado_tianguis())
	_contenido.add_child(_texto("Pedidos de la gente del valle", 28, Color(0.99, 0.86, 0.45)))
	var pedidos := _rejilla()
	for i in pedidos_tianguis().size():
		var pedido: Dictionary = Juego.tianguis[i]
		pedidos.add_child(_tarjeta(pedido["cosas"].keys()[0], "Pedido de " + pedido.get("quien", "un vecino"), pedido["cosas"],
			"", "ENTREGAR", puede_entregar(pedido), 1, func(): entregar(i); abrir_tianguis(),
			"Te da %d hojas y %d de experiencia." % [int(pedido["hojas"]), int(pedido["xp"])],
			"CAMBIAR", func(): cambiar_pedido(i); abrir_tianguis()))
	_contenido.add_child(_texto("Animales (cada especie tiene su corral)", 28, Color(0.99, 0.86, 0.45)))
	var animales := _rejilla()
	for especie in datos["corral"]:
		var lleno := animales_de(especie) >= ANIMALES_POR_ESPECIE
		if not se_vende(especie):
			continue
		var dato: Dictionary = datos["corral"][especie]
		var costo := int(dato["costo"])
		var da := "No da nada, pero te lleva más rápido." if dato["producto"].is_empty() else \
			"Si le das de comer, al otro día da %d de %s." % [int(dato["cantidad"]), nombre(dato["producto"]).to_lower()]
		var nota := "Su corral está lleno (%d)" % ANIMALES_POR_ESPECIE if lleno else \
			"Tienes %d de %d · cuesta %d hojas" % [animales_de(especie), ANIMALES_POR_ESPECIE, costo]
		animales.add_child(_tarjeta(especie, dato["nombre"], {}, nota, "COMPRAR", not lleno and Juego.hojas >= costo,
			int(dato["nivel"]), func(): comprar_animal(especie); abrir_tianguis(), dato["dato"] + " " + da))
	_contenido.add_child(_texto("Semillas", 28, Color(0.99, 0.86, 0.45)))
	var semillas := _rejilla()
	for id in datos["semillas_tianguis"]:
		var precio := int(datos["semillas_tianguis"][id])
		var minutos := 0
		for cultivo in datos["cultivos"]:
			if datos["cultivos"][cultivo]["semilla"] == id:
				minutos = ceili(float(datos["cultivos"][cultivo]["horas"]) * Juego.SEGUNDOS_POR_HORA / 60.0)
		semillas.add_child(_tarjeta(id, nombre(id), {}, "Cuesta %d hojas · tienes %d" % [precio, cantidad(id)], "COMPRAR",
			Juego.hojas >= precio, 1, func(): comprar_semilla(id); abrir_tianguis(),
			"Siémbrala y riégala: se cosecha en unos %d min." % minutos))


## Arriba del tianguis: el puesto, tu nivel y tus hojas.
func _estado_tianguis() -> PanelContainer:
	var caja := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.14, 0.08, 0.9)
	estilo.border_color = Color(0.55, 0.38, 0.18)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(12)
	caja.add_theme_stylebox_override("panel", estilo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	caja.add_child(fila)
	var dibujo := TextureRect.new()
	dibujo.custom_minimum_size = Vector2(110, 90)
	dibujo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dibujo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dibujo.texture = PUESTO
	fila.add_child(dibujo)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_child(columna)
	var avance := progreso_nivel()
	columna.add_child(_texto("Nivel %d  ·  Tienes %d hojas" % [nivel(), Juego.hojas], 28, Color(0.99, 0.86, 0.45)))
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(0, 22)
	barra.max_value = maxi(int(avance[1]), 1)
	barra.value = int(avance[0])
	barra.show_percentage = false
	columna.add_child(barra)
	columna.add_child(_texto("%d / %d de experiencia para el siguiente nivel. Entrega pedidos para ganar hojas." % [avance[0], avance[1]],
		20, Color(0.85, 0.95, 0.8)))
	return caja


func _rejilla() -> GridContainer:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 16)
	rejilla.add_theme_constant_override("v_separation", 16)
	rejilla.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_child(rejilla)
	return rejilla


func cerrar() -> void:
	if abierto.is_empty():
		return
	abierto = ""
	_fondo.visible = false
	if is_instance_valid(_capa_cocina):
		_capa_cocina.queue_free()
	await get_tree().process_frame
	Juego.entrada_bloqueada = false


func _abrir(tipo: String, titulo: String) -> void:
	abierto = tipo
	_titulo.text = titulo
	for hijo in _contenido.get_children():
		hijo.queue_free()
	_fondo.visible = true
	Juego.entrada_bloqueada = true
	_cerrar.grab_focus()


func _fila(id: String, texto: String, boton: String, accion: Callable) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	var imagen := TextureRect.new()
	imagen.custom_minimum_size = Vector2(56, 56)
	imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen.texture = icono(id)
	fila.add_child(imagen)
	var etiqueta := _texto(texto, 24)
	etiqueta.custom_minimum_size.x = 300
	etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(etiqueta)
	if not boton.is_empty():
		var b := Button.new()
		b.text = boton
		b.custom_minimum_size = Vector2(200, 52)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(accion)
		fila.add_child(b)
	return fila


func _texto(texto: String, tam := 26, color := Color(1, 0.96, 0.86)) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return etiqueta


func _construir_panel() -> void:
	_fondo = ColorRect.new()
	(_fondo as ColorRect).color = Color(0, 0, 0, 0.55)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.visible = false
	add_child(_fondo)
	var caja := PanelContainer.new()
	caja.theme = load("res://assets/ui/tema.tres")
	caja.set_anchors_preset(Control.PRESET_CENTER)
	caja.offset_left = -700
	caja.offset_right = 700
	caja.offset_top = -470
	caja.offset_bottom = 470
	# Que crezca hacia los dos lados si el contenido es más grande (si no, se sale por la derecha).
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BOTH
	_fondo.add_child(caja)
	var margen := MarginContainer.new()
	for lado in ["left", "right"]:
		margen.add_theme_constant_override("margin_" + lado, 80)
	margen.add_theme_constant_override("margin_top", 60)
	margen.add_theme_constant_override("margin_bottom", 46)
	caja.add_child(margen)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margen.add_child(vbox)
	_titulo = _texto("", 44, Color(0.99, 0.86, 0.45))
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_titulo)
	var desplazar := ScrollContainer.new()
	desplazar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desplazar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(desplazar)
	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 10)
	desplazar.add_child(_contenido)
	_cerrar = Button.new()
	_cerrar.text = "CERRAR"
	_cerrar.custom_minimum_size = Vector2(300, 66)
	_cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cerrar.pressed.connect(cerrar)
	vbox.add_child(_cerrar)

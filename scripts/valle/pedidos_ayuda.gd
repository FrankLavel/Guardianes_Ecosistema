class_name PedidosAyuda
extends Node
## Después del final, más o menos una vez al día un animal del valle busca al guardián para pedirle
## ayuda: encontrar a su cría o plantar flores. Al terminar regala hojas, que se gastan en muebles
## para la casa. Los textos están en data/pedidos.json.
##
## El pedido en curso se guarda en Juego.pedido:
##     {"tipo": "basura", "animal": "Venado1", "estado": "aviso" | "activo", "progreso": 0}

signal pedido_cambio

const RUTA := "res://data/pedidos.json"
const ESCENA_OBJETO := preload("res://scenes/valle/ObjetoAyuda.tscn")
const ESCENA_ANIMAL := preload("res://scenes/valle/AnimalValle.tscn")
## Horas de juego entre un pedido y el siguiente (un día son 24 h, unos 12 minutos reales), y cuánto
## tarda el primero después del final.
const HORAS_ENTRE_PEDIDOS := Vector2(20.0, 28.0)
const HORAS_PRIMER_PEDIDO := 6.0
## Parte del valle donde pueden aparecer cosas (lejos del río y de los bordes).
const AREA := Rect2(880, 220, 1760, 1420)
## Qué tan cerca de su mamá hay que llevar a la cría.
const DISTANCIA_CRIA := 110.0

var datos: Dictionary = {}
var animales: Array[AnimalValle] = []
var jugador: Node2D
var hud: Node
## Donde se agregan la basura, la tierra y la cría (el nodo con y-sort del valle).
var contenedor: Node2D
var cria: AnimalValle

var _objetos: Array[ObjetoAyuda] = []


func _ready() -> void:
	datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA))


func configurar(lista: Array[AnimalValle], guardian: Node2D, interfaz: Node, nodo_objetos: Node2D) -> void:
	animales = lista
	jugador = guardian
	hud = interfaz
	contenedor = nodo_objetos
	for animal in animales:
		animal.hablaron.connect(_al_hablar)
		animal.llego_al_jugador.connect(_al_llegar)
	if not Juego.pedido.is_empty():
		_reanudar()


func _process(_delta: float) -> void:
	if not Juego.juego_terminado() or Dialogo.activo or get_tree().paused:
		return
	if Juego.pedido.is_empty():
		# De noche los animales duermen: no piden ayuda.
		if Juego.es_de_noche:
			return
		# Se cuenta con el reloj del juego (que se guarda): salir y volver al valle no lo adelanta.
		if Juego.siguiente_pedido < 0.0:
			Juego.siguiente_pedido = Juego.horas_totales() + HORAS_PRIMER_PEDIDO
		if Juego.horas_totales() >= Juego.siguiente_pedido:
			iniciar_pedido()
	elif cria and cria.estado == AnimalValle.Estado.SIGUE and cria.objetivo == jugador:
		var mama := animal_del_pedido()
		if mama and cria.global_position.distance_to(mama.global_position) < DISTANCIA_CRIA:
			cria.seguir(mama)
			avanzar()


func animales_presentes() -> Array[AnimalValle]:
	return animales.filter(func(a: AnimalValle): return a.visible)


func animal_del_pedido() -> AnimalValle:
	for animal in animales:
		if animal.name == Juego.pedido.get("animal", ""):
			return animal
	return null


func definicion() -> Dictionary:
	return datos["pedidos"].get(Juego.pedido.get("tipo", ""), {})


## Un animal elige un problema y va hacia el guardián. Sin argumentos se elige al azar.
## Devuelve false si no hay ningún animal que pueda pedir ese tipo de ayuda.
func iniciar_pedido(tipo := "", animal: AnimalValle = null) -> bool:
	var opciones := []
	for a in animales_presentes():
		if animal and a != animal:
			continue
		for t in datos["pedidos"]:
			if (tipo.is_empty() or t == tipo) and a.especie in datos["pedidos"][t]["animales"]:
				opciones.append([t, a])
	if opciones.is_empty():
		Juego.siguiente_pedido = Juego.horas_totales() + 1.0
		return false
	var elegido: Array = opciones.pick_random()
	Juego.pedido = {"tipo": elegido[0], "animal": String(elegido[1].name), "especie": elegido[1].especie,
		"estado": "aviso", "progreso": 0}
	elegido[1].ir_hacia(jugador)
	pedido_cambio.emit()
	return true


func _al_llegar(animal: AnimalValle) -> void:
	if Juego.pedido.get("animal") == animal.name and Juego.pedido.get("estado") == "aviso":
		Sonido.efecto("punto_control")
		hud.mostrar_objetivo("¡Un animal necesita tu ayuda! Habla con él (E).")


func _al_hablar(animal: AnimalValle) -> void:
	if Juego.pedido.is_empty() or Juego.pedido["animal"] != animal.name:
		if Juego.es_de_noche:
			_hablar(animal, ["Zzz... zzz... (Está dormido. Vuelve cuando amanezca.)"])
		else:
			_hablar(animal, [datos["saludos"].get(animal.especie, ["..."]).pick_random()])
		return
	var def := definicion()
	if Juego.pedido["estado"] == "aviso":
		await _hablar(animal, def["pedir"])
		_activar()
	elif int(Juego.pedido["progreso"]) >= int(def["meta"]):
		await _hablar(animal, def["gracias"])
		_terminar()
	else:
		_hablar(animal, def["recordar"])


func _hablar(animal: AnimalValle, textos: Array) -> void:
	var lineas := []
	for texto in textos:
		lineas.append({"quien": animal.especie, "texto": texto})
	await Dialogo.mostrar_lineas("_animal", lineas)


func _activar() -> void:
	Juego.pedido["estado"] = "activo"
	var animal := animal_del_pedido()
	animal.esperar()
	animal.mostrar_alerta("…")
	_aparecer_objetivos()
	_mostrar_objetivo()
	Juego.guardar()
	pedido_cambio.emit()


## Lo que hay que hacer: basura o tierra cerca del animal, o la cría lejos de él.
func _aparecer_objetivos() -> void:
	var animal := animal_del_pedido()
	var faltan := int(definicion()["meta"]) - int(Juego.pedido["progreso"])
	if Juego.pedido["tipo"] == "cria":
		if faltan > 0:
			_aparecer_cria(animal)
		return
	var tipo_objeto := "basura" if Juego.pedido["tipo"] == "basura" else "tierra"
	var usados: Array[Vector2] = []
	for i in faltan:
		var objeto: ObjetoAyuda = ESCENA_OBJETO.instantiate()
		objeto.tipo = tipo_objeto
		objeto.planta = "flores" if Juego.pedido["tipo"] == "flores" else "arbolito"
		objeto.position = _lugar_cerca(animal.global_position, usados)
		usados.append(objeto.position)
		objeto.usado.connect(func(_o): avanzar())
		contenedor.add_child(objeto)
		_objetos.append(objeto)


func _aparecer_cria(mama: AnimalValle) -> void:
	cria = ESCENA_ANIMAL.instantiate()
	cria.name = "Cria"
	cria.especie = mama.especie
	cria.cuadros = mama.cuadros
	# Si la hoja del animal trae su cría, se usa; si no, la mamá en chiquito.
	if mama.cuadros.has_animation(&"cria"):
		cria.anim_quieto = &"cria"
		cria.anim_caminar = &"cria"
		cria.escala = mama.escala
	else:
		cria.anim_quieto = mama.anim_quieto
		cria.anim_caminar = mama.anim_caminar
		cria.escala = mama.escala * 0.6
	cria.mira_derecha = mama.mira_derecha
	cria.velocidad = mama.velocidad
	cria.texto_aviso = "E  Llamar a la cría"
	var lugar := mama.global_position
	for intento in 30:
		lugar = Vector2(randf_range(AREA.position.x, AREA.end.x), randf_range(AREA.position.y, AREA.end.y))
		if lugar.distance_to(mama.global_position) > 700.0:
			break
	cria.position = lugar
	cria.zona_paseo = Rect2(lugar - Vector2(80, 60), Vector2(160, 120))
	cria.hablaron.connect(_al_llamar_cria)
	contenedor.add_child(cria)


func _al_llamar_cria(_c: AnimalValle) -> void:
	if cria.estado == AnimalValle.Estado.SIGUE:
		return
	cria.seguir(jugador)
	# Ya no se le habla: solo camina detrás.
	cria.monitoring = false
	cria.get_node("Aviso").visible = false
	if jugador.has_method("quitar_interactuable"):
		jugador.quitar_interactuable(cria)
	Sonido.efecto("correcto")
	hud.mostrar_objetivo("La cría te sigue. Llévala con su mamá.")


func _lugar_cerca(centro: Vector2, ocupados: Array[Vector2]) -> Vector2:
	var lugar := centro
	for intento in 30:
		var angulo := randf() * TAU
		lugar = centro + Vector2(cos(angulo), sin(angulo)) * randf_range(140.0, 300.0)
		lugar = lugar.clamp(AREA.position, AREA.end)
		if ocupados.all(func(o: Vector2): return o.distance_to(lugar) > 90.0):
			break
	return lugar


## Un objetivo más cumplido (una basura, un arbolito o la cría de vuelta).
func avanzar() -> void:
	if Juego.pedido.is_empty():
		return
	Juego.pedido["progreso"] = int(Juego.pedido["progreso"]) + 1
	if int(Juego.pedido["progreso"]) >= int(definicion()["meta"]):
		animal_del_pedido().mostrar_alerta("!")
		hud.mostrar_objetivo("¡Listo! Regresa a hablar con el animal que te pidió ayuda.")
	else:
		_mostrar_objetivo()
	Juego.guardar()
	pedido_cambio.emit()


func _terminar() -> void:
	var def := definicion()
	Juego.dar_hojas(int(def["recompensa"]))
	Granja.dar_xp(int(Granja.datos["xp"]["ayudar_animal"]))
	Juego.contar_ayuda(Juego.pedido["tipo"])
	var animal := animal_del_pedido()
	animal.volver_a_pasear()
	if cria:
		var irse := cria.create_tween()
		irse.tween_property(cria, "modulate:a", 0.0, 1.5).set_delay(2.0)
		irse.tween_callback(cria.queue_free)
		cria = null
	_objetos.clear()
	Juego.pedido = {}
	Juego.siguiente_pedido = Juego.horas_totales() + randf_range(HORAS_ENTRE_PEDIDOS.x, HORAS_ENTRE_PEDIDOS.y)
	Sonido.efecto("zona_restaurada")
	hud.mostrar_objetivo("+%d hojas  ·  Gástalas en muebles para tu casa." % int(def["recompensa"]))
	Juego.guardar()
	pedido_cambio.emit()


func _mostrar_objetivo() -> void:
	hud.mostrar_objetivo(texto_objetivo())


func texto_objetivo() -> String:
	if Juego.pedido.is_empty():
		return ""
	var def := definicion()
	var texto: String = def["objetivo"].replace("{del_animal}", datos["nombres"].get(Juego.pedido.get("especie", ""), ""))
	if int(def["meta"]) > 1:
		texto += " (%d/%d)" % [int(Juego.pedido["progreso"]), int(def["meta"])]
	return texto


## Al volver al valle con un pedido a medias: el animal espera y vuelve a aparecer lo que falta.
func _reanudar() -> void:
	var animal := animal_del_pedido()
	# Partidas con un pedido que ya no existe (recoger basura o plantar árboles): se olvida.
	if animal == null or not animal.visible or definicion().is_empty():
		Juego.pedido = {}
		return
	if Juego.pedido["estado"] == "aviso":
		animal.ir_hacia(jugador)
		return
	animal.esperar()
	if int(Juego.pedido["progreso"]) >= int(definicion()["meta"]):
		animal.mostrar_alerta("!")
	else:
		animal.mostrar_alerta("…")
		_aparecer_objetivos()

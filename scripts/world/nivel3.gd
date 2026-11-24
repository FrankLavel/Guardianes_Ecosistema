extends Node2D
## Nivel 3 - El lago de Pátzcuaro.
## Se cruza el lago nadando: hay que quitar el lirio que tapa la luz, rescatar los huevos de
## achoque del fondo y sacar la basura que flota. En la orilla, la cadena alimenticia (puzzle).
## Al final se sube con una enredadera hasta el muelle (meta).

const MARGEN_CAIDA := 200.0
## Limpieza del agua al empezar (turbia, pero sin veneno: se puede nadar).
const LIMPIEZA_INICIAL := 0.5

var nivel_terminado := false
## La basura recogida se borra de la escena: se guarda la lista completa al empezar.
var _basuras: Array = []

@onready var terreno: TileMapLayer = $Terreno
@onready var guardian: Guardian = $Guardian
@onready var hud: HUD = $HUD
@onready var pantalla_final: NivelCompletado = $NivelCompletado
@onready var meta: Meta = $Meta
@onready var fondo: FondoZona = $FondoZona3
@onready var lago: Rio = $Lago
@onready var cadena: EstacionPuzzle = $Mirador


func _ready() -> void:
	add_to_group(&"jugable")
	_basuras.assign(_hijos("BasuraLago"))
	Sonido.musica("lago")
	_ajustar_camara()
	# La meta del lago es el muelle.
	var muelle: Sprite2D = meta.get_node("Sprite2D")
	muelle.texture = preload("res://assets/objects/zona3/muelle.png")
	muelle.scale = Vector2(0.35, 0.35)
	# Las patas quedan hundidas en el pasto, no apoyadas encima.
	muelle.offset = Vector2(0, -muelle.texture.get_height() / 2.0 + 45)
	for lirio in lirios():
		lirio.quitado.connect(_al_quitar_lirio)
	for huevo in huevos():
		huevo.rescatado.connect(_al_rescatar_huevo)
	for basura in basuras():
		basura.recogida.connect(func(_b): _actualizar.call_deferred())
	for tierra in $Tierras.get_children():
		tierra.plantada.connect(_actualizar)
	cadena.resuelta.connect(_al_resolver_cadena)
	lago.guardian_cayo.connect(func(g): g.call_deferred("reaparecer"))
	meta.guardian_llego.connect(_al_llegar_a_meta)
	lago.limpieza = LIMPIEZA_INICIAL
	_actualizar()
	hud.mostrar_mensaje("El lago está cubierto de lirio",
		"El lirio tapa la luz del sol. ¡Nada y quítalo con E! Busca también los huevos de achoque en el fondo.", 7.0)


func _hijos(grupo: String) -> Array:
	return get_node(grupo).get_children()


func lirios() -> Array[Lirio]:
	var lista: Array[Lirio] = []
	lista.assign(_hijos("Lirios"))
	return lista


func huevos() -> Array[HuevoAchoque]:
	var lista: Array[HuevoAchoque] = []
	lista.assign(_hijos("Huevos"))
	return lista


func basuras() -> Array:
	return _basuras


func basura_recogida(b) -> bool:
	return not is_instance_valid(b) or b.fue_recogida


func huevos_rescatados() -> int:
	return huevos().filter(func(h): return h.esta_rescatado).size()


## Tareas que restauran el lago: [hecha, nombre].
func tareas() -> Array:
	var lista := []
	for l in lirios():
		lista.append([l.esta_quitado, "lirio"])
	for h in huevos():
		lista.append([h.esta_rescatado, "huevo"])
	for b in basuras():
		lista.append([basura_recogida(b), "basura"])
	lista.append([cadena.esta_resuelta, "cadena"])
	return lista


func tareas_hechas() -> int:
	return tareas().filter(func(t): return t[0]).size()


func salud_del_lago() -> float:
	return float(tareas_hechas()) / tareas().size()


func lago_listo() -> bool:
	return tareas_hechas() == tareas().size()


func obtener_limites_terreno() -> Rect2:
	var celdas := terreno.get_used_rect()
	var tamano_tile := Vector2(terreno.tile_set.tile_size)
	var inicio := terreno.to_global(Vector2(celdas.position) * tamano_tile)
	return Rect2(inicio, Vector2(celdas.size) * tamano_tile)


func _ajustar_camara() -> void:
	var limites := obtener_limites_terreno()
	var camara := guardian.camara
	# La primera y la última columna son las paredes del nivel: la cámara no las muestra.
	var columna := limites.size.x / terreno.get_used_rect().size.x
	camara.limit_left = int(limites.position.x + columna)
	camara.limit_top = int(limites.position.y) - 500
	camara.limit_right = int(limites.end.x - columna)
	camara.limit_bottom = int(limites.end.y)
	guardian.limite_caida = limites.end.y + MARGEN_CAIDA


func _actualizar() -> void:
	var salud := salud_del_lago()
	hud.actualizar(tareas_hechas(), tareas().size(), salud)
	fondo.animar_limpieza(salud)
	lago.animar_limpieza(LIMPIEZA_INICIAL + (1.0 - LIMPIEZA_INICIAL) * salud)
	if lago_listo() and not lago.hay_peces():
		lago.mostrar_peces(3)
		Bitacora.descubrir("pescado_blanco")
		_traer_pato()


func _al_quitar_lirio() -> void:
	_actualizar()
	if lirios().all(func(l): return l.esta_quitado):
		hud.mostrar_mensaje("¡Ya entra la luz al lago!",
			"El lirio no es de aquí: crece tanto que tapa el sol y las plantas del fondo se mueren.", 6.0)


func _al_rescatar_huevo() -> void:
	_actualizar()
	var n := huevos_rescatados()
	if n == huevos().size():
		Bitacora.descubrir("achoque")
		hud.mostrar_mensaje("¡Rescataste todos los huevos de achoque!",
			"El achoque solo vive en el lago de Pátzcuaro. Con agua limpia, sus crías podrán crecer.", 6.0)
	else:
		hud.mostrar_mensaje("Huevo de achoque: %d / %d" % [n, huevos().size()],
			"Sigue buscando en el fondo del lago.", 3.0)


func _al_resolver_cadena() -> void:
	_actualizar()


func _al_llegar_a_meta(_cuerpo: Guardian) -> void:
	if nivel_terminado:
		return
	if lago_listo():
		nivel_terminado = true
		pantalla_final.mostrar()
		return
	var falta := []
	var lirio := lirios().filter(func(l): return not l.esta_quitado).size()
	var huevo := huevos().size() - huevos_rescatados()
	var basura := basuras().filter(func(b): return not basura_recogida(b)).size()
	if lirio > 0:
		falta.append("quitar %d lirio%s" % [lirio, "s" if lirio > 1 else ""])
	if huevo > 0:
		falta.append("rescatar %d huevo%s" % [huevo, "s" if huevo > 1 else ""])
	if basura > 0:
		falta.append("sacar %d basura%s" % [basura, "s" if basura > 1 else ""])
	if not cadena.esta_resuelta:
		falta.append("armar la cadena alimenticia en el mirador")
	hud.mostrar_mensaje("El lago todavía necesita ayuda", "Te falta: " + ", ".join(falta) + ".", 5.0)


## Con el lago limpio llega un pato mexicano nadando.
func _traer_pato() -> void:
	var pato := AnimatedSprite2D.new()
	pato.name = "Pato"
	pato.sprite_frames = preload("res://assets/characters/animales/zona3_animales_frames.tres")
	pato.animation = &"pato"
	pato.play()
	pato.scale = Vector2(0.16, 0.16)
	pato.offset = Vector2(0, -150)
	pato.z_index = 2
	var superficie := lago.global_position.y + 6.0
	pato.global_position = Vector2(lago.global_position.x + lago.tamano.x - 60.0, superficie)
	pato.flip_h = true
	add_child(pato)
	var paseo := create_tween().set_loops()
	paseo.tween_property(pato, "global_position:x", lago.global_position.x + 120.0, 14.0)
	paseo.tween_callback(func(): pato.flip_h = false)
	paseo.tween_property(pato, "global_position:x", lago.global_position.x + lago.tamano.x - 60.0, 14.0)
	paseo.tween_callback(func(): pato.flip_h = true)

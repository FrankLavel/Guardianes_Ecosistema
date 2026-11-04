class_name Parcela
extends ZonaInteraccion
## Un surco de la milpa: sembrar, regar una vez al día y cosechar (ver Granja).

signal aviso(texto: String)

## Las plantas van en hilera sobre el lomo de en medio (la tierra la dibuja MilpaSuelo).
const ESCALA_PLANTA := 0.24
const HILERA := [-40.0, 0.0, 40.0]
const HILERA_CALABAZA := [-28.0, 28.0]

@export var indice := 0

var _plantas: Array[Sprite2D] = []
var _reloj := 0.0
## Cómo estaba la parcela la última vez (para animar lo que cambió: sembrar, regar, abonar, crecer, cosechar).
var _antes: Dictionary = {}


func _ready() -> void:
	for x in HILERA:
		var planta := Sprite2D.new()
		planta.scale = Vector2.ONE * ESCALA_PLANTA
		add_child(planta)
		_plantas.append(planta)
	super()
	actualizar()
	Granja.parcelas_cambio.connect(actualizar)


## El aviso dice cuánto falta mientras crece.
func _process(delta: float) -> void:
	_reloj += delta
	if _reloj >= 1.0:
		_reloj = 0.0
		actualizar()


func actualizar() -> void:
	var p := Granja.parcela(indice)
	var ahora := {"cultivo": p["cultivo"], "etapa": int(p["etapa"]), "regada": p["regada"], "abonada": p.get("abonada", false)}
	var cambio := ""
	if not _antes.is_empty():
		if _antes["cultivo"].is_empty() and not ahora["cultivo"].is_empty():
			cambio = "sembrar"
		elif not _antes["cultivo"].is_empty() and ahora["cultivo"].is_empty():
			_cosechar_animado()
		elif not _antes["abonada"] and ahora["abonada"]:
			cambio = "abonar"
		elif not _antes["regada"] and ahora["regada"]:
			cambio = "regar"
		elif _antes["etapa"] != ahora["etapa"]:
			cambio = "crecer"
	_antes = ahora
	var textura := Granja.textura_planta(indice)
	# La calabaza se extiende: van dos matas en lugar de tres.
	var hilera: Array = HILERA_CALABAZA if p["cultivo"] == "calabaza" else HILERA
	for k in _plantas.size():
		var planta := _plantas[k]
		planta.visible = textura != null and k < hilera.size()
		if planta.visible:
			planta.texture = textura
			planta.offset = Vector2(0, -textura.get_height() / 2.0)
			planta.position = Vector2(hilera[k], 6.0)
	var texto := "E  Sembrar"
	if indice >= Granja.surcos():
		texto = "Se abre en el nivel %d" % Granja.nivel_del_surco(indice)
	elif not p["cultivo"].is_empty():
		if int(p["etapa"]) >= Granja.LISTO:
			texto = "E  Cosechar"
		elif not p["regada"]:
			texto = "E  Regar"
		elif Granja.puede_abonar(indice):
			texto = "E  Abonar · %d min" % Granja.minutos_restantes(indice)
		else:
			texto = "Creciendo · %d min" % Granja.minutos_restantes(indice)
	_aviso.text = texto
	match cambio:
		"sembrar":
			_caen(Color(0.42, 0.27, 0.12), 10, 0.45)
			_brotar(0.2)
		"regar":
			_caen(Color(0.45, 0.75, 1.0), 18, 0.55)
		"abonar":
			_caen(Color(0.3, 0.2, 0.1), 14, 0.5)
			_chispas(Color(0.6, 1, 0.4), 6)
		"crecer":
			_brotar(1.0)


## Las plantas salen de la tierra con un pequeño rebote (`desde`: qué tan chicas empiezan).
func _brotar(desde: float) -> void:
	for planta in _plantas:
		if not planta.visible:
			continue
		planta.scale = Vector2(ESCALA_PLANTA * (1.25 if desde >= 1.0 else desde), ESCALA_PLANTA * (0.8 if desde >= 1.0 else desde))
		var rebote := planta.create_tween()
		rebote.tween_property(planta, "scale", Vector2.ONE * ESCALA_PLANTA, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Semillas, gotas de agua o abono que caen sobre el surco.
func _caen(color: Color, cuantas: int, tiempo: float) -> void:
	for i in cuantas:
		var gota := ColorRect.new()
		gota.color = color
		gota.size = Vector2(6, 8) if color.b > 0.8 else Vector2(6, 6)
		gota.position = Vector2(randf_range(-55, 55), randf_range(-120, -80))
		gota.z_index = 2
		gota.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(gota)
		var caer := gota.create_tween()
		caer.tween_interval(i * tiempo / cuantas)
		caer.tween_property(gota, "position:y", randf_range(-6, 8), tiempo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		caer.tween_property(gota, "modulate:a", 0.0, 0.2)
		caer.tween_callback(gota.queue_free)


## Destellos que suben (abono, cosecha).
func _chispas(color: Color, cuantas: int) -> void:
	for i in cuantas:
		var chispa := ColorRect.new()
		chispa.color = color
		chispa.size = Vector2(5, 5)
		chispa.position = Vector2(randf_range(-50, 50), randf_range(-30, 0))
		chispa.z_index = 2
		chispa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(chispa)
		var subir := chispa.create_tween()
		subir.tween_interval(0.3 + i * 0.05)
		subir.tween_property(chispa, "position", chispa.position + Vector2(randf_range(-20, 20), -70), 0.6)
		subir.parallel().tween_property(chispa, "modulate:a", 0.0, 0.6)
		subir.tween_callback(chispa.queue_free)


## Al cosechar, las matas brincan y desaparecen (antes de que el surco quede vacío).
func _cosechar_animado() -> void:
	for planta in _plantas:
		if not planta.visible or planta.texture == null:
			continue
		var copia := Sprite2D.new()
		copia.texture = planta.texture
		copia.offset = planta.offset
		copia.position = planta.position
		copia.scale = planta.scale
		copia.z_index = 2
		add_child(copia)
		var brinco := copia.create_tween()
		brinco.tween_property(copia, "position:y", copia.position.y - 50, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		brinco.parallel().tween_property(copia, "scale", copia.scale * 0.4, 0.5)
		brinco.parallel().tween_property(copia, "modulate:a", 0.0, 0.5).set_delay(0.15)
		brinco.tween_callback(copia.queue_free)
	_chispas(Color(1, 0.9, 0.4), 8)


func _al_interactuar(_jugador: Node2D) -> void:
	var p := Granja.parcela(indice)
	if indice >= Granja.surcos():
		aviso.emit("Este surco se abre en el nivel %d. Cosecha y entrega pedidos para subir." % Granja.nivel_del_surco(indice))
	elif p["cultivo"].is_empty():
		Granja.abrir_semillas(indice, actualizar)
	elif int(p["etapa"]) >= Granja.LISTO:
		var cosecha := Granja.cosechar(indice)
		var fila := 0
		for id in cosecha:
			Granja.mostrar_recogida(id, int(cosecha[id]), global_position + Vector2(0, -40), fila)
			fila += 1
	elif Granja.regar(indice):
		aviso.emit("¡La regaste! Estará lista en unos %d minutos." % Granja.minutos_restantes(indice))
	elif Granja.abonar(indice):
		aviso.emit("¡Le echaste abono! Ahora crece el doble de rápido: faltan unos %d minutos." % Granja.minutos_restantes(indice))
	else:
		aviso.emit("Está creciendo. Faltan unos %d minutos." % Granja.minutos_restantes(indice))
	actualizar()

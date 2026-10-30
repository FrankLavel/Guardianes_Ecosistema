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
		else:
			texto = "Creciendo · %d min" % Granja.minutos_restantes(indice)
	_aviso.text = texto


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
	else:
		aviso.emit("Está creciendo. Faltan unos %d minutos." % Granja.minutos_restantes(indice))
	actualizar()

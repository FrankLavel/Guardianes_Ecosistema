extends Node
## Música y efectos de sonido (autoload "Sonido").
##
##     Sonido.efecto("recoger")
##     Sonido.musica("valle")
##
## Los archivos están en assets/audio/sfx/<nombre>.wav y assets/audio/musica/<nombre>.wav.

const CARPETA_SFX := "res://assets/audio/sfx/%s.wav"
const CARPETA_MUSICA := "res://assets/audio/musica/%s.wav"
const VOCES := 8
const FUNDIDO := 0.8

const RUTA_OPCIONES := "user://opciones.cfg"

var musica_actual := ""
## Volumen (0 a 1) de cada bus; se guarda en user://opciones.cfg.
var opciones := {"Master": 0.8, "Musica": 0.7, "Efectos": 0.9}

var _voces: Array[AudioStreamPlayer] = []
var _siguiente_voz := 0
var _reproductor_musica: AudioStreamPlayer
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOCES:
		var voz := AudioStreamPlayer.new()
		voz.bus = &"Efectos"
		add_child(voz)
		_voces.append(voz)
	_reproductor_musica = AudioStreamPlayer.new()
	_reproductor_musica.bus = &"Musica"
	add_child(_reproductor_musica)
	_cargar_opciones()
	# Todos los botones del juego suenan al presionarlos.
	get_tree().node_added.connect(func(nodo: Node):
		if nodo is BaseButton:
			nodo.pressed.connect(efecto.bind("boton", 0.0)))


func _cargar(ruta: String) -> AudioStream:
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
		if _cache[ruta] == null:
			push_warning("No existe el sonido: %s" % ruta)
	return _cache[ruta]


func efecto(nombre: String, variacion_tono := 0.0) -> void:
	var stream := _cargar(CARPETA_SFX % nombre)
	if stream == null:
		return
	var voz := _voces[_siguiente_voz]
	_siguiente_voz = (_siguiente_voz + 1) % VOCES
	voz.stream = stream
	voz.pitch_scale = 1.0 + randf_range(-variacion_tono, variacion_tono)
	voz.play()


func musica(nombre: String) -> void:
	if nombre == musica_actual:
		return
	musica_actual = nombre
	var stream := _cargar(CARPETA_MUSICA % nombre)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	var fundido := create_tween()
	if _reproductor_musica.playing:
		fundido.tween_property(_reproductor_musica, "volume_db", -40.0, FUNDIDO)
	fundido.tween_callback(func():
		_reproductor_musica.stream = stream
		_reproductor_musica.volume_db = -40.0
		if stream:
			_reproductor_musica.play())
	fundido.tween_property(_reproductor_musica, "volume_db", 0.0, FUNDIDO)


func detener_musica() -> void:
	musica_actual = ""
	create_tween().tween_property(_reproductor_musica, "volume_db", -40.0, FUNDIDO).finished.connect(_reproductor_musica.stop)


## Volumen de un bus (0 a 1).
func fijar_volumen(bus: String, valor: float) -> void:
	opciones[bus] = valor
	var indice := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(valor, 0.0001)))
	AudioServer.set_bus_mute(indice, valor <= 0.001)


func guardar_opciones() -> void:
	var cfg := ConfigFile.new()
	for bus in opciones:
		cfg.set_value("volumen", bus, opciones[bus])
	cfg.save(RUTA_OPCIONES)


func _cargar_opciones() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_OPCIONES) == OK:
		for bus in opciones:
			opciones[bus] = float(cfg.get_value("volumen", bus, opciones[bus]))
	for bus in opciones:
		fijar_volumen(bus, opciones[bus])

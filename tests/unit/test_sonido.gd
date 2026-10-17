extends GutTest
## Audio: buses, archivos de efectos y música, y volúmenes.

const EFECTOS := ["salto", "recoger", "boton", "dialogo", "correcto", "incorrecto", "valvula",
	"chapoteo", "brazada", "zona_restaurada", "punto_control"]
const MUSICAS := ["valle", "rio", "puzzle"]


func test_existen_los_buses_de_musica_y_efectos() -> void:
	assert_ne(AudioServer.get_bus_index("Musica"), -1)
	assert_ne(AudioServer.get_bus_index("Efectos"), -1)


func test_existen_todos_los_sonidos() -> void:
	for nombre in EFECTOS:
		assert_true(ResourceLoader.exists(Sonido.CARPETA_SFX % nombre), "Falta efecto: %s" % nombre)
	for nombre in MUSICAS:
		assert_true(ResourceLoader.exists(Sonido.CARPETA_MUSICA % nombre), "Falta música: %s" % nombre)


func test_la_musica_se_repite_en_bucle() -> void:
	Sonido.musica("rio")
	var stream: AudioStreamWAV = load(Sonido.CARPETA_MUSICA % "rio")
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(Sonido.musica_actual, "rio")


func test_fijar_volumen_cambia_el_bus() -> void:
	var anterior: float = Sonido.opciones["Efectos"]
	Sonido.fijar_volumen("Efectos", 0.5)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Efectos")), -6.02, 0.05)
	Sonido.fijar_volumen("Efectos", anterior)

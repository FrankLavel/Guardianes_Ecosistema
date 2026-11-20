class_name TextosTactiles
extends Translation
## En pantallas táctiles, los textos que mencionan teclas ("presiona E", "(I)", "Tab: ...") se cambian
## por el botón que hay en pantalla. Se registra como traducción (ver Tactil): Godot pasa por aquí
## todos los textos que muestran las etiquetas y botones, así no hay que cambiar cada mensaje.

## Frases completas primero (las instrucciones de los minijuegos), luego trozos.
const CAMBIOS := [
	["Presiona ← y → (o A y D) una y otra vez, o haz clic a cada lado.", "Toca un lado y luego el otro, una y otra vez."],
	["Presiona E o haz clic muchas veces.", "Toca muchas veces."],
	["Presiona E o haz clic cuando la marca blanca esté en lo verde.", "Toca cuando la marca blanca esté en lo verde."],
	["Tab: abrir la bitácora", "Toca el libro para abrir la bitácora"],
	["presiona ↑ para trepar", "empuja el joystick hacia arriba para trepar"],
	["trepa con ↑", "trepa con el joystick hacia arriba"],
	["presiona E", "toca el botón de la mano"],
	["Presiona E", "Toca el botón de la mano"],
	["con E", "con el botón de la mano"],
	["(E)", "(botón de la mano)"],
	["(I)", "(botón de la mochila)"],
	[" (C)", ""],
	["haz clic o arrastra", "toca o arrastra"],
]


static func cambiar(texto: String) -> String:
	# Avisos sobre los objetos ("E  Hablar"): en el celular la E es el botón de la mano.
	if texto.begins_with("E  "):
		texto = texto.substr(3)
	for par in CAMBIOS:
		if texto.contains(par[0]):
			texto = texto.replace(par[0], par[1])
	return texto


func _get_message(mensaje: StringName, _contexto: StringName) -> StringName:
	var original := String(mensaje)
	var nuevo := cambiar(original)
	# Sin cambios se devuelve vacío: Godot entonces muestra el texto tal cual.
	return StringName(nuevo) if nuevo != original else &""

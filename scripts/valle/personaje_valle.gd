class_name PersonajeValle
extends ZonaInteraccion
## Personaje con el que se habla. Elige el diálogo según el progreso de la partida.

## Lista de [condición, id de diálogo]; se usa el primero cuya condición se cumpla.
## Condiciones: "zona:<id>" (zona completa), "marca:<id>" (meta cumplida),
## "visto:<id>" (diálogo ya visto), "siempre".
@export var dialogos: Array[PackedStringArray] = []
## Para personajes que vuelan (Mari): sube y baja y "aletea" estrechando el dibujo.
@export var aleteo := false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	super()
	if aleteo:
		var escala := sprite.scale
		var vuelo := create_tween().set_loops()
		vuelo.tween_property(sprite, "scale:x", escala.x * 0.35, 0.18)
		vuelo.tween_property(sprite, "scale:x", escala.x, 0.18)
		var flotar := create_tween().set_loops()
		flotar.tween_property(sprite, "position:y", sprite.position.y - 12.0, 0.9).set_trans(Tween.TRANS_SINE)
		flotar.tween_property(sprite, "position:y", sprite.position.y, 0.9).set_trans(Tween.TRANS_SINE)


func dialogo_actual() -> String:
	for opcion in dialogos:
		if opcion.size() == 2 and _cumple(opcion[0]):
			return opcion[1]
	return ""


func _cumple(condicion: String) -> bool:
	if condicion == "siempre":
		return true
	var partes := condicion.split(":")
	match partes[0]:
		"zona":
			return Juego.zona_esta_completa(partes[1])
		"marca":
			return Juego.tiene_marca(partes[1])
		"visto":
			return partes[1] in Juego.dialogos_vistos
		"no_visto":
			return partes[1] not in Juego.dialogos_vistos
	return false


func _al_interactuar(jugador: Node2D) -> void:
	var id := dialogo_actual()
	if id.is_empty() or Dialogo.activo:
		return
	if jugador is GaraAerea:
		jugador.mirar_hacia(global_position)
	sprite.flip_h = jugador.global_position.x < global_position.x
	sprite.play(&"hablar")
	await Dialogo.mostrar(id)
	sprite.play(&"idle")

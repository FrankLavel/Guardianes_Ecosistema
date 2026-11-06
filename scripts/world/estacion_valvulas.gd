class_name EstacionValvulas
extends Area2D
## Tubería de la fábrica con sus válvulas. Al interactuar se abre el puzzle de las compuertas;
## al resolverlo deja de salir agua sucia y desaparece el charco tóxico.

signal resuelta

const MARCA := "rio_compuertas"

var esta_resuelta := false

@onready var puzzle: PuzzleCompuertas = $PuzzleCompuertas
@onready var _chorro: Sprite2D = $Tuberia
@onready var _charco: Sprite2D = $Charco
@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	puzzle.resuelto.connect(_al_resolver)
	if Juego.tiene_marca(MARCA):
		_al_resolver()


func interactuar(_guardian: Node) -> void:
	if not esta_resuelta:
		puzzle.abrir()


func _al_resolver() -> void:
	if esta_resuelta:
		return
	esta_resuelta = true
	Juego.marcar(MARCA)
	_aviso.visible = false
	# Ya no sale agua sucia: la tubería se ve limpia y el charco se seca.
	var cambio := create_tween().set_parallel()
	cambio.tween_property(_chorro, "modulate", Color(0.75, 0.8, 0.75), 0.8)
	cambio.tween_property(_charco, "modulate:a", 0.0, 1.2)
	resuelta.emit()


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not esta_resuelta:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

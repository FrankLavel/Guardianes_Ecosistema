class_name EstacionPuzzle
extends Area2D
## Lugar de un nivel que abre un puzzle al interactuar (por ejemplo, el vivero del bosque).
## El puzzle es un nodo hijo llamado "Puzzle". Al resolverlo se cumple `marca`.

signal resuelta

@export var marca := ""
@export var texto_aviso := "E  Revisar"

var esta_resuelta := false

@onready var puzzle: PuzzleBase = $Puzzle
@onready var _aviso: Label = $Aviso


func _ready() -> void:
	_aviso.text = texto_aviso
	_aviso.visible = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	puzzle.resuelto.connect(_al_resolver)
	if marca != "" and Juego.tiene_marca(marca):
		_al_resolver()


func interactuar(_guardian: Node) -> void:
	if not esta_resuelta:
		puzzle.abrir()


func _al_resolver() -> void:
	if esta_resuelta:
		return
	esta_resuelta = true
	if marca != "":
		Juego.marcar(marca)
	_aviso.visible = false
	resuelta.emit()


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not esta_resuelta:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

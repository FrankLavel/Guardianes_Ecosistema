class_name TierraFertil
extends Area2D
## Montículo de tierra fértil: al interactuar se planta una semilla y crece una enredadera.

signal plantada

@export var altura_enredadera := 192.0

var esta_plantada := false

@onready var _aviso: Label = $Aviso
@onready var enredadera: Enredadera = $Enredadera


func _ready() -> void:
	_aviso.visible = false
	enredadera.altura = altura_enredadera
	enredadera.visible = false
	enredadera.monitoring = false
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func interactuar(guardian: Node) -> void:
	if esta_plantada:
		return
	esta_plantada = true
	_aviso.visible = false
	if guardian.has_method("quitar_interactuable"):
		guardian.quitar_interactuable(self)
	Sonido.efecto("recoger")
	enredadera.visible = true
	enredadera.set_deferred("monitoring", true)
	plantada.emit()
	await enredadera.crecer()
	Sonido.efecto("correcto")


func _al_entrar(cuerpo: Node2D) -> void:
	if cuerpo is Guardian and not esta_plantada:
		cuerpo.registrar_interactuable(self)
		_aviso.visible = true


func _al_salir(cuerpo: Node2D) -> void:
	if cuerpo is Guardian:
		cuerpo.quitar_interactuable(self)
		_aviso.visible = false

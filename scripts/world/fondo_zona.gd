class_name FondoZona
extends CanvasLayer
## Fondo de una zona: varias CapaFondo que siguen a la cámara a distinta velocidad.

var limpieza := 0.0:
	set(valor):
		limpieza = valor
		for capa in capas():
			capa.limpieza = valor


func _ready() -> void:
	limpieza = limpieza


func capas() -> Array[CapaFondo]:
	var lista: Array[CapaFondo] = []
	for nodo in get_children():
		if nodo is CapaFondo:
			lista.append(nodo)
	return lista


## Cambia la limpieza poco a poco (al recoger basura se ve cómo se aclara el paisaje).
func animar_limpieza(objetivo: float, segundos := 1.2) -> void:
	create_tween().tween_property(self, "limpieza", objetivo, segundos)


func _process(_delta: float) -> void:
	var camara := get_viewport().get_camera_2d()
	if camara == null:
		return
	var x := camara.get_screen_center_position().x
	for capa in capas():
		capa.desplazar(x)

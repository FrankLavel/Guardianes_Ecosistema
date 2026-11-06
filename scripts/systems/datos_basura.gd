class_name DatosBasura
extends RefCounted
## Nombres y datos educativos de cada tipo de basura (editable en data/basura.json).

const RUTA := "res://data/basura.json"

static var _cache: Dictionary = {}


static func todos() -> Dictionary:
	if _cache.is_empty():
		var texto := FileAccess.get_file_as_string(RUTA)
		var datos = JSON.parse_string(texto)
		if datos is Dictionary:
			_cache = datos
		else:
			push_error("No se pudo leer %s" % RUTA)
	return _cache


static func obtener(tipo: String) -> Dictionary:
	return todos().get(tipo, {"nombre": tipo, "dato": ""})

"""Convierte el arte de assets/fuente_ia en PNG listos para Godot.

Ejecutar desde la raíz del proyecto:
    python tools/arte/procesar.py            # todo
    python tools/arte/procesar.py valle ui   # solo algunos grupos

Si se regenera una imagen con IA, basta con reemplazarla en assets/fuente_ia (mismo nombre)
y volver a ejecutar este script. Los nombres de cada objeto dependen del orden en que aparecen
(de arriba a abajo y de izquierda a derecha); si cambia el orden, revisar las listas de abajo.
"""
from __future__ import annotations

import sys

import numpy as np
from PIL import Image, ImageFilter

import arte
from arte import RAIZ, cargar, construir_atlas, guardar, hacer_repetible, hacer_repetible_h, quitar_fondo, recortar, separar_objetos

ASSETS = RAIZ / "assets"


def objetos(fuente: str, nombres: list[str | None], destino: str, area_min: int = 400) -> dict[str, Image.Image]:
    rgba = quitar_fondo(cargar(fuente))
    encontrados = separar_objetos(rgba, area_min=area_min)
    if len(encontrados) != len(nombres):
        raise SystemExit(f"{fuente}: se esperaban {len(nombres)} objetos y se encontraron {len(encontrados)}")
    piezas = {}
    for nombre, obj in zip(nombres, encontrados):
        if nombre is None:
            continue
        pieza = recortar(rgba, obj)
        guardar(pieza, ASSETS / destino / f"{nombre}.png")
        piezas[nombre] = pieza
    return piezas


def rellenar_magenta(img: np.ndarray) -> np.ndarray:
    """Tapa las líneas magenta de la cuadrícula copiando los pixeles vecinos."""
    img = img.astype(np.float32).copy()
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    hueco = (r - g > 60) & (b - g > 60)
    # Las líneas de la cuadrícula se mezclan con el pasto (morado oscuro): se detectan como
    # columnas/filas donde casi todo el trazo tiene tinte magenta, y se tapan completas (±2 px).
    tinte = (r - g > 15) & (b - g > 15)
    for eje in (0, 1):
        fraccion = tinte.mean(axis=eje)
        for i in np.nonzero(fraccion > 0.35)[0]:
            if eje == 0:
                hueco[:, max(i - 2, 0) : i + 3] = True
            else:
                hueco[max(i - 2, 0) : i + 3, :] = True
    for _ in range(40):
        if not hueco.any():
            break
        suma = np.zeros_like(img)
        cuenta = np.zeros(hueco.shape, np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            vecino = np.roll(img, (dy, dx), axis=(0, 1))
            valido = ~np.roll(hueco, (dy, dx), axis=(0, 1))
            suma += vecino * valido[..., None]
            cuenta += valido
        llenar = hueco & (cuenta > 0)
        img[llenar] = suma[llenar] / cuenta[llenar][:, None]
        hueco &= ~llenar
    return img.astype(np.uint8)


# ---------------------------------------------------------------- Guardianes en el valle
def personaje_aereo(fuente: str, carpeta: str, nombre: str, idle: dict[str, int], caminar: dict[str, list[int]], fps_arriba: float) -> None:
    """Atlas de un personaje del mapa aéreo + retrato (cabeza) para los diálogos.

    `idle`/`caminar` usan los índices de los cuadros tal como los numera separar_objetos.
    La dirección "derecha" no se exporta: el juego voltea "izquierda".
    """
    rgba = quitar_fondo(cargar(fuente))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    orden: list[int] = []
    for i in list(idle.values()) + [i for lista in caminar.values() for i in lista]:
        if i not in orden:
            orden.append(i)
    pos = {orig: n for n, orig in enumerate(orden)}
    anims = {f"idle_{d}": ([pos[i]], 1.0, True) for d, i in idle.items()}
    for d, lista in caminar.items():
        anims[f"caminar_{d}"] = ([pos[i] for i in lista], fps_arriba if d == "arriba" else 8.0, True)
    base = ASSETS / "characters" / carpeta / "aerea"
    construir_atlas(
        [cuadros[i] for i in orden], anims, (128, 208),
        base / f"{nombre}_aerea_atlas.png", base / f"{nombre}_aerea_frames.tres",
        f"res://assets/characters/{carpeta}/aerea/{nombre}_aerea_atlas.png",
    )
    # Retrato: la cabeza del cuadro de frente, en un cuadrado.
    frente = cuadros[idle["abajo"]]
    lado = int(frente.width * 1.05)
    cabeza = frente.crop(((frente.width - lado) // 2, 0, (frente.width + lado) // 2, lado))
    guardar(cabeza.resize((256, 256), Image.Resampling.LANCZOS), ASSETS / "characters" / carpeta / f"{nombre}_retrato.png")


def nina_plataformas() -> None:
    """Hoja lateral de la niña para los niveles de plataformas (mismo formato que la de Gara)."""
    def cuadros_de(fuente: str, de_pie: int = 0) -> list[Image.Image]:
        rgba = quitar_fondo(cargar(fuente))
        cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
        # Cada hoja viene a otra escala: se lleva a la estatura del niño (~156 px de pie).
        # `de_pie`: índice de un cuadro donde está parada derecha, para medirla.
        factor = 156 / cuadros[de_pie].height
        return [c.resize((round(c.width * factor), round(c.height * factor)), Image.Resampling.LANCZOS) for c in cuadros]

    # Hoja base (de ella solo se usa "quieta") + hojas corregidas, porque en la base varias poses
    # salieron con la ropa del niño. Índices: 23-29 caminar, 30-36 correr (nina_plataformas_correr),
    # 37-49 poses (nina_plataformas_poses: saltar, saltar, caer, de pie, agachar, recoger, ...).
    cuadros = (cuadros_de("nina_plataformas.jpg") + cuadros_de("nina_plataformas_correr.jpg")
        + cuadros_de("nina_plataformas_poses.jpg", de_pie=3))
    animaciones = {
            "idle": ([0, 1], 2.0, True),
            "caminar": ([23, 24, 25, 26, 27, 28, 29], 10.0, True),
            "correr": ([30, 31, 32, 33, 34, 35, 36], 12.0, True),
            "saltar": ([37], 1.0, False),
            "caer": ([39], 1.0, False),
            "agachar": ([41], 1.0, False),
            "interactuar": ([42], 1.0, False),
    }
    # Solo los cuadros que se usan (las filas viejas de caminar/correr quedan fuera del atlas).
    usados = sorted({i for indices, _, _ in animaciones.values() for i in indices})
    nuevo = {orig: n for n, orig in enumerate(usados)}
    animaciones = {k: ([nuevo[i] for i in v[0]], v[1], v[2]) for k, v in animaciones.items()}
    construir_atlas(
        [cuadros[i] for i in usados],
        animaciones,
        # Celdas más anchas que las de Gara: el cuadro de caída es ancho y, centrado por el torso,
        # tocaría el borde con 160 px.
        (200, 176),
        ASSETS / "characters/nina/nina_atlas.png",
        ASSETS / "characters/nina/nina_frames.tres",
        "res://assets/characters/nina/nina_atlas.png",
        anclar_torso=True,
    )


def guardianes() -> None:
    personaje_aereo(
        "gara_aerea.jpg", "gara", "gara",
        idle={"abajo": 0, "arriba": 11, "izquierda": 4},
        caminar={"abajo": [0, 1, 2, 3], "izquierda": [4, 5, 6, 12], "arriba": [16, 17, 18, 19, 20, 21, 22, 23]},
        fps_arriba=12.0,
    )
    personaje_aereo(
        "npc_aldeana_aerea.jpg", "nina", "nina",
        idle={"abajo": 11, "arriba": 15, "izquierda": 0},
        caminar={"abajo": [1, 3, 5, 7], "izquierda": [8, 12, 16, 20], "arriba": [27, 28, 29, 31]},
        fps_arriba=8.0,
    )
    nina_plataformas()


# ---------------------------------------------------------------- Valle (mapa aéreo)
def valle() -> None:
    objetos("valle_objetos.jpg", [
        "oyamel", "sabino", "arbusto_flores", "casa_adobe", "muelle", "roca_grande",
        "letrero", "encino", "cerca", "piedras", "tuberia", "tocon",
    ], "maps/valle/objetos")
    objetos("valle_entradas.jpg", ["entrada_rio", "entrada_bosque", "entrada_lago"], "maps/valle/entradas")

    tiles = rellenar_magenta(cargar("valle_tileset.jpg"))
    destino = ASSETS / "maps/valle/texturas"
    pasto = Image.fromarray(tiles[103:189, 6:95]).convert("RGBA")
    guardar(hacer_repetible(pasto, 20), destino / "pasto.png")
    # Camino de tierra (tramo vertical) girado para que el largo quede en horizontal (Line2D).
    # Solo la tierra y un borde delgado: el pasto del tileset es más claro que el del suelo.
    camino = Image.fromarray(tiles[390:476, 431:487]).convert("RGBA").transpose(Image.Transpose.ROTATE_90)
    # El pasto de las orillas se vuelve transparente (suave) para que el camino se funda con el suelo.
    px = np.asarray(hacer_repetible_h(camino, 14)).copy()
    r, g = px[..., 0].astype(np.float32), px[..., 1].astype(np.float32)
    alfa = np.clip((r - g + 6.0) / 26.0, 0.0, 1.0) * 255
    alfa = np.asarray(Image.fromarray(alfa.astype(np.uint8)).filter(ImageFilter.GaussianBlur(2)))
    px[..., 3] = alfa
    guardar(Image.fromarray(px), destino / "camino.png")
    rio = Image.fromarray(tiles[100:282, 818:1000]).convert("RGBA").transpose(Image.Transpose.ROTATE_90)
    guardar(hacer_repetible_h(rio, 30), destino / "rio.png")
    puente = Image.fromarray(tiles[296:392, 772:1028]).convert("RGBA")
    guardar(puente, ASSETS / "maps/valle/objetos/puente.png")


# ---------------------------------------------------------------- Zona 1 (plataformas)
def zona1() -> None:
    piezas = objetos("zona1_plataformas.jpg", [
        "suelo_bloque", "isla_grande", "isla_chica", "rampa", "tronco",
        "pilar", "troncos_doble", "orilla_izquierda", "orilla_derecha",
    ], "maps/zona1/plataformas")
    # Tira de suelo para NinePatchRect: bordes a los lados y centro repetible.
    suelo = piezas["suelo_bloque"]
    tapa = 70
    izq = suelo.crop((0, 0, tapa, suelo.height))
    der = suelo.crop((suelo.width - tapa, 0, suelo.width, suelo.height))
    centro = hacer_repetible_h(suelo.crop((tapa, 0, suelo.width - tapa, suelo.height)), 40)
    tira = Image.new("RGBA", (tapa * 2 + centro.width, suelo.height))
    tira.alpha_composite(izq, (0, 0))
    tira.alpha_composite(centro, (tapa, 0))
    tira.alpha_composite(der, (tapa + centro.width, 0))
    guardar(tira, ASSETS / "maps/zona1/plataformas/suelo_tira.png")

    objetos("zona1_objetos.jpg", [
        "botella", None, "bolsa", "pila", "unicel", "arbol_meta", "tuberia_sucia",
        None, "tronco_empujable", "brote_control", "lancha", "charco_toxico",
    ], "objects/zona1")
    # El brillo del brote salió rosa (mezclado con el fondo); se quita y el brillo lo pone el juego.
    brote = Image.open(ASSETS / "objects/zona1/brote_control.png")
    px = np.asarray(brote.convert("RGBA")).copy()
    r, g, b = (px[..., i].astype(np.int16) for i in range(3))
    # Brillo pintado (rosa/durazno claro): rojo dominante y muy claro. Hojas y pasto son verdes.
    brillo = (r >= g) & (r > 175) & (b > 95)
    px[..., 3] = np.where(brillo, 0, px[..., 3])
    brote = Image.fromarray(arte.quitar_tinte_magenta(px, rojo=30, azul=-10))
    guardar(brote.crop(brote.getbbox()), ASSETS / "objects/zona1/brote_control.png")
    lata = objetos("zona1_lata.jpg", ["lata"], "objects/zona1")["lata"]
    # La IA la dibujó enorme; se reduce al tamaño de los demás objetos.
    guardar(lata.resize((200, round(200 * lata.height / lata.width)), Image.Resampling.LANCZOS), ASSETS / "objects/zona1/lata.png")
    objetos("zona1_valvula.jpg", ["valvula_abierta", "valvula_cerrada"], "objects/zona1")
    # La basura se carga por tipo desde assets/objects/basura/<tipo>.png
    for tipo in ["botella", "lata", "bolsa", "pila", "unicel"]:
        img = Image.open(ASSETS / "objects/zona1" / f"{tipo}.png")
        guardar(img, ASSETS / "objects/basura" / f"{tipo}.png")

    rgba = quitar_fondo(cargar("zona1_animales.jpg"))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    construir_atlas(
        cuadros,
        {"acocil": ([0, 1, 2, 3], 6.0, True), "garza": ([4, 5, 6, 7], 5.0, True),
         "martin_pescador": ([8, 9, 10, 11], 10.0, True), "pez": ([12, 13, 14, 15], 8.0, True)},
        (352, 224),
        ASSETS / "characters/animales/zona1_animales_atlas.png",
        ASSETS / "characters/animales/zona1_animales_frames.tres",
        "res://assets/characters/animales/zona1_animales_atlas.png",
        por_fila=4,
    )

    destino = ASSETS / "maps/zona1/fondos"
    for capa in ["montanas", "arboles"]:
        for sufijo in ["", "_contaminado"]:
            rgba = arte.quitar_cielo_magenta(cargar(f"zona1_fondo_{capa}{sufijo}.jpg"))
            # Hay restos del magenta del fondo mezclados con el dibujo (árboles "fantasma",
            # manchas rosas en las cimas).
            rgba = arte.quitar_tinte_magenta(rgba, rojo=12, azul=12)
            img = Image.fromarray(rgba)
            img = img.crop(img.getbbox())
            img = hacer_repetible_h(img, 120)
            # Segunda pasada: la mezcla de los bordes puede revivir restos morados.
            img = Image.fromarray(arte.quitar_tinte_magenta(np.asarray(img), rojo=8, azul=8))
            guardar(img, destino / f"{capa}{sufijo}.png")
    for sufijo, caja in [("", (82, 154, 1182, 709)), ("_contaminado", None)]:
        img = Image.fromarray(cargar(f"zona1_fondo_cielo{sufijo}.jpg").astype(np.uint8))
        if caja is None:
            rgba = quitar_fondo(cargar(f"zona1_fondo_cielo{sufijo}.jpg"))
            x0, y0, x1, y1 = separar_objetos(rgba)[0]["caja"]
            caja = (x0 + 8, y0 + 8, x1 - 8, y1 - 8)
        guardar(hacer_repetible_h(img.crop(caja).convert("RGBA"), 120), destino / f"cielo{sufijo}.png")


# ---------------------------------------------------------------- Puzzle del filtro
def puzzle_filtro() -> None:
    destino = "ui/puzzle_filtro"
    piezas = {}
    for fuente, nombre in [("puzzle_filtro_vacio.jpg", "botella"), ("puzzle_filtro_grava.jpg", "carta_grava"),
                           ("puzzle_filtro_arena.jpg", "carta_arena"), ("puzzle_filtro_carbon.jpg", "carta_carbon")]:
        piezas.update(objetos(fuente, [nombre], destino))
    piezas.update(objetos("puzzle_filtro_extras.jpg", ["carta_algodon", "gota_sucia", "gota_limpia"], destino))
    # Texturas de cada material para pintar las capas dentro del filtro. Se dibujan a baja
    # resolución y se amplían sin suavizar, para que sean pixel art como el resto.
    for material in ["grava", "arena", "carbon", "algodon"]:
        guardar(textura_material(material), ASSETS / destino / f"textura_{material}.png")


def textura_material(material: str, lado: int = 48, zoom: int = 4) -> Image.Image:
    from PIL import ImageDraw
    rng = np.random.default_rng({"grava": 1, "arena": 2, "carbon": 3, "algodon": 4}[material])
    paletas = {
        "grava": ((92, 72, 52), [(150, 140, 125), (120, 110, 98), (170, 150, 120), (105, 95, 90)], (55, 45, 38)),
        "arena": ((214, 170, 98), [(232, 192, 120), (196, 150, 80), (240, 210, 150)], None),
        "carbon": ((22, 22, 24), [(48, 48, 52), (62, 62, 68), (36, 36, 40)], (10, 10, 12)),
        "algodon": ((226, 232, 238), [(250, 252, 255), (205, 214, 224)], (180, 190, 204)),
    }
    fondo, colores, contorno = paletas[material]
    img = Image.new("RGB", (lado, lado), fondo)
    d = ImageDraw.Draw(img)
    if material == "arena":
        for _ in range(lado * lado // 3):
            x, y = rng.integers(0, lado, 2)
            img.putpixel((int(x), int(y)), tuple(int(c) for c in colores[rng.integers(0, len(colores))]))
    else:
        cantidad, tam = {"grava": (34, (3, 7)), "carbon": (40, (2, 6)), "algodon": (26, (4, 9))}[material]
        for _ in range(cantidad):
            cx, cy = rng.integers(0, lado, 2)
            rx, ry = rng.integers(tam[0], tam[1], 2)
            color = tuple(int(c) for c in colores[rng.integers(0, len(colores))])
            # Se dibuja también desplazado un "lado" para que la textura se repita sin cortes.
            for ox in (-lado, 0, lado):
                for oy in (-lado, 0, lado):
                    caja = [cx - rx + ox, cy - ry + oy, cx + rx + ox, cy + ry + oy]
                    d.ellipse(caja, fill=color, outline=contorno)
    return img.resize((lado * zoom, lado * zoom), Image.Resampling.NEAREST).convert("RGBA")


# ---------------------------------------------------------------- Personajes
def personajes() -> None:
    rgba = quitar_fondo(cargar("don_chucho_hablando.jpg"))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    construir_atlas(
        cuadros,
        {"idle": ([0, 1], 2.0, True), "hablar": ([2, 3], 6.0, True)},
        (272, 960),
        ASSETS / "characters/don_chucho/don_chucho_atlas.png",
        ASSETS / "characters/don_chucho/don_chucho_frames.tres",
        "res://assets/characters/don_chucho/don_chucho_atlas.png",
        por_fila=4,
    )
    objetos("don_chucho_retrato.jpg", ["don_chucho_retrato"], "characters/don_chucho")


# ---------------------------------------------------------------- Interfaz
def ui() -> None:
    objetos("ui_panel.jpg", ["panel"], "ui")
    objetos("ui_panel_bitacora.jpg", ["panel_bitacora"], "ui")
    objetos("ui_botones.jpg", ["boton_normal", "boton_hover", "boton_presionado"], "ui")
    objetos("ui_iconos.jpg", [
        "icono_corazon", "icono_hoja", "icono_gota", "icono_basura",
        None, "icono_bitacora", "icono_pausa_izq", "icono_pausa_der", "icono_cerrar",
    ], "ui/iconos", area_min=200)
    # Versiones a tamaño de pantalla (1920x1080) para usarlas como estilos de la interfaz.
    for nombre, factor in [("panel", 0.42), ("panel_bitacora", 0.6), ("boton_normal", 0.5), ("boton_hover", 0.5), ("boton_presionado", 0.5)]:
        img = Image.open(ASSETS / "ui" / f"{nombre}.png")
        tam = (round(img.width * factor), round(img.height * factor))
        guardar(img.resize(tam, Image.Resampling.LANCZOS), ASSETS / "ui" / "escalado" / f"{nombre}.png")
    for icono in (ASSETS / "ui/iconos").glob("*.png"):
        img = Image.open(icono)
        f = 72 / max(img.size)
        guardar(img.resize((round(img.width * f), round(img.height * f)), Image.Resampling.LANCZOS), ASSETS / "ui/iconos/escalado" / icono.name)
    rgba = quitar_fondo(cargar("logo.jpg"))
    # Sin unir piezas cercanas: así las Garas pequeñas de abajo quedan separadas del logo.
    logo = max(separar_objetos(rgba, area_min=200, union=0), key=lambda o: o["mascara"].sum())
    guardar(recortar(rgba, logo), ASSETS / "ui" / "logo.png")


GRUPOS = {"guardianes": guardianes, "valle": valle, "zona1": zona1, "personajes": personajes, "ui": ui, "filtro": puzzle_filtro}

if __name__ == "__main__":
    for nombre in sys.argv[1:] or GRUPOS:
        print("Procesando", nombre, "...")
        GRUPOS[nombre]()
    print("Listo.")

"""Convierte el arte de assets/fuente_ia en PNG listos para Godot.

Ejecutar desde la raíz del proyecto:
    python tools/arte/procesar.py            # todo
    python tools/arte/procesar.py valle ui   # solo algunos grupos

Si se regenera una imagen con IA, basta con reemplazarla en assets/fuente_ia (mismo nombre)
y volver a ejecutar este script. Los nombres de cada objeto dependen del orden en que aparecen
(de arriba a abajo y de izquierda a derecha); si cambia el orden, revisar las listas de abajo.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

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


def a_alto(img: Image.Image, alto: int) -> Image.Image:
    """Mismo alto que el arte anterior: las escenas usan offsets y escalas calculados con ese alto."""
    return img.resize((round(img.width * alto / img.height), alto), Image.Resampling.LANCZOS)


def unir(a: dict, b: dict) -> dict:
    """Une dos objetos de separar_objetos en uno (p. ej. el humo suelto de la fogata apagada)."""
    caja = (min(a["caja"][0], b["caja"][0]), min(a["caja"][1], b["caja"][1]),
            max(a["caja"][2], b["caja"][2]), max(a["caja"][3], b["caja"][3]))
    mascara = np.zeros((caja[3] - caja[1], caja[2] - caja[0]), bool)
    for o in (a, b):
        x0, y0, x1, y1 = o["caja"]
        mascara[y0 - caja[1]:y1 - caja[1], x0 - caja[0]:x1 - caja[0]] |= o["mascara"]
    return {"caja": caja, "mascara": mascara}


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


def agregar_animacion(tres: Path, nombre: str, cuadros: list[Image.Image], fps: float, celda: tuple[int, int]) -> None:
    """Agrega (o reemplaza) una animación a un SpriteFrames existente, con su propio atlas."""
    png = tres.with_name(tres.stem.replace("_frames", "") + f"_{nombre}.png")
    ruta_res = "res://" + png.relative_to(RAIZ).as_posix()
    cw, ch = celda
    atlas = Image.new("RGBA", (cw * len(cuadros), ch), (0, 0, 0, 0))
    for i, c in enumerate(cuadros):
        atlas.alpha_composite(c, (i * cw + (cw - c.width) // 2, ch - c.height))
    guardar(atlas, png)
    texto = tres.read_text(encoding="utf-8")
    # Quitar una versión anterior de esta animación.
    texto = re.sub(r'\n\[ext_resource [^\n]*id="%s_atlas"\]' % nombre, "", texto)
    texto = re.sub(r'\[sub_resource type="AtlasTexture" id="%s_\d+"\]\n[^\[]*' % nombre, "", texto)
    texto = re.sub(r', \{\n"frames": \[[^\]]*\],\n"loop": \w+,\n"name": &"%s",\n"speed": [\d.]+\n\}' % nombre, "", texto)
    ext = f'[ext_resource type="Texture2D" path="{ruta_res}" id="{nombre}_atlas"]'
    i = texto.index("\n\n", texto.rindex("[ext_resource"))
    texto = texto[:i] + "\n" + ext + texto[i:]
    subs = "".join(
        f'[sub_resource type="AtlasTexture" id="{nombre}_{k}"]\natlas = ExtResource("{nombre}_atlas")\n'
        f"region = Rect2({k * cw}, 0, {cw}, {ch})\n\n"
        for k in range(len(cuadros))
    )
    texto = texto.replace("[resource]", subs + "[resource]", 1)
    frames = ", ".join(f'{{\n"duration": 1.0,\n"texture": SubResource("{nombre}_{k}")\n}}' for k in range(len(cuadros)))
    anim = f', {{\n"frames": [{frames}],\n"loop": true,\n"name": &"{nombre}",\n"speed": {fps}\n}}'
    k = texto.rstrip().rindex("]")
    texto = texto[:k] + anim + texto[k:]
    tres.write_text(texto, encoding="utf-8", newline="\n")


def nadar() -> None:
    """Animación de nado (si ya se generó el arte): gara_nadar.* y nina_nadar.* en fuente_ia."""
    for carpeta, celda in [("gara", (160, 176)), ("nina", (200, 176))]:
        fuente = next((f.name for f in arte.FUENTE.glob(f"{carpeta}_nadar.*")), None)
        if fuente is None:
            print(f"  (sin arte de nado para {carpeta})")
            continue
        img = cargar(fuente)
        if carpeta == "nina":
            # La hoja de la niña trae abajo otra cuadrícula (caminando en el valle): solo la mitad de arriba.
            img = img[:375]
        rgba = quitar_fondo(img)
        # Los 6 objetos más grandes son los cuadros (las burbujas sueltas se descartan).
        objs = sorted(separar_objetos(rgba, union=14), key=lambda o: -o["mascara"].sum())[:6]
        cuadros = [recortar(rgba, o) for o in sorted(objs, key=lambda o: (o["caja"][1] // 150, o["caja"][0]))]
        factor = min(150 / max(c.width for c in cuadros), 120 / max(c.height for c in cuadros))
        cuadros = [c.resize((round(c.width * factor), round(c.height * factor)), Image.Resampling.LANCZOS) for c in cuadros]
        agregar_animacion(ASSETS / f"characters/{carpeta}/{carpeta}_frames.tres", "nadar", cuadros, 8.0, celda)


def trepar() -> None:
    for fuente, carpeta, usar, celda in [("gara_trepar.jpg", "gara", None, (160, 176)), ("nina_trepar.jpg", "nina", 7, (200, 176))]:
        rgba = quitar_fondo(cargar(fuente))
        objs = separar_objetos(rgba)
        if usar:
            objs = sorted(objs, key=lambda o: (o["caja"][1] // 200, o["caja"][0]))[:usar]
        cuadros = [recortar(rgba, o) for o in objs]
        # Misma estatura que en el resto de sus animaciones (~165 px con los brazos arriba).
        factor = 165 / max(c.height for c in cuadros)
        cuadros = [c.resize((round(c.width * factor), round(c.height * factor)), Image.Resampling.LANCZOS) for c in cuadros]
        agregar_animacion(ASSETS / f"characters/{carpeta}/{carpeta}_frames.tres", "trepar", cuadros, 8.0, celda)


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
    # Retratos de los diálogos: niño a la izquierda, niña a la derecha; en un cuadrado, pegados abajo.
    rgba = quitar_fondo(cargar("retratos.jpg"))
    for carpeta, obj in zip(["gara", "nina"], separar_objetos(rgba)):
        busto = recortar(rgba, obj)
        lado = max(busto.size)
        cuadro = Image.new("RGBA", (lado, lado))
        cuadro.alpha_composite(busto, ((lado - busto.width) // 2, lado - busto.height))
        guardar(cuadro.resize((512, 512), Image.Resampling.LANCZOS), ASSETS / "characters" / carpeta / f"{carpeta}_retrato.png")
    nina_plataformas()
    trepar()
    nadar()


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
    # Agua sola (la parte honda del río, sin orillas) para el estanque de Achi.
    agua = Image.open(destino / "rio.png").convert("RGBA").crop((0, 66, 152, 114))
    guardar(hacer_repetible(agua, 10), destino / "agua.png")
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
        None, None, None, None, None, "arbol_meta", None,
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
    # En el juego la basura se escala por su lado más largo (basura.gd), así que el tamaño aquí no importa.
    objetos("zona1_basura.jpg", ["bolsa", "botella", "lata", "unicel", "pila"], "objects/zona1")
    # Los objetos 1, 2, 4 y 5 son los letreros "OPEN"/"CLOSED" que dibujó la IA.
    valvulas = objetos("zona1_valvulas.jpg", ["valvula_abierta", None, None, "valvula_cerrada", None, None, "tuberia_sucia"], "objects/zona1")
    for nombre, alto in {"valvula_abierta": 613, "valvula_cerrada": 532, "tuberia_sucia": 462}.items():
        guardar(a_alto(valvulas[nombre], alto), ASSETS / "objects/zona1" / f"{nombre}.png")
    # La basura se carga por tipo desde assets/objects/basura/<tipo>.png
    for tipo in ["botella", "lata", "bolsa", "pila", "unicel"]:
        img = Image.open(ASSETS / "objects/zona1" / f"{tipo}.png")
        guardar(img, ASSETS / "objects/basura" / f"{tipo}.png")

    rgba = quitar_fondo(cargar("zona1_animales.jpg"))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    # El martín pescador viene de su propia hoja (4 cuadros de izquierda a derecha), del alto de la celda.
    rgba = quitar_fondo(cargar("zona1_martin.jpg"))
    martin = [recortar(rgba, o) for o in sorted(separar_objetos(rgba), key=lambda o: o["caja"][0])]
    factor = 215 / max(c.height for c in martin)
    cuadros[8:12] = [c.resize((round(c.width * factor), round(c.height * factor)), Image.Resampling.LANCZOS) for c in martin]
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
    piezas.update(objetos("puzzle_filtro_extras.jpg", ["carta_algodon", None, None], destino))
    for nombre, gota in objetos("puzzle_gotas.jpg", ["gota_sucia", "gota_limpia"], destino).items():
        guardar(a_alto(gota, 521), ASSETS / destino / f"{nombre}.png")
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


# ---------------------------------------------------------------- Zona 3 (lago)
def zona3() -> None:
    z3 = "objects/zona3"
    objetos("zona3_objetos.jpg", ["lirio", "huevo", "lirio_2", "tule", "muelle", "canoa"], z3)
    (ASSETS / z3 / "lirio_2.png").unlink()

    # Achi: 12 cuadros (los 3 primeros quieto, los demás nadando).
    rgba = quitar_fondo(cargar("zona3_achoque.jpg"))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    construir_atlas(
        cuadros,
        {"idle": ([0, 1, 2, 1], 4.0, True), "hablar": ([0, 1, 2, 1], 7.0, True), "nadar": (list(range(3, 12)), 10.0, True)},
        (352, 224),
        ASSETS / "characters/achi/achi_atlas.png",
        ASSETS / "characters/achi/achi_frames.tres",
        "res://assets/characters/achi/achi_atlas.png",
        por_fila=4,
    )
    guardar(cuadros[0], ASSETS / z3 / "achoque.png")
    retrato = objetos("achi_retrato.jpg", ["achi_retrato"], "characters/achi")["achi_retrato"]
    guardar(retrato.resize((512, round(512 * retrato.height / retrato.width)), Image.Resampling.LANCZOS),
            ASSETS / "characters/achi/achi_retrato.png")

    # Pato mexicano (2) y pescado blanco (2).
    rgba = quitar_fondo(cargar("zona3_animales.jpg"))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    construir_atlas(
        cuadros,
        {"pato": ([0, 1], 3.0, True), "pescado_blanco": ([2, 3], 6.0, True)},
        (496, 320),
        ASSETS / "characters/animales/zona3_animales_atlas.png",
        ASSETS / "characters/animales/zona3_animales_frames.tres",
        "res://assets/characters/animales/zona3_animales_atlas.png",
        por_fila=2,
    )
    guardar(cuadros[0], ASSETS / "characters/animales/pato_mexicano.png")
    guardar(cuadros[2], ASSETS / "characters/animales/pescado_blanco.png")

    objetos("zona3_cadena.jpg", ["sol", "plantas", "insecto"], z3)
    piezas = objetos("zona3_residuos.jpg", [
        "cascara", "papel", "frasco", "contenedor_organico",
        "contenedor_plastico", "contenedor_papel", "contenedor_vidrio_metal", "contenedor_peligrosos",
    ], z3)
    px = np.asarray(piezas["frasco"]).copy()
    r, g, b = (px[..., i].astype(np.int16) for i in range(3))
    rosa = (r - g > 30) & (b - g > 20)
    px[rosa, 0] = (px[rosa, 0] * 0.55).astype(np.uint8)
    px[rosa, 1] = np.clip(g[rosa] * 1.15 + 20, 0, 255).astype(np.uint8)
    px[rosa, 3] = 150
    guardar(Image.fromarray(px), ASSETS / z3 / "frasco.png")

    # Fondo: el lago con Janitzio (sano y contaminado), mismo tamaño para poder mezclarlos.
    destino = ASSETS / "maps/zona3/fondos"
    for nombre, fuente in [("lago", "zona3_fondo_lago.jpg"), ("lago_contaminado", "zona3_fondo_lago_contaminado.jpg")]:
        img = Image.fromarray(cargar(fuente).astype(np.uint8)).convert("RGBA")
        guardar(hacer_repetible_h(img, 220), destino / f"{nombre}.png")


# ---------------------------------------------------------------- Zona 2 y bitácora
def zona2() -> None:
    # Las antenas quedan separadas del cuerpo: se unen piezas hasta 40 px de distancia.
    rgba = quitar_fondo(cargar("zona2_mariposa_monarca.jpg"))
    mariposa = max(separar_objetos(rgba, union=40), key=lambda o: o["mascara"].sum())
    guardar(recortar(rgba, mariposa), ASSETS / "characters/animales/monarca.png")
    destino = ASSETS / "maps/zona2/fondos"
    rgba = arte.quitar_cielo_magenta(cargar("zona2_fondo_talado.jpg"))
    rgba = arte.quitar_tinte_magenta(rgba, rojo=12, azul=12)
    img = Image.fromarray(rgba)
    img = img.crop(img.getbbox())
    img = hacer_repetible_h(img, 160)
    img = Image.fromarray(arte.quitar_tinte_magenta(np.asarray(img), rojo=8, azul=8))
    guardar(img, destino / "bosque_talado.png")

    # De la hoja vieja solo queda la enredadera; lo demás viene de zona2_objetos_pixel.
    piezas = objetos("zona2_objetos.png", ["enredadera_original", None, None, None, None, None], "objects/zona2")
    # Orden: humo suelto, alambre, fogata apagada, fogata, letrero, tierra. El humo va con la fogata apagada.
    rgba = quitar_fondo(cargar("zona2_objetos_pixel.jpg"))
    o = separar_objetos(rgba)
    nuevos = {"fogata": o[3], "fogata_apagada": unir(o[2], o[0]), "letrero_vivero": o[4], "tierra_fertil": o[5], "alambre": o[1]}
    altos = {"fogata": 353, "letrero_vivero": 319, "tierra_fertil": 212, "alambre": 222}
    # La apagada (con su humo, más alta) usa la escala de la encendida para que la leña mida igual.
    escala = 353 / recortar(rgba, nuevos["fogata"]).height
    for nombre, obj in nuevos.items():
        pieza = recortar(rgba, obj)
        guardar(a_alto(pieza, altos.get(nombre, round(pieza.height * escala))), ASSETS / "objects/zona2" / f"{nombre}.png")
    # La enredadera se repite hacia arriba: se hace repetible en vertical.
    vertical = piezas["enredadera_original"].transpose(Image.Transpose.TRANSPOSE)
    guardar(hacer_repetible_h(vertical, 60).transpose(Image.Transpose.TRANSPOSE), ASSETS / "objects/zona2/enredadera.png")
    (ASSETS / "objects/zona2/enredadera_original.png").unlink()

    # Venado: 0 de pie, 3 comiendo, 1, 2, 4, 5 y 6 corriendo. De pie mide lo mismo que el anterior (328 px).
    rgba = quitar_fondo(cargar("zona2_venado.jpg"))
    cuadros = [recortar(rgba, o) for o in separar_objetos(rgba)]
    factor = 328 / cuadros[0].height
    cuadros = [c.resize((round(c.width * factor), round(c.height * factor)), Image.Resampling.LANCZOS) for c in cuadros]
    construir_atlas(
        cuadros,
        {"idle": ([0], 1.0, True), "comer": ([3, 0], 1.2, True), "correr": ([1, 2, 4, 5, 6], 10.0, True)},
        (500, 360),
        ASSETS / "characters/animales/venado_atlas.png",
        ASSETS / "characters/animales/venado_frames.tres",
        "res://assets/characters/animales/venado_atlas.png",
        por_fila=3,
    )
    guardar(cuadros[0], ASSETS / "objects/zona2/venado.png")

    # La hoja trae venados de relleno; el tronco con el carpintero está arriba al centro y en la
    # fila de abajo toca a un venado, así que se borra esa fila antes de separar.
    rgba = quitar_fondo(cargar("zona2_carpintero.jpg"))
    rgba[415:, :, 3] = 0
    tronco = next(o for o in separar_objetos(rgba) if 500 < o["caja"][0] < 700)
    guardar(recortar(rgba, tronco), ASSETS / "characters/animales/carpintero.png")

    # Mari: mariposa volando (4 cuadros, ordenados de izquierda a derecha) + retrato.
    rgba = quitar_fondo(cargar("zona2_monarca_vuelo.png"))
    vuelo = sorted(separar_objetos(rgba, union=40), key=lambda o: o["caja"][0])
    cuadros = [recortar(rgba, o) for o in vuelo]
    construir_atlas(
        cuadros,
        {"idle": ([0, 1, 2, 3, 2, 1], 12.0, True), "hablar": ([0, 1, 2, 3, 2, 1], 14.0, True)},
        (560, 600),
        ASSETS / "characters/mari/mari_atlas.png",
        ASSETS / "characters/mari/mari_frames.tres",
        "res://assets/characters/mari/mari_atlas.png",
        por_fila=4,
    )
    retrato = objetos("mari_retrato.png", ["mari_retrato"], "characters/mari")["mari_retrato"]
    guardar(retrato.resize((512, round(512 * retrato.height / retrato.width)), Image.Resampling.LANCZOS),
            ASSETS / "characters/mari/mari_retrato.png")

    # Plataformas del bosque: 0 bloque de suelo, 5 tronco.
    piezas = objetos("zona2_plataformas.png", [
        "suelo_bloque", "isla_grande", "isla_chica", "rampa_orilla", "pilar", "tronco", "tronco_2", "orilla_izquierda",
    ], "maps/zona2/plataformas")
    # El bloque trae un pino a la izquierda: la tira se arma con la parte derecha (sin árbol) y
    # el borde izquierdo es el derecho volteado.
    suelo = piezas["suelo_bloque"]
    tapa = 70
    derecha = suelo.crop((suelo.width - tapa, 0, suelo.width, suelo.height))
    izquierda = derecha.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    centro = hacer_repetible_h(suelo.crop((330, 0, suelo.width - tapa, suelo.height)), 40)
    tira = Image.new("RGBA", (tapa * 2 + centro.width, suelo.height))
    tira.alpha_composite(izquierda, (0, 0))
    tira.alpha_composite(centro, (tapa, 0))
    tira.alpha_composite(derecha, (tapa + centro.width, 0))
    tira = tira.crop(tira.getbbox())
    tira = Image.fromarray(arte.quitar_tinte_magenta(np.asarray(tira), rojo=20, azul=20))
    guardar(tira, ASSETS / "maps/zona2/plataformas/suelo_tira.png")
    # Alto del pasto (para que el decorador no lo estire): última fila mayormente verde.
    a = np.asarray(tira).astype(int)
    verde = [y for y in range(a.shape[0]) if (a[y, :, 3] > 0).any()
             and (a[y, a[y, :, 3] > 0, 1] > a[y, a[y, :, 3] > 0, 0] + 15).mean() > 0.5]
    print("  suelo_tira zona2:", tira.size, "pasto hasta y =", max(verde) if verde else "?")


def bitacora() -> None:
    """Una imagen cuadrada por especie (assets/ui/bitacora/<id>.png) con el arte que ya existe."""
    destino = ASSETS / "ui/bitacora"
    atlas = Image.open(ASSETS / "characters/animales/zona1_animales_atlas.png")
    cw, ch = atlas.width // 4, atlas.height // 4
    fuentes = {
        "acocil": atlas.crop((0, 0, cw, ch)),
        "garza": atlas.crop((0, ch, cw, 2 * ch)),
        "martin_pescador": atlas.crop((0, 2 * ch, cw, 3 * ch)),
        "pez_rio": atlas.crop((0, 3 * ch, cw, 4 * ch)),
        "monarca": Image.open(ASSETS / "characters/animales/monarca.png"),
        "oyamel": Image.open(ASSETS / "maps/valle/objetos/oyamel.png"),
        "encino": Image.open(ASSETS / "maps/valle/objetos/encino.png"),
        "pino": Image.open(ASSETS / "maps/valle/objetos/sabino.png"),
        "venado": Image.open(ASSETS / "objects/zona2/venado.png"),
        "carpintero": Image.open(ASSETS / "characters/animales/carpintero.png"),
        "achoque": Image.open(ASSETS / "objects/zona3/achoque.png"),
        "tule": Image.open(ASSETS / "objects/zona3/tule.png"),
        "pato_mexicano": Image.open(ASSETS / "characters/animales/pato_mexicano.png"),
        "pescado_blanco": Image.open(ASSETS / "characters/animales/pescado_blanco.png"),
    }
    for nombre, img in fuentes.items():
        img = img.convert("RGBA")
        img = img.crop(img.getbbox())
        img.thumbnail((240, 240), Image.Resampling.LANCZOS)
        lienzo = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        lienzo.alpha_composite(img, ((256 - img.width) // 2, (256 - img.height) // 2))
        guardar(lienzo, destino / f"{nombre}.png")


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


# ---------------------------------------------------------------- Después del final
def _por_filas(objetos: list[dict], alto_fila: int = 384) -> list[dict]:
    """Ordena por fila (arriba/abajo) y luego de izquierda a derecha."""
    return sorted(objetos, key=lambda o: ((o["caja"][1] + o["caja"][3]) // 2 // alto_fila, o["caja"][0]))


def animales_valle() -> None:
    """Animales vistos desde arriba que pasean por el valle.

    Hojas con 2 filas: arriba 4 cuadros caminando a la derecha; abajo quieto, comiendo,
    descansando y la cría. La monarca son 8 cuadros volando.
    """
    destino = ASSETS / "characters/animales/valle"
    for especie in ["venado", "garza", "pato"]:
        rgba = quitar_fondo(cargar(f"valle_{especie}.jpg"))
        cuadros = [recortar(rgba, o) for o in _por_filas(separar_objetos(rgba))]
        construir_atlas(
            cuadros,
            {"caminar": ([0, 1, 2, 3], 8.0, True), "idle": ([4], 1.0, True), "comer": ([5, 4], 1.2, True),
             "descansar": ([6], 1.0, True), "cria": ([7], 1.0, True)},
            (380, 340),
            destino / f"{especie}_atlas.png", destino / f"{especie}_frames.tres",
            f"res://assets/characters/animales/valle/{especie}_atlas.png",
            por_fila=4,
        )
    rgba = quitar_fondo(cargar("valle_monarca.jpg"))
    cuadros = [recortar(rgba, o) for o in _por_filas(separar_objetos(rgba))]
    construir_atlas(
        cuadros, {"volar": (list(range(8)), 12.0, True)}, (380, 340),
        destino / "monarca_atlas.png", destino / "monarca_frames.tres",
        "res://assets/characters/animales/valle/monarca_atlas.png", por_fila=4,
    )


def casa() -> None:
    """Interior de la casa del guardián y sus muebles."""
    rgba = quitar_fondo(cargar("casa_interior.jpg"))
    cuarto = recortar(rgba, separar_objetos(rgba)[0])
    # La IA dibujó la puerta como un marco suelto a mitad del piso: se tapa con el piso de al lado
    # (las tablas son horizontales y empatan) y se corta lo que queda debajo del piso.
    cuarto.paste(cuarto.crop((650, 440, 840, 646)), (455, 440))
    guardar(cuarto.crop((0, 0, cuarto.width, 646)), ASSETS / "maps/casa/interior.png")
    # Orden: cama, tabla de arriba de la repisa, tablero, baúl, tabla de abajo, alfombra,
    # lámpara, pecera, maceta. Las dos tablas son una sola repisa.
    rgba = quitar_fondo(cargar("casa_muebles.jpg"))
    o = separar_objetos(rgba)
    piezas = {"cama": o[0], "repisa": unir(o[1], o[4]), "tablero": o[2], "baul": o[3], "alfombra": o[5],
              "lampara": o[6], "pecera": o[7], "maceta": o[8]}
    for nombre, obj in piezas.items():
        guardar(recortar(rgba, obj), ASSETS / "maps/casa" / f"{nombre}.png")


GRUPOS = {"animales_valle": animales_valle, "casa": casa, "guardianes": guardianes, "valle": valle, "zona1": zona1, "personajes": personajes, "ui": ui, "filtro": puzzle_filtro, "zona2": zona2, "bitacora": bitacora, "zona3": zona3}

if __name__ == "__main__":
    for nombre in sys.argv[1:] or GRUPOS:
        print("Procesando", nombre, "...")
        GRUPOS[nombre]()
    print("Listo.")

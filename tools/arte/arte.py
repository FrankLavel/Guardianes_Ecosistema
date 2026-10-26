"""Utilidades para limpiar el arte generado con IA (assets/fuente_ia) y convertirlo en PNG para Godot.

Uso típico desde procesar.py:
    img = cargar("valle_objetos.jpg")
    rgba = quitar_fondo(img)
    piezas = separar_objetos(rgba)
"""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAIZ = Path(__file__).resolve().parents[2]
FUENTE = RAIZ / "assets" / "fuente_ia"


def cargar(nombre: str) -> np.ndarray:
    return np.asarray(Image.open(FUENTE / nombre).convert("RGB")).astype(np.int16)


def _es_magenta(px: np.ndarray, fuerte: bool) -> np.ndarray:
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    if fuerte:
        return (r > 150) & (b > 150) & (g < 110) & (np.abs(r - b) < 90)
    # Magenta oscuro o mezclado (sombras dibujadas por la IA, bordes JPG, fondos rosados).
    return (r - g > 45) & (b - g > 45) & (np.abs(r - b) < 110)


def _inundar(candidato: np.ndarray) -> np.ndarray:
    """Pixeles candidatos conectados con el borde de la imagen."""
    h, w = candidato.shape
    visto = np.zeros((h, w), bool)
    q: deque = deque()
    for x in range(w):
        for y in (0, h - 1):
            if candidato[y, x] and not visto[y, x]:
                visto[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if candidato[y, x] and not visto[y, x]:
                visto[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and candidato[ny, nx] and not visto[ny, nx]:
                visto[ny, nx] = True
                q.append((ny, nx))
    return visto


def quitar_fondo(img: np.ndarray, quitar_sombras: bool = True, huecos: bool = True) -> np.ndarray:
    """Devuelve RGBA uint8 sin el fondo magenta (y sin las sombras magenta si se pide).

    `huecos=False`: solo se quita el fondo que toca la orilla de la imagen. Para dibujos con
    partes rosas por dentro (el ajolote), que si no se volverían transparentes.
    """
    fondo = _es_magenta(img, fuerte=True) | _parecido_al_borde(img)
    if not huecos:
        fondo = _inundar(fondo)
    if quitar_sombras:
        fondo |= _inundar(_es_magenta(img, fuerte=False)) | (_es_magenta(img, fuerte=False) & fondo_cerca(fondo, 3))
    alfa = np.where(fondo, 0, 255).astype(np.uint8)
    # Quitar motas de 1-2 px.
    a = Image.fromarray(alfa).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    alfa = np.asarray(a)
    rgb = _despill(img, alfa)
    return np.dstack([rgb, alfa]).astype(np.uint8)


def _parecido_al_borde(img: np.ndarray, tolerancia: int = 70) -> np.ndarray:
    """Pixeles del mismo color que el fondo (se estima con la mediana del borde de la imagen).

    Sirve para fondos que no son magenta puro y para huecos encerrados (dentro de un arco).
    """
    borde = np.concatenate([img[0], img[-1], img[:, 0], img[:, -1]])
    color = np.median(borde, axis=0)
    return np.abs(img - color).sum(axis=-1) < tolerancia


def fondo_cerca(fondo: np.ndarray, radio: int) -> np.ndarray:
    m = Image.fromarray((fondo * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(radio * 2 + 1))
    return np.asarray(m) > 0


def _despill(img: np.ndarray, alfa: np.ndarray) -> np.ndarray:
    """Quita el tinte magenta de los bordes (artefacto del JPG)."""
    rgb = img.copy()
    borde = fondo_cerca(alfa == 0, 2) & (alfa > 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    exceso = np.minimum(r, b) - g
    tinte = borde & (exceso > 0)
    rgb[..., 0] = np.where(tinte, r - exceso * 0.8, r)
    rgb[..., 2] = np.where(tinte, b - exceso * 0.8, b)
    return np.clip(rgb, 0, 255).astype(np.uint8)


def separar_objetos(rgba: np.ndarray, area_min: int = 400, union: int = 6) -> list[dict]:
    """Objetos encontrados: {"caja": (x0, y0, x1, y1), "mascara": bool recortada a la caja}.

    Une piezas que estén a menos de `union` px (p. ej. el chorro de agua de una tubería).
    """
    alfa = rgba[..., 3] > 0
    if union > 0:
        alfa_u = np.asarray(Image.fromarray((alfa * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(union * 2 + 1))) > 0
    else:
        alfa_u = alfa
    h, w = alfa.shape
    etiqueta = np.zeros((h, w), np.int32)
    cajas = []
    n = 0
    for sy, sx in zip(*np.nonzero(alfa_u)):
        if etiqueta[sy, sx]:
            continue
        n += 1
        etiqueta[sy, sx] = n
        q = deque([(sy, sx)])
        y0 = y1 = sy
        x0 = x1 = sx
        while q:
            y, x = q.popleft()
            y0, y1, x0, x1 = min(y0, y), max(y1, y), min(x0, x), max(x1, x)
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and alfa_u[ny, nx] and not etiqueta[ny, nx]:
                    etiqueta[ny, nx] = n
                    q.append((ny, nx))
        area = int(alfa[y0 : y1 + 1, x0 : x1 + 1].sum())
        if area >= area_min:
            mascara = (etiqueta[y0 : y1 + 1, x0 : x1 + 1] == n) & alfa[y0 : y1 + 1, x0 : x1 + 1]
            cajas.append({"caja": (x0, y0, x1 + 1, y1 + 1), "mascara": mascara})
    cajas.sort(key=lambda o: (o["caja"][1] // 80, o["caja"][0]))
    return cajas


def recortar(rgba: np.ndarray, objeto: dict) -> Image.Image:
    """Recorta solo los pixeles del objeto (sin pedazos de objetos vecinos)."""
    x0, y0, x1, y1 = objeto["caja"]
    pieza = rgba[y0:y1, x0:x1].copy()
    pieza[..., 3] = np.where(objeto["mascara"], pieza[..., 3], 0)
    img = Image.fromarray(pieza)
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def vista_numerada(rgba: np.ndarray, cajas, destino: Path) -> None:
    """Imagen de revisión con cada objeto encerrado y numerado."""
    fondo = Image.new("RGBA", (rgba.shape[1], rgba.shape[0]), (40, 60, 80, 255))
    fondo.alpha_composite(Image.fromarray(rgba))
    d = ImageDraw.Draw(fondo)
    fuente = ImageFont.truetype("arial.ttf", 28)
    for i, objeto in enumerate(cajas):
        x0, y0, x1, y1 = objeto["caja"]
        d.rectangle([x0, y0, x1, y1], outline=(255, 255, 0), width=2)
        d.rectangle([x0, y0, x0 + 40, y0 + 32], fill=(0, 0, 0))
        d.text((x0 + 4, y0 + 1), str(i), fill=(255, 255, 0), font=fuente)
    fondo.convert("RGB").save(destino)


def guardar(img: Image.Image, ruta: Path) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    img.save(ruta, optimize=True)


def hacer_repetible_h(img: Image.Image, mezcla: int) -> Image.Image:
    """Hace que la imagen se pueda repetir en horizontal sin que se note la unión.

    Mezcla las primeras `mezcla` columnas con las últimas y recorta el sobrante.
    """
    a = np.asarray(img.convert("RGBA")).astype(np.float32)
    h, w = a.shape[:2]
    salida = a[:, : w - mezcla].copy()
    t = np.linspace(0.0, 1.0, mezcla)[None, :, None]
    salida[:, :mezcla] = a[:, :mezcla] * t + a[:, w - mezcla :] * (1.0 - t)
    return Image.fromarray(np.clip(salida, 0, 255).astype(np.uint8), "RGBA")


def hacer_repetible(img: Image.Image, mezcla: int) -> Image.Image:
    """Repetible en horizontal y en vertical (para texturas de suelo vistas desde arriba)."""
    h = hacer_repetible_h(img, mezcla)
    v = hacer_repetible_h(h.transpose(Image.Transpose.TRANSPOSE), mezcla)
    return v.transpose(Image.Transpose.TRANSPOSE)


def construir_atlas(
    cuadros: list[Image.Image],
    animaciones: dict[str, tuple[list[int], float, bool]],
    celda: tuple[int, int],
    png: Path,
    tres: Path,
    ruta_res: str,
    por_fila: int = 8,
    anclar_torso: bool = False,
) -> None:
    """Atlas con celdas uniformes (pies abajo y centrados) + recurso SpriteFrames de Godot.

    `animaciones`: nombre -> (índices de `cuadros`, fps, repetir).
    `anclar_torso`: centra cada cuadro por la cabeza/torso y no por su caja completa; así brazos
    y piernas extendidos no hacen que el personaje "brinque" de lado entre cuadros.
    """
    cw, ch = celda
    filas = (len(cuadros) + por_fila - 1) // por_fila
    atlas = Image.new("RGBA", (cw * por_fila, ch * filas), (0, 0, 0, 0))
    for i, c in enumerate(cuadros):
        if c.width > cw or c.height > ch:
            raise ValueError(f"El cuadro {i} ({c.size}) no cabe en la celda {celda}")
        ox, oy = (i % por_fila) * cw, (i // por_fila) * ch
        x = (cw - c.width) // 2
        if anclar_torso:
            alfa = np.asarray(c)[: c.height // 2, :, 3] > 0
            xs = np.nonzero(alfa)[1]
            if len(xs):
                x = int(np.clip(cw // 2 - round(xs.mean()), 0, cw - c.width))
        atlas.alpha_composite(c, (ox + x, oy + ch - c.height))
    guardar(atlas, png)

    subs = []
    for i in range(len(cuadros)):
        ox, oy = (i % por_fila) * cw, (i // por_fila) * ch
        subs.append(
            f'[sub_resource type="AtlasTexture" id="c{i}"]\natlas = ExtResource("1_atlas")\n'
            f"region = Rect2({ox}, {oy}, {cw}, {ch})\n"
        )
    anims = []
    for nombre, (indices, fps, repetir) in animaciones.items():
        frames = ", ".join(f'{{\n"duration": 1.0,\n"texture": SubResource("c{i}")\n}}' for i in indices)
        anims.append(
            f'{{\n"frames": [{frames}],\n"loop": {str(repetir).lower()},\n"name": &"{nombre}",\n"speed": {fps}\n}}'
        )
    texto = (
        f'[gd_resource type="SpriteFrames" load_steps={len(subs) + 2} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{ruta_res}" id="1_atlas"]\n\n'
        + "\n".join(subs)
        + "\n[resource]\nanimations = ["
        + ", ".join(anims)
        + "]\n"
    )
    tres.parent.mkdir(parents=True, exist_ok=True)
    tres.write_text(texto, encoding="utf-8", newline="\n")


def quitar_tinte_magenta(rgba: np.ndarray, rojo: int = 45, azul: int = 45) -> np.ndarray:
    """Vuelve transparente cualquier pixel con tinte magenta, aunque esté dentro del dibujo.

    Sirve para imágenes donde la IA mezcló el fondo magenta con el dibujo (árboles fantasma
    rosados, brillos rosas). No usar en imágenes con morados o rosas reales.
    """
    rgba = rgba.copy()
    px = rgba[..., :3].astype(np.int16)
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    # `rojo`/`azul`: cuánto más rojo/azul que verde debe ser un pixel para considerarlo teñido.
    tinte = (r - g > rojo) & (b - g > azul)
    rgba[..., 3] = np.where(tinte, 0, rgba[..., 3])
    return rgba


def quitar_cielo_magenta(img: np.ndarray) -> np.ndarray:
    """Para capas de paisaje: quita solo el magenta conectado con el borde superior."""
    candidato = _es_magenta(img, fuerte=False)
    h, w = candidato.shape
    visto = np.zeros((h, w), bool)
    q: deque = deque((0, x) for x in range(w) if candidato[0, x])
    for _, x in list(q):
        visto[0, x] = True
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and candidato[ny, nx] and not visto[ny, nx]:
                visto[ny, nx] = True
                q.append((ny, nx))
    # Huecos encerrados entre árboles: magenta puro en cualquier parte.
    visto |= _es_magenta(img, fuerte=True)
    alfa = np.where(visto, 0, 255).astype(np.uint8)
    return np.dstack([_despill(img, alfa), alfa]).astype(np.uint8)

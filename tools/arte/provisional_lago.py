"""Arte PROVISIONAL de la Zona 3 (lago), dibujado por código en pixel art sencillo.

    python tools/arte/provisional_lago.py

Se reemplaza al generar el arte con IA (ver docs/arte/GUIA_ARTE.md, sección 8): basta con
procesar las imágenes nuevas y guardarlas con el mismo nombre en assets/objects/zona3/.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[2]
DESTINO = RAIZ / "assets" / "objects" / "zona3"
BITACORA = RAIZ / "assets" / "ui" / "bitacora"
Z = 4  # se dibuja chico y se amplía sin suavizar

CONTORNO = (40, 26, 22, 255)


def lienzo(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def guardar(img: Image.Image, nombre: str) -> Image.Image:
    DESTINO.mkdir(parents=True, exist_ok=True)
    grande = img.resize((img.width * Z, img.height * Z), Image.Resampling.NEAREST)
    grande.save(DESTINO / f"{nombre}.png")
    return grande


def para_bitacora(img: Image.Image, nombre: str) -> None:
    img = img.crop(img.getbbox())
    img.thumbnail((240, 240), Image.Resampling.NEAREST)
    fondo = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    fondo.alpha_composite(img, ((256 - img.width) // 2, (256 - img.height) // 2))
    BITACORA.mkdir(parents=True, exist_ok=True)
    fondo.save(BITACORA / f"{nombre}.png")


def achoque() -> Image.Image:
    """Achoque (ajolote de Pátzcuaro) de lado, mirando a la derecha."""
    img, d = lienzo(52, 26)
    cuerpo, panza, branquia = (122, 92, 78, 255), (176, 146, 120, 255), (226, 98, 110, 255)
    # Cola
    d.polygon([(2, 12), (16, 9), (16, 17), (4, 15)], fill=cuerpo, outline=CONTORNO)
    d.polygon([(3, 10), (14, 6), (16, 9)], fill=(150, 118, 100, 255))
    # Cuerpo
    d.ellipse([12, 8, 38, 20], fill=cuerpo, outline=CONTORNO)
    d.ellipse([16, 14, 34, 20], fill=panza)
    # Patas
    for x in (16, 30):
        d.rectangle([x, 18, x + 2, 23], fill=cuerpo, outline=CONTORNO)
        d.line([x - 1, 23, x + 3, 23], fill=CONTORNO)
    # Cabeza
    d.ellipse([32, 6, 49, 20], fill=cuerpo, outline=CONTORNO)
    # Branquias (3 ramitas rosas)
    for (x0, y0, x1, y1) in [(35, 7, 31, 1), (37, 7, 36, 0), (39, 7, 41, 1)]:
        d.line([x0, y0, x1, y1], fill=branquia, width=2)
        d.point((x1, y1), fill=(250, 150, 160, 255))
    # Ojo y sonrisa
    d.point((44, 11), fill=(10, 10, 10, 255))
    d.point((45, 11), fill=(10, 10, 10, 255))
    d.point((44, 10), fill=(255, 255, 255, 255))
    d.line([42, 15, 46, 15], fill=CONTORNO)
    # Manchitas
    for p in [(20, 11), (25, 10), (29, 12), (23, 13)]:
        d.point(p, fill=(90, 66, 56, 255))
    return img


def huevo() -> Image.Image:
    img, d = lienzo(14, 14)
    d.ellipse([1, 1, 12, 12], fill=(200, 230, 210, 170), outline=(120, 170, 140, 255))
    d.ellipse([4, 4, 9, 9], fill=(70, 60, 50, 255))
    d.point((5, 5), fill=(160, 140, 120, 255))
    d.point((10, 3), fill=(255, 255, 255, 220))
    return img


def lirio() -> Image.Image:
    """Lirio acuático (planta invasora): hojas verdes flotando y flor morada."""
    img, d = lienzo(40, 22)
    verde, oscuro = (70, 140, 60, 255), (35, 85, 35, 255)
    for (x, y, w, h) in [(1, 12, 14, 8), (11, 10, 16, 9), (24, 12, 14, 8), (6, 7, 12, 7), (20, 6, 12, 7)]:
        d.ellipse([x, y, x + w, y + h], fill=verde, outline=oscuro)
    for (x, y) in [(15, 2), (18, 0), (21, 2), (18, 4)]:
        d.ellipse([x - 3, y, x + 3, y + 5], fill=(170, 120, 210, 255), outline=(90, 55, 130, 255))
    d.point((18, 3), fill=(250, 220, 90, 255))
    # Raíces colgando (bajo el agua)
    for x in (8, 18, 30):
        d.line([x, 19, x - 1, 21], fill=(60, 70, 50, 255))
    return img


def tule() -> Image.Image:
    img, d = lienzo(24, 48)
    for i, x in enumerate([3, 7, 11, 15, 19]):
        alto = 12 + (i * 7) % 15
        d.line([x, 47, x + (i % 3) - 1, alto], fill=(80, 130, 60, 255), width=2)
        d.line([x + 1, 47, x + (i % 3), alto], fill=(50, 95, 40, 255))
        if i % 2 == 0:
            d.rectangle([x + (i % 3) - 2, alto - 7, x + (i % 3) + 1, alto], fill=(120, 80, 45, 255), outline=(70, 45, 25, 255))
    return img


def sol() -> Image.Image:
    img, d = lienzo(40, 40)
    for k in range(12):
        a = k * np.pi / 6
        d.line([20 + 11 * np.cos(a), 20 + 11 * np.sin(a), 20 + 18 * np.cos(a), 20 + 18 * np.sin(a)],
               fill=(250, 190, 40, 255), width=2)
    d.ellipse([9, 9, 31, 31], fill=(255, 215, 70, 255), outline=(220, 140, 30, 255))
    d.point((16, 17), fill=CONTORNO)
    d.point((24, 17), fill=CONTORNO)
    d.arc([14, 16, 26, 26], 20, 160, fill=CONTORNO)
    return img


def insecto() -> Image.Image:
    """Larva/insecto acuático (libélula joven) de lado."""
    img, d = lienzo(36, 16)
    d.ellipse([2, 5, 22, 11], fill=(110, 120, 60, 255), outline=CONTORNO)
    d.ellipse([20, 4, 30, 12], fill=(130, 140, 70, 255), outline=CONTORNO)
    d.point((27, 7), fill=(10, 10, 10, 255))
    for x in (8, 13, 18):
        d.line([x, 11, x - 2, 15], fill=CONTORNO)
    d.polygon([(10, 5), (18, 0), (20, 5)], fill=(190, 220, 240, 180), outline=(100, 130, 160, 255))
    return img


def cascara() -> Image.Image:
    img, d = lienzo(24, 16)
    d.polygon([(2, 12), (8, 5), (12, 10), (16, 4), (22, 12), (12, 15)], fill=(245, 210, 70, 255), outline=(150, 110, 30, 255))
    d.point((12, 14), fill=(110, 80, 30, 255))
    for p in [(7, 9), (16, 8)]:
        d.point(p, fill=(120, 90, 40, 255))
    return img


def papel() -> Image.Image:
    img, d = lienzo(22, 18)
    d.polygon([(2, 3), (18, 1), (20, 15), (4, 17)], fill=(240, 238, 228, 255), outline=(120, 115, 105, 255))
    for y in (6, 9, 12):
        d.line([6, y, 16, y - 1], fill=(150, 170, 200, 255))
    d.line([2, 3, 6, 7], fill=(190, 185, 170, 255))
    return img


if __name__ == "__main__":
    a = guardar(achoque(), "achoque")
    para_bitacora(a, "achoque")
    guardar(huevo(), "huevo")
    guardar(lirio(), "lirio")
    t = guardar(tule(), "tule")
    para_bitacora(t, "tule")
    guardar(sol(), "sol")
    guardar(insecto(), "insecto")
    guardar(cascara(), "cascara")
    guardar(papel(), "papel")
    print("Arte provisional del lago en", DESTINO)

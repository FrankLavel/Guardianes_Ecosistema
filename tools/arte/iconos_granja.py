"""Íconos PROVISIONALES de la granja (pixel art dibujado con código).

    python tools/arte/iconos_granja.py

Se reemplazan por el arte final generado con IA (ver docs/arte/GUIA_ARTE.md, sección 10)
guardando un PNG con el mismo nombre en assets/ui/granja/ o assets/objects/granja/.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[2]
ICONOS = RAIZ / "assets/ui/granja"
PLANTAS = RAIZ / "assets/objects/granja"
LADO = 24
ZOOM = 5
CONTORNO = (40, 26, 16, 255)

C = {
    "amarillo": (246, 200, 60), "verde": (88, 160, 60), "verde_osc": (52, 110, 44), "cafe": (120, 74, 40),
    "cafe_osc": (84, 50, 28), "naranja": (232, 128, 40), "blanco": (246, 242, 230), "gris": (150, 160, 170),
    "azul": (90, 150, 210), "rojo": (200, 60, 50), "barro": (170, 90, 50), "rosa": (230, 150, 160),
}


def lienzo() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def guardar(img: Image.Image, ruta: Path) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    img.resize((LADO * ZOOM, LADO * ZOOM), Image.Resampling.NEAREST).save(ruta)


def elipse(d, caja, color):
    d.ellipse(caja, fill=color + (255,), outline=CONTORNO)


def maiz(d):
    d.polygon([(8, 20), (6, 9), (11, 4), (12, 20)], fill=C["verde"] + (255,), outline=CONTORNO)
    elipse(d, (10, 3, 16, 20), C["amarillo"])
    for y in range(6, 19, 3):
        d.line([(11, y), (15, y)], fill=(200, 150, 30, 255))
    d.polygon([(16, 20), (18, 9), (14, 6), (13, 20)], fill=C["verde_osc"] + (255,), outline=CONTORNO)


def frijol(d):
    for x, y in ((5, 9), (11, 12), (8, 4)):
        elipse(d, (x, y, x + 8, y + 6), C["cafe"])
        d.point((x + 3, y + 2), fill=(200, 160, 120, 255))


def calabaza(d):
    elipse(d, (3, 7, 21, 21), C["naranja"])
    d.line([(12, 8), (12, 20)], fill=(190, 90, 30, 255))
    d.line([(7, 9), (7, 19)], fill=(190, 90, 30, 255))
    d.line([(17, 9), (17, 19)], fill=(190, 90, 30, 255))
    d.rectangle((11, 3, 13, 7), fill=C["verde_osc"] + (255,), outline=CONTORNO)


def huevo(d):
    elipse(d, (7, 4, 17, 20), C["blanco"])
    d.point((10, 8), fill=(255, 255, 255, 255))


def leche(d):
    d.rectangle((7, 8, 17, 21), fill=C["blanco"] + (255,), outline=CONTORNO)
    d.rectangle((9, 4, 15, 8), fill=C["blanco"] + (255,), outline=CONTORNO)
    d.rectangle((9, 3, 15, 5), fill=C["azul"] + (255,), outline=CONTORNO)
    d.rectangle((8, 12, 16, 16), fill=C["azul"] + (255,))


def pescado(d):
    elipse(d, (3, 8, 17, 16), C["gris"])
    d.polygon([(16, 12), (22, 7), (22, 17)], fill=C["gris"] + (255,), outline=CONTORNO)
    d.point((6, 11), fill=CONTORNO)


def manzanilla(d):
    d.line([(12, 12), (12, 22)], fill=C["verde_osc"] + (255,), width=2)
    for dx, dy in ((0, -5), (5, 0), (0, 5), (-5, 0), (4, -4), (-4, 4), (4, 4), (-4, -4)):
        elipse(d, (12 + dx - 2, 10 + dy - 2, 12 + dx + 2, 10 + dy + 2), C["blanco"])
    elipse(d, (10, 8, 14, 12), C["amarillo"])


def hierbabuena(d):
    d.line([(12, 6), (12, 22)], fill=C["verde_osc"] + (255,), width=2)
    for y, lado in ((7, -1), (11, 1), (15, -1), (18, 1)):
        x = 12 + lado * 5
        elipse(d, (x - 4, y - 2, x + 4, y + 3), C["verde"])


def nopal(d):
    elipse(d, (6, 6, 18, 21), C["verde"])
    elipse(d, (13, 2, 21, 11), C["verde"])
    for x, y in ((9, 11), (13, 15), (10, 17), (16, 6)):
        d.point((x, y), fill=C["amarillo"] + (255,))


def lena(d):
    for y, x0 in ((8, 3), (13, 5), (17, 2)):
        d.rectangle((x0, y, x0 + 17, y + 4), fill=C["cafe"] + (255,), outline=CONTORNO)
        elipse(d, (x0 + 15, y, x0 + 19, y + 4), (200, 150, 90))


def semilla(color):
    def dibujar(d):
        d.polygon([(6, 9), (18, 9), (20, 21), (4, 21)], fill=(196, 160, 110, 255), outline=CONTORNO)
        d.rectangle((8, 5, 16, 9), fill=(180, 140, 90, 255), outline=CONTORNO)
        elipse(d, (9, 13, 15, 18), color)
    return dibujar


def plato(relleno):
    def dibujar(d):
        elipse(d, (2, 9, 22, 21), C["barro"])
        elipse(d, (4, 9, 20, 15), (120, 60, 30))
        relleno(d)
    return dibujar


def taza(color):
    def dibujar(d):
        d.rectangle((6, 9, 17, 20), fill=C["barro"] + (255,), outline=CONTORNO)
        d.arc((15, 11, 21, 17), 270, 90, fill=CONTORNO, width=2)
        d.rectangle((7, 10, 16, 12), fill=color + (255,))
        for x in (9, 13):
            d.line([(x, 3), (x + 1, 7)], fill=(230, 230, 230, 180))
    return dibujar


ICONOS_DEF = {
    "maiz": maiz, "frijol": frijol, "calabaza": calabaza, "huevo": huevo, "leche": leche, "pescado": pescado,
    "manzanilla": manzanilla, "hierbabuena": hierbabuena, "nopal": nopal, "lena": lena,
    "semilla_maiz": semilla(C["amarillo"]), "semilla_frijol": semilla(C["cafe"]), "semilla_calabaza": semilla(C["naranja"]),
    "elote_asado": plato(lambda d: elipse(d, (7, 6, 17, 12), C["amarillo"])),
    "huevos_frijoles": plato(lambda d: (elipse(d, (5, 9, 12, 14), C["cafe"]), elipse(d, (12, 8, 19, 13), C["blanco"]))),
    "corundas": plato(lambda d: d.polygon([(12, 5), (15, 10), (12, 13), (9, 10)], fill=(240, 220, 160, 255), outline=CONTORNO)),
    "sopa_tarasca": plato(lambda d: elipse(d, (5, 9, 19, 14), (150, 70, 40))),
    "calabaza_tacha": plato(lambda d: elipse(d, (7, 6, 17, 13), (200, 90, 30))),
    "nopales_asados": plato(lambda d: elipse(d, (6, 7, 18, 13), C["verde"])),
    "pescado_asado": plato(lambda d: (elipse(d, (5, 8, 16, 13), (190, 140, 90)), elipse(d, (15, 7, 19, 11), C["verde"]))),
    "atole": taza((220, 190, 130)),
    "te_manzanilla": taza((220, 190, 80)),
}


def planta(cultivo: str, etapa: int) -> Image.Image:
    """Etapas: 0 recién sembrada, 1 creciendo, 2 grande, 3 lista para cosechar."""
    img = Image.new("RGBA", (24, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    elipse(d, (2, 25, 22, 31), C["cafe_osc"])
    alto = [4, 11, 18, 22][etapa]
    if cultivo == "calabaza":
        d.line([(12, 28), (12, 28 - alto // 2)], fill=C["verde_osc"] + (255,), width=2)
        for x in range(4, 20, 6)[: etapa + 1]:
            elipse(d, (x, 26 - alto // 2, x + 6, 30 - alto // 2 + 2), C["verde"])
        if etapa == 3:
            elipse(d, (7, 20, 17, 29), C["naranja"])
    else:
        d.line([(12, 28), (12, 28 - alto)], fill=C["verde_osc"] + (255,), width=2)
        for k in range(etapa + 1):
            y = 26 - k * 5
            elipse(d, (12 - 6, y - 2, 12, y + 1), C["verde"])
            elipse(d, (12, y - 4, 18, y - 1), C["verde"])
        if etapa == 3:
            if cultivo == "maiz":
                elipse(d, (13, 8, 17, 15), C["amarillo"])
            else:
                for x, y in ((6, 14), (15, 18)):
                    d.rectangle((x, y, x + 3, y + 6), fill=(140, 170, 60, 255), outline=CONTORNO)
    return img


if __name__ == "__main__":
    for nombre, dibujar in ICONOS_DEF.items():
        img, d = lienzo()
        dibujar(d)
        guardar(img, ICONOS / f"{nombre}.png")
    for cultivo in ("maiz", "frijol", "calabaza"):
        for etapa in range(4):
            img = planta(cultivo, etapa)
            img.resize((img.width * ZOOM, img.height * ZOOM), Image.Resampling.NEAREST).save(PLANTAS / f"{cultivo}_{etapa}.png") \
                if PLANTAS.mkdir(parents=True, exist_ok=True) is None else None
    print("Íconos provisionales en", ICONOS, "y", PLANTAS)

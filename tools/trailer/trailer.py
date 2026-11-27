"""Tráiler promocional de ~36 s: logo, 8 tomas con su mecánica en pantalla y cierre con logo.

Ejecutar desde la raíz del proyecto (necesita ffmpeg y el video demo de Play):
    python tools/trailer/trailer.py
Toma las escenas de builds/playstore/video_demo_1080p.mp4 (se graba con el script de captura del
video demo) y deja el resultado en builds/promo/trailer_guardianes.mp4.
La música es original: un chiptune de 140 BPM generado aquí mismo; los cortes caen cada 2 compases.
"""
from __future__ import annotations

import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

RAIZ = Path(__file__).resolve().parents[2]
DEMO = RAIZ / "builds/playstore/video_demo_1080p.mp4"
SALIDA = RAIZ / "builds/promo/trailer_guardianes.mp4"
LOGO = RAIZ / "assets/ui/logo.png"
LOGO_UTOM = RAIZ / "assets/ui/app/logo_utom.png"
FUENTE = "C:/Windows/Fonts/seguibl.ttf"  # Segoe UI Black
FUENTE_TEXTO = "C:/Windows/Fonts/segoeuib.ttf"

FS = 44100
BPM = 140
COMPAS = 4 * 60 / BPM  # 1.714 s
W, H = 1920, 1080

# (segundo de inicio en el video demo, texto). Cada toma dura 2 compases.
TOMAS = [
    (6.0, "EXPLORA EL VALLE DE TZINTZUN"),
    (18.5, "LIMPIA EL RÍO CUPATITZIO"),
    (29.0, "RESUELVE MINIJUEGOS"),
    (40.0, "SALVA EL BOSQUE DE OYAMEL"),
    (46.0, "RESCATA EL LAGO DE PÁTZCUARO"),
    (50.2, "DESCUBRE 14 ESPECIES REALES"),
    (58.0, "CUIDA TU PROPIA GRANJA"),
    (65.5, "COCINA COMIDA MICHOACANA"),
]
COMPASES_INICIO, COMPASES_TOMA, COMPASES_FIN = 2, 2, 3


# ---------------------------------------------------------------- Música
def midi(n: float) -> float:
    return 440.0 * 2 ** ((n - 69) / 12)


def onda(freq: float, seg: float, forma: str, vol: float, caida: float) -> np.ndarray:
    t = np.arange(int(seg * FS)) / FS
    fase = (freq * t) % 1.0
    if forma == "cuadrada":
        s = np.where(fase < 0.5, 1.0, -1.0)
    elif forma == "pulso":
        s = np.where(fase < 0.25, 1.0, -1.0)
    else:  # triangular
        s = 4 * np.abs(fase - 0.5) - 1
    env = np.exp(-t / caida) * np.minimum(1, t / 0.004)
    return s * env * vol


def bombo(vol=0.9) -> np.ndarray:
    t = np.arange(int(0.18 * FS)) / FS
    freq = 45 + 110 * np.exp(-t / 0.03)
    return np.sin(2 * np.pi * np.cumsum(freq) / FS) * np.exp(-t / 0.07) * vol


def ruido(seg: float, caida: float, vol: float, agudo=False) -> np.ndarray:
    n = np.random.default_rng(len(str(seg))).uniform(-1, 1, int(seg * FS))
    if agudo:
        n = np.diff(n, prepend=0)
    t = np.arange(n.size) / FS
    return n * np.exp(-t / caida) * vol


def tarola() -> np.ndarray:
    s = ruido(0.16, 0.05, 0.5)
    s[: int(0.16 * FS)] += onda(185, 0.16, "triangular", 0.35, 0.04)
    return s


def musica(compases: int) -> np.ndarray:
    pulso = 60 / BPM
    total = np.zeros(int((compases * COMPAS + 2.0) * FS))

    def poner(seg: float, s: np.ndarray) -> None:
        i = int(seg * FS)
        fin = min(total.size, i + s.size)
        total[i:fin] += s[: fin - i]

    acordes = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]]  # C G Am F
    melodia = [
        [76, None, 79, None, 81, 79, 76, None], [74, None, 79, None, 74, 71, 74, None],
        [72, None, 76, None, 81, None, 79, 76], [77, None, 76, None, 74, None, 72, None],
        [76, 79, 84, None, 83, None, 79, None], [81, None, 79, None, 74, None, 79, None],
        [76, None, 79, 81, 84, None, 81, None], [79, None, 77, None, 76, None, 74, None],
    ]
    principio = COMPASES_INICIO
    final = compases - COMPASES_FIN
    for c in range(compases):
        t0 = c * COMPAS
        acorde = acordes[c % 4]
        if c >= final:
            # Cierre: un golpe del acorde de Do con todo, y que suene hasta apagarse.
            if c == final:
                poner(t0, bombo(1.0))
                poner(t0, ruido(1.2, 0.4, 0.25, agudo=True))
                for n in [48, 60, 64, 67, 72, 76, 84]:
                    poner(t0, onda(midi(n), COMPAS * 3, "pulso" if n > 70 else "triangular", 0.16, 1.4))
            continue
        # Arpegio en semicorcheas (también en la entrada).
        for k in range(16):
            nota = acorde[k % 3] + 12 * (1 + (k // 3) % 2)
            poner(t0 + k * pulso / 4, onda(midi(nota), pulso / 4, "cuadrada", 0.05 if c < principio else 0.07, 0.06))
        if c < principio:
            if c == principio - 1:  # redoble y ruido que sube antes de la primera toma
                for k in range(8, 16):
                    poner(t0 + k * pulso / 4, tarola() * (0.3 + 0.05 * k))
            poner(t0 + 3 * pulso, bombo(0.6))
            continue
        for b in range(4):
            poner(t0 + b * pulso, bombo())
            if b in (1, 3):
                poner(t0 + b * pulso, tarola())
        for k in range(8):
            poner(t0 + k * pulso / 2, ruido(0.04, 0.012, 0.18 if k % 2 else 0.1, agudo=True))
            poner(t0 + k * pulso / 2, onda(midi(acorde[0] - 24 + 12 * (k % 2)), pulso / 2, "triangular", 0.45, 0.2))
        for k, nota in enumerate(melodia[(c - principio) % 8]):
            if nota is not None:
                poner(t0 + k * pulso / 2, onda(midi(nota), pulso * 0.9, "pulso", 0.13, 0.25))
    total = np.tanh(total * 1.4)
    total = total / np.abs(total).max() * 0.89
    return total[: int((compases * COMPAS + 1.5) * FS)]


def guardar_wav(ruta: Path, s: np.ndarray) -> None:
    datos = (s * 32767).astype(np.int16)
    with wave.open(str(ruta), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
        w.writeframes(datos.tobytes())


# ---------------------------------------------------------------- Imágenes
def letrero(texto: str) -> Image.Image:
    """Cartel con la mecánica: abajo al centro, entre el joystick y los botones táctiles."""
    img = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(img)
    fuente = ImageFont.truetype(FUENTE, 66)
    x0, y0, x1, y1 = d.textbbox((0, 0), texto, font=fuente)
    ancho, alto = x1 - x0 + 110, y1 - y0 + 56
    caja = ((W - ancho) // 2, 870, (W + ancho) // 2, 870 + alto)
    d.rounded_rectangle((caja[0] + 8, caja[1] + 10, caja[2] + 8, caja[3] + 10), 26, fill=(0, 0, 0, 120))
    d.rounded_rectangle(caja, 26, fill=(15, 46, 27, 235), outline=(246, 232, 196, 255), width=6)
    d.text((W // 2, (caja[1] + caja[3]) // 2), texto, font=fuente, fill=(255, 214, 102), anchor="mm",
           stroke_width=3, stroke_fill=(8, 25, 14))
    return img


def cuadro_demo(seg: float, carpeta: Path) -> Image.Image:
    ruta = carpeta / f"cuadro_{seg}.png"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(seg), "-i", str(DEMO), "-frames:v", "1", str(ruta)], check=True)
    return Image.open(ruta).convert("RGB")


def tarjeta(fondo: Image.Image, lineas: list[tuple[str, int, tuple]], con_utom: bool) -> Image.Image:
    img = fondo.filter(ImageFilter.GaussianBlur(14)).convert("RGBA")
    img.alpha_composite(Image.new("RGBA", (W, H), (6, 24, 12, 150)))
    logo = Image.open(LOGO).convert("RGBA")
    ancho = 1150
    logo = logo.resize((ancho, round(logo.height * ancho / logo.width)), Image.Resampling.LANCZOS)
    y = 150 if lineas else (H - logo.height) // 2 - 40
    img.alpha_composite(logo, ((W - ancho) // 2, y))
    y += logo.height + 40
    d = ImageDraw.Draw(img)
    for texto, tam, color in lineas:
        f = ImageFont.truetype(FUENTE_TEXTO, tam)
        d.text((W // 2, y), texto, font=f, fill=color, anchor="mt", stroke_width=3, stroke_fill=(8, 25, 14))
        y += tam + 28
    if con_utom:
        u = Image.open(LOGO_UTOM).convert("RGBA")
        u = u.resize((420, round(u.height * 420 / u.width)), Image.Resampling.LANCZOS)
        img.alpha_composite(u, ((W - u.width) // 2, H - u.height - 60))
    return img.convert("RGB")


# ---------------------------------------------------------------- Video
def ffmpeg(*args: str) -> None:
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


CODIF = ["-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p", "-r", "30", "-an"]


def video_tarjeta(png: Path, seg: float, salida: Path) -> None:
    cuadros = round(seg * 30)
    ffmpeg("-loop", "1", "-i", str(png), "-vf",
           f"scale=2400:-1,zoompan=z='1.0+0.06*on/{cuadros}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d={cuadros}:s={W}x{H}:fps=30",
           "-frames:v", str(cuadros), *CODIF, str(salida))


def video_toma(inicio: float, seg: float, png: Path, salida: Path) -> None:
    # El cartel entra subiendo y aparece, y se desvanece antes del corte.
    ffmpeg("-ss", str(inicio), "-t", f"{seg:.4f}", "-i", str(DEMO), "-loop", "1", "-t", f"{seg:.4f}", "-i", str(png),
           "-filter_complex",
           f"[1]format=rgba,fade=in:st=0.1:d=0.25:alpha=1,fade=out:st={seg - 0.3:.3f}:d=0.25:alpha=1[c];"
           f"[0]fps=30[v];[v][c]overlay=x=0:y='max(0,50-t*250)'",
           "-frames:v", str(round(seg * 30)), *CODIF, str(salida))


def main() -> None:
    if not DEMO.exists():
        raise SystemExit(f"Falta {DEMO}: graba primero el video demo.")
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    compases = COMPASES_INICIO + COMPASES_TOMA * len(TOMAS) + COMPASES_FIN
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        guardar_wav(tmp / "musica.wav", musica(compases))
        partes = []

        inicio = tarjeta(cuadro_demo(20.0, tmp), [("Un videojuego educativo de Michoacán", 54, (246, 232, 196))], False)
        inicio.save(tmp / "inicio.png")
        video_tarjeta(tmp / "inicio.png", COMPASES_INICIO * COMPAS, tmp / "p00.mp4")
        partes.append(tmp / "p00.mp4")

        for i, (seg, texto) in enumerate(TOMAS, 1):
            letrero(texto).save(tmp / f"l{i}.png")
            video_toma(seg, COMPASES_TOMA * COMPAS, tmp / f"l{i}.png", tmp / f"p{i:02}.mp4")
            partes.append(tmp / f"p{i:02}.mp4")

        fin = tarjeta(cuadro_demo(60.0, tmp), [
            ("Cuida el agua, los bosques y a los animales", 52, (246, 232, 196)),
            ("Gratis en Android, Windows y Web", 60, (255, 214, 102)),
        ], True)
        fin.save(tmp / "fin.png")
        video_tarjeta(tmp / "fin.png", COMPASES_FIN * COMPAS + 1.5, tmp / "p99.mp4")
        partes.append(tmp / "p99.mp4")

        (tmp / "lista.txt").write_text("".join(f"file '{p.as_posix()}'\n" for p in partes), encoding="utf-8")
        duracion = compases * COMPAS + 1.5
        ffmpeg("-f", "concat", "-safe", "0", "-i", str(tmp / "lista.txt"), "-i", str(tmp / "musica.wav"),
               "-vf", f"fade=in:st=0:d=0.4,fade=out:st={duracion - 0.9:.2f}:d=0.9",
               "-af", f"afade=out:st={duracion - 1.2:.2f}:d=1.2",
               "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
               "-c:a", "aac", "-b:a", "192k", "-ac", "2", "-movflags", "+faststart", "-shortest", str(SALIDA))
        fin.save(SALIDA.with_name("trailer_portada.png"))
    print(f"Listo: {SALIDA} ({duracion:.1f} s)")


if __name__ == "__main__":
    main()

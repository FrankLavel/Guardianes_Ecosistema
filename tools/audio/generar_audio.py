"""Genera los efectos de sonido y la música PROVISIONALES del juego (síntesis con numpy).

    python tools/audio/generar_audio.py

Crea WAV en assets/audio/sfx y assets/audio/musica. Para usar audio definitivo (por ejemplo de
una biblioteca CC0), basta con reemplazar el archivo manteniendo el nombre y anotar la licencia
en assets/audio/CREDITOS.md.
"""
from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

RAIZ = Path(__file__).resolve().parents[2]
SFX = RAIZ / "assets" / "audio" / "sfx"
MUSICA = RAIZ / "assets" / "audio" / "musica"
FS = 44100
rng = np.random.default_rng(7)


def t(seg: float) -> np.ndarray:
    return np.arange(int(FS * seg)) / FS


def envolvente(n: int, ataque: float, caida: float) -> np.ndarray:
    """Ataque lineal y caída exponencial (sonido tipo pulsado)."""
    x = np.arange(n) / FS
    a = np.clip(x / max(ataque, 1e-4), 0, 1)
    return a * np.exp(-x / caida)


def tono(freq, seg, forma="seno", ataque=0.005, caida=0.2, vol=0.5) -> np.ndarray:
    x = t(seg)
    f = np.broadcast_to(freq, x.shape) if np.ndim(freq) else np.full(x.shape, freq)
    fase = 2 * np.pi * np.cumsum(f) / FS
    if forma == "seno":
        s = np.sin(fase)
    elif forma == "triangulo":
        s = 2 / np.pi * np.arcsin(np.sin(fase))
    elif forma == "cuadrada":
        s = np.sign(np.sin(fase)) * 0.6
    else:  # marimba: fundamental + armónico suave
        s = np.sin(fase) + 0.25 * np.sin(fase * 4) * np.exp(-x / 0.05)
    return s * envolvente(len(x), ataque, caida) * vol


def ruido(seg, caida=0.2, vol=0.5, suavizado=1) -> np.ndarray:
    s = rng.uniform(-1, 1, int(FS * seg))
    if suavizado > 1:
        s = np.convolve(s, np.ones(suavizado) / suavizado, mode="same")
    return s * envolvente(len(s), 0.002, caida) * vol


def mezclar(*partes: tuple[float, np.ndarray]) -> np.ndarray:
    largo = max(int(inicio * FS) + len(p) for inicio, p in partes)
    out = np.zeros(largo)
    for inicio, p in partes:
        i = int(inicio * FS)
        out[i : i + len(p)] += p
    return out


def guardar(ruta: Path, s: np.ndarray, normalizar=0.8) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    pico = np.max(np.abs(s)) or 1.0
    datos = (s / pico * normalizar * 32767).astype(np.int16)
    with wave.open(str(ruta), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())


def nota(n: int) -> float:
    """Frecuencia de la nota MIDI n."""
    return 440.0 * 2 ** ((n - 69) / 12)


# ------------------------------------------------------------------ efectos
def efectos() -> None:
    x = t(0.18)
    guardar(SFX / "salto.wav", tono(np.linspace(300, 700, len(x)), 0.18, "triangulo", caida=0.08))
    guardar(SFX / "recoger.wav", mezclar((0, tono(nota(84), 0.25, "marimba", caida=0.12)),
                                         (0.07, tono(nota(91), 0.35, "marimba", caida=0.18))))
    guardar(SFX / "boton.wav", tono(nota(79), 0.08, "seno", caida=0.03), 0.5)
    guardar(SFX / "dialogo.wav", tono(nota(72), 0.05, "triangulo", caida=0.02), 0.35)
    guardar(SFX / "correcto.wav", mezclar(*[(i * 0.09, tono(nota(n), 0.4, "marimba", caida=0.2))
                                            for i, n in enumerate([72, 76, 79, 84])]))
    guardar(SFX / "incorrecto.wav", mezclar((0, tono(nota(52), 0.22, "cuadrada", caida=0.12, vol=0.3)),
                                            (0.12, tono(nota(49), 0.3, "cuadrada", caida=0.15, vol=0.3))), 0.55)
    # Válvula: chirrido metálico + golpe.
    chirrido = tono(np.linspace(900, 600, int(FS * 0.25)), 0.25, "cuadrada", caida=0.15, vol=0.15)
    guardar(SFX / "valvula.wav", mezclar((0, chirrido), (0.2, ruido(0.12, 0.05, 0.6, 4)),
                                         (0.2, tono(nota(45), 0.2, "seno", caida=0.08))), 0.7)
    guardar(SFX / "chapoteo.wav", mezclar((0, ruido(0.35, 0.12, 0.8, 12)),
                                          (0.02, tono(np.linspace(500, 200, int(FS * 0.2)), 0.2, caida=0.08, vol=0.3))), 0.6)
    guardar(SFX / "brazada.wav", ruido(0.25, 0.1, 0.6, 30), 0.4)
    guardar(SFX / "zona_restaurada.wav", mezclar(*[(i * 0.12, tono(nota(n), 0.9, "marimba", caida=0.5))
                                                   for i, n in enumerate([67, 72, 76, 79, 84, 88])]))
    guardar(SFX / "punto_control.wav", mezclar((0, tono(nota(79), 0.3, "seno", caida=0.15)),
                                               (0.06, tono(nota(86), 0.4, "seno", caida=0.2))), 0.5)


# ------------------------------------------------------------------ música
def pieza(acordes: list[list[int]], melodia: list[int | None], bpm: float, compases_por_acorde=1,
          brillo=1.0) -> np.ndarray:
    """Loop simple: pad suave con los acordes + melodía de marimba en corcheas."""
    negra = 60 / bpm
    compas = negra * 4
    total = compas * compases_por_acorde * len(acordes)
    out = np.zeros(int(FS * total) + FS)
    for i, acorde in enumerate(acordes):
        inicio = i * compas * compases_por_acorde
        dur = compas * compases_por_acorde
        for n in acorde:
            x = t(dur)
            pad = np.sin(2 * np.pi * nota(n) * x) + 0.3 * np.sin(2 * np.pi * nota(n) * 2.003 * x)
            env = np.minimum(1, np.minimum(x / 0.4, (dur - x) / 0.4))
            out[int(inicio * FS) : int(inicio * FS) + len(x)] += pad * env * 0.06
        # Bajo
        b = tono(nota(acorde[0] - 12), dur * 0.9, "seno", ataque=0.02, caida=dur * 0.6, vol=0.22)
        out[int(inicio * FS) : int(inicio * FS) + len(b)] += b
    corchea = negra / 2
    for i, n in enumerate(melodia):
        if n is None:
            continue
        s = tono(nota(n), 0.7, "marimba", caida=0.35, vol=0.16 * brillo)
        j = int(i * corchea * FS) % int(total * FS)
        fin = min(j + len(s), len(out))
        out[j:fin] += s[: fin - j]
    # Lo que sobresale del final se suma al inicio para que el loop no tenga corte.
    largo = int(total * FS)
    out[: len(out) - largo] += out[largo:]
    return out[:largo]


def musica() -> None:
    # Escala pentatónica de Do: tranquila y "de naturaleza".
    p = [60, 62, 64, 67, 69, 72, 74, 76, 79, 81]
    acordes = [[48, 55, 64], [45, 52, 60], [41, 48, 57], [43, 50, 59]]
    mel = []
    for c in range(4):
        for k in range(16):
            mel.append(None if rng.random() < 0.35 else int(rng.choice(p[3 + (c % 2) : 9])))
    guardar(MUSICA / "valle.wav", pieza(acordes, mel, 84, compases_por_acorde=1), 0.6)
    # Río: un poco más movida.
    mel2 = []
    for c in range(8):
        for k in range(8):
            mel2.append(int(p[(k * 2 + c) % len(p)]) if k % 3 != 2 else None)
    guardar(MUSICA / "rio.wav", pieza([[50, 57, 66], [45, 52, 61], [47, 54, 62], [43, 50, 59]], mel2, 96,
                                     compases_por_acorde=2, brillo=0.9), 0.6)
    # Puzzle: pensativa, lenta, pocas notas.
    mel3 = [None] * 64
    for k in range(0, 64, 3):
        mel3[k] = int(rng.choice(p[2:7]))
    guardar(MUSICA / "puzzle.wav", pieza([[45, 52, 60], [41, 48, 57], [43, 50, 55], [40, 47, 55]], mel3, 70,
                                        compases_por_acorde=2, brillo=0.7), 0.55)


if __name__ == "__main__":
    efectos()
    musica()
    print("Audio generado en", SFX.parent)

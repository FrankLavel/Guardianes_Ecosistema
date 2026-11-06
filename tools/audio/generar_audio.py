"""Genera los efectos de sonido y los ambientes de naturaleza del juego (síntesis con numpy).

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


# ------------------------------------------------------------------ ambiente de naturaleza
# En lugar de música, cada lugar suena a su ecosistema: viento, agua, pájaros, grillos...
# Son loops de DURACION segundos que empatan al repetirse.
DURACION = 45.0
CRUCE = 3.0


def filtrar(s: np.ndarray, bajo: float, alto: float) -> np.ndarray:
    """Pasa banda por FFT (bajo/alto en Hz)."""
    f = np.fft.rfftfreq(len(s), 1 / FS)
    espectro = np.fft.rfft(s)
    espectro[(f < bajo) | (f > alto)] = 0
    return np.fft.irfft(espectro, len(s))


def lfo(n: int, velocidad: float, minimo: float) -> np.ndarray:
    """Variación lenta y suave entre `minimo` y 1 (ráfagas de viento, oleaje)."""
    puntos = rng.uniform(0, 1, int(n / FS * velocidad) + 3)
    x = np.linspace(0, len(puntos) - 1, n)
    suave = np.interp(x, np.arange(len(puntos)), puntos)
    # Promedio móvil de medio segundo (con suma acumulada: convolve era lentísimo).
    ancho = FS // 2
    acumulado = np.cumsum(np.pad(suave, (ancho // 2, ancho - ancho // 2)))
    suave = (acumulado[ancho:] - acumulado[:-ancho]) / ancho
    return minimo + (1 - minimo) * suave


def viento(n: int, bajo=60.0, alto=600.0, vol=0.25) -> np.ndarray:
    return filtrar(rng.normal(0, 1, n), bajo, alto) * lfo(n, 0.15, 0.25) * vol


def corriente(n: int, vol=0.3) -> np.ndarray:
    """Río: rumor de agua y burbujeo."""
    # Agua grave (rumor) y un poco de brillo arriba; sin agudos para que no suene a estática.
    s = (filtrar(rng.normal(0, 1, n), 120, 900) + 0.35 * filtrar(rng.normal(0, 1, n), 900, 2200)) * lfo(n, 0.6, 0.7) * vol
    for _ in range(int(n / FS * 9)):
        f0 = rng.uniform(500, 1400)
        gota = tono(np.linspace(f0, f0 * 1.6, int(FS * 0.06)), 0.06, "seno", 0.003, 0.02, 0.05)
        i = rng.integers(0, n - len(gota))
        s[i : i + len(gota)] += gota
    return s


def olas(n: int, vol=0.35) -> np.ndarray:
    """Lago: olas suaves que llegan a la orilla cada 5-8 s."""
    s = filtrar(rng.normal(0, 1, n), 100, 1800)
    env = np.zeros(n)
    i = 0
    while i < n:
        largo = int(FS * rng.uniform(2.5, 4.0))
        x = np.linspace(0, np.pi, min(largo, n - i))
        env[i : i + len(x)] += np.sin(x) ** 2
        i += int(FS * rng.uniform(5, 8))
    return s * (0.15 + env) * vol


def pajaros(n: int, por_minuto=14, vol=0.12, apagado=False) -> np.ndarray:
    """Cantos variados: silbido de dos notas, trino rápido y gorjeo que baja."""
    s = np.zeros(n)
    for _ in range(int(n / FS / 60 * por_minuto)):
        tipo = rng.integers(0, 3)
        base = rng.uniform(2200, 4200)
        canto = []
        if tipo == 0:
            for f in (base, base * 0.8):
                canto.append(tono(np.linspace(f, f * 1.05, int(FS * 0.18)), 0.18, "seno", 0.02, 0.1, 1))
                canto.append(np.zeros(int(FS * 0.06)))
        elif tipo == 1:
            for _k in range(rng.integers(6, 12)):
                canto.append(tono(np.linspace(base * 1.2, base, int(FS * 0.05)), 0.05, "seno", 0.004, 0.02, 1))
                canto.append(np.zeros(int(FS * 0.025)))
        else:
            for k in range(4):
                f = base * (1 - k * 0.12)
                canto.append(tono(np.linspace(f * 1.3, f, int(FS * 0.09)), 0.09, "seno", 0.005, 0.04, 1))
                canto.append(np.zeros(int(FS * 0.05)))
        c = np.concatenate(canto) * vol * rng.uniform(0.4, 1.0)
        i = rng.integers(0, n - len(c))
        s[i : i + len(c)] += c
    return filtrar(s, 200, 2500) * 0.8 if apagado else s


def grillos(n: int, vol=0.06) -> np.ndarray:
    s = np.zeros(n)
    x = np.arange(n) / FS
    for f, ritmo in ((4300, 2.1), (4700, 2.6), (5100, 1.7)):
        pulsos = (np.sin(2 * np.pi * 28 * x) > 0.3) * (np.sin(2 * np.pi * ritmo * x + rng.uniform(0, 6)) > 0.55)
        suave = np.convolve(pulsos.astype(float), np.ones(60) / 60, mode="same")
        s += np.sin(2 * np.pi * f * x) * suave * vol
    return s


def ranas(n: int, por_minuto=10, vol=0.18) -> np.ndarray:
    s = np.zeros(n)
    for _ in range(int(n / FS / 60 * por_minuto)):
        f = rng.uniform(180, 320)
        croar = []
        for _k in range(rng.integers(2, 4)):
            x = t(0.16)
            pulso = np.sign(np.sin(2 * np.pi * f * x)) * (np.sin(2 * np.pi * 35 * x) > 0)
            croar.append(filtrar(pulso, 150, 1200) * envolvente(len(x), 0.01, 0.08))
            croar.append(np.zeros(int(FS * 0.12)))
        c = np.concatenate(croar) * vol
        i = rng.integers(0, n - len(c))
        s[i : i + len(c)] += c
    return s


def carpintero(n: int, veces=3, vol=0.3) -> np.ndarray:
    s = np.zeros(n)
    for _ in range(veces):
        golpe = filtrar(rng.normal(0, 1, int(FS * 0.02)), 600, 2500) * envolvente(int(FS * 0.02), 0.001, 0.005)
        i = rng.integers(0, n - FS * 2)
        for k in range(rng.integers(10, 18)):
            j = i + int(k * FS / 17)
            s[j : j + len(golpe)] += golpe * vol * (1 - k * 0.03)
    return s


def loop(partes) -> np.ndarray:
    """Suma las capas y cruza el final con el principio para que el loop no tenga corte."""
    n = int(FS * (DURACION + CRUCE))
    s = sum(capa(n) for capa in partes)
    largo, cruce = int(FS * DURACION), int(FS * CRUCE)
    rampa = np.linspace(0, 1, cruce)
    s[:cruce] = s[:cruce] * np.sqrt(rampa) + s[largo:] * np.sqrt(1 - rampa)
    return s[:largo]


def ambiente() -> None:
    # Volumen (RMS) de cada lugar: la casa es tranquila, el río y el valle más vivos.
    lugares = {
        "valle": [viento, pajaros],
        "valle_noche": [lambda n: viento(n, vol=0.15), grillos],
        "rio": [corriente, lambda n: pajaros(n, 10), lambda n: viento(n, vol=0.1)],
        "bosque": [lambda n: viento(n, 150, 2500, 0.3), lambda n: pajaros(n, 18), carpintero],
        "lago": [olas, ranas, lambda n: pajaros(n, 8)],
        "casa": [lambda n: viento(n, 60, 300, 0.05), lambda n: pajaros(n, 8, apagado=True)],
        "casa_noche": [lambda n: viento(n, 60, 300, 0.04), lambda n: filtrar(grillos(n), 200, 3000) * 0.6],
    }
    volumen = {"valle": 0.08, "valle_noche": 0.06, "rio": 0.09, "bosque": 0.08, "lago": 0.07,
               "casa": 0.035, "casa_noche": 0.03}
    for nombre, capas in lugares.items():
        s = loop(capas)
        s *= volumen[nombre] / np.sqrt(np.mean(s ** 2))
        # guardar() normaliza al pico: se le pasa el pico que ya trae para conservar el volumen.
        guardar(MUSICA / f"{nombre}.wav", s, min(0.95, float(np.max(np.abs(s)))))
    (MUSICA / "puzzle.wav").unlink(missing_ok=True)
    (MUSICA / "puzzle.wav.import").unlink(missing_ok=True)


if __name__ == "__main__":
    efectos()
    ambiente()
    print("Audio generado en", SFX.parent)

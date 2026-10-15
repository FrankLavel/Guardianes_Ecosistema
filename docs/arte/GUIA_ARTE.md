# Guía de arte con IA — Guardianes del Último Ecosistema

Esta guía es para que el equipo genere el arte con la misma herramienta de IA que usó para la hoja de Gara. Yo (programación) recorto, limpio e integro cada imagen en Godot.

> **Regla de oro:** todo debe verse como si lo hubiera dibujado la misma persona que dibujó a Gara.
> Adjunten **siempre** la hoja de Gara (`assets/characters/gara/fuente/gara_sprite_sheet_original.jpg`) como imagen de referencia de estilo.

---

## 1. Reglas técnicas (para que se pueda usar en el juego)

| Regla | Por qué |
|---|---|
| **Fondo plano de un solo color**: magenta puro `#FF00FF` (o blanco liso si la herramienta no obedece). | Así se quita el fondo de forma automática y limpia. |
| **Sin cuadrícula, sin textos, sin etiquetas, sin logos.** | La hoja de Gara traía cuadrícula y textos y hubo que limpiarlos a mano. |
| **Separación de al menos 40 px** entre objetos o cuadros. | Para recortarlos sin que se peguen. |
| **PNG** (no JPG) y la **resolución más alta** disponible. | El JPG ensucia los bordes. |
| En animaciones: **todos los cuadros del mismo tamaño, alineados en una fila** y mirando **a la derecha**. | Para que la animación no "brinque". |
| Tamaño relativo: **Gara mide ≈ 150 px** en su hoja. Mantener esa escala (un árbol ≈ 3× Gara, una lata ≈ 1/5 de Gara). | Para que todo combine en pantalla. |
| Los fondos (paisajes) van **por capas separadas**, sin personajes. | Para el efecto de profundidad (paralaje). |

### Cómo entregarlo
Suban cada imagen a la carpeta `assets/fuente_ia/` del repositorio (o pásenmelas en el chat) con el **nombre de archivo indicado** en la lista. Si una imagen sale mal (estilo distinto, cortada, con texto), regenérenla antes de enviarla; mejor 1 buena que 4 regulares.

---

## 2. Bloque de estilo (pegar al inicio de **cada** prompt)

```
High-detail HD pixel art game asset, same art style as the attached character reference
(Gara): clean dark outlines, soft cel shading, vibrant natural greens and earthy browns,
Mexican highland nature (Michoacán). Plain flat solid magenta #FF00FF background,
no grid, no text, no labels, no watermark, no drop shadow on the background.
```

---

## 3. Lista de arte — Sprint 1 (para el 27 de octubre)

Prioridad: 🔴 imprescindible · 🟡 importante · 🟢 si da tiempo

### 3.1 Gara en el mapa aéreo
🔴 `gara_aerea.png`
```
[BLOQUE DE ESTILO] Top-down 3/4 view RPG character sprite sheet of the same girl (Gara):
4 rows (walking down, walking left, walking right, walking up), 4 frames per row,
all frames the same size and evenly spaced, full body visible, small shadow under feet.
```

### 3.2 Mapa aéreo del Valle
🔴 `valle_tileset.png`
```
[BLOQUE DE ESTILO] Top-down 3/4 view RPG tileset, seamless square tiles evenly spaced in a
grid: grass (3 variations), dirt path (straight, corner, crossing), river water with
grass edges (straight, corner), wooden bridge, shallow lake shore, stone path.
```
🔴 `valle_objetos.png`
```
[BLOQUE DE ESTILO] Top-down 3/4 view RPG objects, each separate with space between them:
oyamel fir tree, pine tree, oak tree, bush with flowers, big rock, small rocks, wooden
fence pieces, wooden sign post, small adobe house with red tile roof (Purépecha style),
wooden pier, old rusty pipe dripping dark water, cut tree stump.
```
🟡 `valle_entradas.png` — tres arcos/portales de entrada a zona: uno de piedra con agua (río), uno de troncos con mariposas (bosque), uno de tule y piedra junto al lago.

### 3.3 Zona 1: nivel de plataformas (río)
🔴 `zona1_plataformas.png`
```
[BLOQUE DE ESTILO] Side-view 2D platformer level pieces, each separate with space between
them: large grassy ground block with dirt and rocks underneath (wide), medium floating
grassy island, small floating grassy island, wooden log platform, mossy stone pillar,
grassy slope piece, riverbank edge with reeds (left and right versions).
```
🔴 `zona1_fondo_cielo.png`, `zona1_fondo_montanas.png`, `zona1_fondo_arboles.png` (3 capas, formato **panorámico 3:1**)
```
[BLOQUE DE ESTILO] Side-view parallax background layer for a 2D platformer, wide panoramic
3:1, only [sky with soft clouds at dawn | distant blue-green mountains of Michoacán |
forest tree line of pines and oyamel firs], no characters, no ground in front.
```
🔴 Las mismas 3 capas en **versión contaminada** (`..._contaminado.png`): `same image but polluted: grey hazy sky, dull brown dry trees, smog`.
🔴 `zona1_objetos.png`
```
[BLOQUE DE ESTILO] Side-view 2D platformer objects, each separate with space between
them: plastic bottle, crushed soda can, plastic bag, used battery, styrofoam cup, rusty
drain pipe pouring dark polluted water, metal valve wheel (open and closed versions),
pushable wooden log, small glowing sapling (checkpoint), big healthy tree (goal),
wooden fishing boat, toxic dark puddle.
```
🟡 `zona1_animales.png`
```
[BLOQUE DE ESTILO] Side-view 2D sprite sheet, animals of a Mexican river, each in its own
row, 4 frames per row, facing right: swimming crayfish (acocil), white heron walking,
kingfisher flying, small silver fish swimming.
```
🟡 `don_chucho.png` — personaje: pescador mayor michoacano con sombrero de palma y red; vista lateral (idle 2 cuadros, hablar 2 cuadros) + **retrato** de cara para diálogos (`don_chucho_retrato.png`).

### 3.4 Puzzle del filtro de agua
🟡 `puzzle_filtro.png`
```
[BLOQUE DE ESTILO] Game UI puzzle pieces, front view, each separate: tall transparent
glass bottle cut in half (empty water filter), layer of gravel, layer of sand, layer of
activated charcoal, layer of cotton, dirty brown water drop, clean blue water drop.
```

### 3.5 Interfaz
🟡 `ui_elementos.png`
```
[BLOQUE DE ESTILO] Game UI kit in the same style: wooden panel frame with leaf corners
(large and small), green rounded button (normal, hover, pressed), heart icon, leaf icon,
water drop icon, trash bag icon, open book icon (journal), pause icon, close icon.
```
🟢 `logo.png` — el logo "Guardianes del Último Ecosistema" que ya aparece en la hoja de Gara, **solo**, grande y sobre fondo magenta.

---

## 4. Sprints siguientes (resumen; se detallan al llegar)
- **Sprint 2:** Zona 2 — bosque de oyamel (plataformas, fondos sano/talado, enredaderas que crecen en 4 cuadros, mariposas monarca, venado, pájaro carpintero, Mari la mariposa).
- **Sprint 3:** Zona 3 — lago de Pátzcuaro (agua profunda, tule, lirio, achoque nadando, pato, pescado blanco, Achi), puzzles de cadena alimenticia y separación de residuos.
- **Sprint 4:** final (valle completamente vivo), portada para itch.io.

---

## 5. Lista de revisión antes de entregar una imagen
- [ ] ¿Se ve del mismo estilo que Gara?
- [ ] ¿Fondo de un solo color, sin cuadrícula ni texto?
- [ ] ¿Nada está cortado en los bordes?
- [ ] ¿Los cuadros de animación son del mismo tamaño y miran a la derecha?
- [ ] ¿Nombre de archivo correcto?

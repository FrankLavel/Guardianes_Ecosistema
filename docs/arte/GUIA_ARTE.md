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

### 3.6 Niña para los niveles de plataformas (pendiente)
🔴 `nina_plataformas.png` — la niña (la de `npc_aldeana_aerea.jpg`) vista de **lado**, para los niveles de plataformas. Mientras no exista, en los niveles se ve al niño.
*(Adjuntar `npc_aldeana_aerea.jpg` y la hoja de Gara como referencia)*
```
[BLOQUE DE ESTILO] Side-view 2D platformer character sprite sheet of the same girl from the
attached reference (long black braids, green embroidered blouse, brown skirt, cloth bag,
sandals), same size and proportions as the boy in the other attached sheet. All frames facing
RIGHT, full body, same size, evenly spaced with plenty of space between them, in rows:
row 1: idle (2 frames); row 2: walk (6 frames); row 3: run (6 frames);
row 4: jump up, falling, crouching, kneeling and reaching forward with one hand (interact).
Plain flat solid magenta #FF00FF background, no grid, no text, no labels, no watermark.
```

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

---

## 6. Cómo se integra el arte (programación)

1. Las imágenes originales viven en `assets/fuente_ia/` (Godot las ignora).
2. `python tools/arte/procesar.py` quita el fondo magenta, separa cada objeto, arma las animaciones y deja los PNG en `assets/` (personajes, mapas, objetos, interfaz).
3. Si se regenera una imagen, se reemplaza con **el mismo nombre** y se vuelve a ejecutar el script. Si cambia la cantidad u orden de objetos en una hoja, el script avisa y hay que ajustar la lista de nombres en `procesar.py`.

---

## 7. Lista de arte — Sprint 3 (Zona 2: bosque de oyamel)

Hoy el nivel funciona con arte **provisional** (enredadera, tierra fértil y venado dibujados por código; el pájaro carpintero aparece como "?"). Al reemplazarlos con estos, el juego toma el arte nuevo sin cambiar código.

🔴 `zona2_objetos.png`
```
[BLOQUE DE ESTILO] Side-view 2D platformer objects, each separate with plenty of space between
them: a tall climbing green vine with leaves (seamless vertically, about 3 times taller than wide),
a small mound of dark fertile soil with tiny sprouts, a campfire with burning logs, the same
campfire put out and smoking, an old rusty barbed wire fence piece, a wooden sign of a tree nursery.
```
🔴 `zona2_venado.png`
```
[BLOQUE DE ESTILO] Side-view 2D sprite sheet of a white-tailed deer facing right, one row,
evenly spaced: 2 frames standing, 4 frames running. Same scale as the boy character
(the deer is a bit taller than him). No text, no grid.
```
🔴 `zona2_carpintero.png`
```
[BLOQUE DE ESTILO] Acorn woodpecker (Melanerpes formicivorus) clinging to a tree trunk, side view,
facing right, red cap, black and white face, alone and centered.
```
🟡 `zona2_monarca_vuelo.png`
```
[BLOQUE DE ESTILO] Monarch butterfly flying, side view, one row of 4 frames of the wings flapping,
evenly spaced, facing right.
```
🟡 `mari_retrato.png` — retrato de Mari (mariposa monarca con carita amigable y ojos grandes, estilo caricatura), de frente, para los diálogos.
🟡 `zona2_plataformas.png` — mismas piezas que `zona1_plataformas` pero de **bosque de montaña**: tierra más oscura, agujas de pino en el pasto, raíces y piedras con musgo.
🟢 Animación de **trepar** para el niño y la niña (vista de espaldas subiendo una enredadera, 4 cuadros).

---

## 8. Lista de arte — Sprint 4 (Zona 3: lago de Pátzcuaro)

✅ **Integrado** (19 oct). Se procesa con `python tools/arte/procesar.py zona3`.

🔴 `zona3_achoque.png` — Achi, el achoque (ajolote de Pátzcuaro): café-morado con branquias rosas, carita amigable; de lado mirando a la derecha: 2 cuadros quieto, 4 nadando. Además, **retrato** de frente para los diálogos (`achi_retrato.png`).
🔴 `zona3_objetos.png` — huevo de achoque (gelatinoso, transparente), lirio acuático flotando con flor morada, tule (varias cañas con espigas cafés), muelle de madera, canoa de pescador de Pátzcuaro.
🟡 `zona3_animales.png` — pato mexicano de lado (2 cuadros) y pescado blanco de lado (casi transparente, 2 cuadros).
🟡 `zona3_fondo_lago.png` (3:1) — el lago de Pátzcuaro de fondo con la isla de Janitzio a lo lejos, sin personajes; y la misma imagen **contaminada** (`zona3_fondo_lago_contaminado.png`): agua verde cubierta de lirio, cielo gris.
🟡 `zona3_cadena.png` — íconos para el puzzle de la cadena alimenticia, cada uno separado: sol con carita, plantas acuáticas, larva de insecto acuático (libélula joven).
🟡 `zona3_residuos.png` — cáscara de plátano, hoja de papel arrugada, frasco de vidrio, y 5 contenedores de basura de colores (verde, amarillo, azul, gris, rojo).

Todos con el **bloque de estilo** de la sección 2 y fondo magenta.

## 9. Arte de "después del final" (integrado)

| Archivo en `assets/fuente_ia/` | Qué es | Resultado en el juego |
|---|---|---|
| `valle_venado.jpg`, `valle_garza.jpg`, `valle_pato.jpg` | 2 filas: 4 cuadros caminando a la derecha; quieto, comiendo, descansando y la cría | `assets/characters/animales/valle/<especie>_frames.tres` |
| `valle_monarca.jpg` | 8 cuadros volando | `assets/characters/animales/valle/monarca_frames.tres` |
| `casa_interior.jpg` | cuarto vacío (vista 3/4) | `assets/maps/casa/interior.png` |
| `casa_muebles.jpg` | cama, repisa (2 tablas), tablero, baúl, alfombra, lámpara, pecera, maceta | `assets/maps/casa/<mueble>.png` |

Se procesan con `python tools/arte/procesar.py animales_valle casa`.

### Pendiente (opcional)
**`casa_cuadro.png`** — hoy el cuadro de la monarca es un marco dibujado con código. Pegar el bloque de estilo y:
```
Top-down 3/4 RPG view, a small wooden picture frame hanging on a wall with a painting of a monarch butterfly on an oyamel branch, alone and centered.
```

## 10. Granja y cocina (arte provisional hecho con código)

Hoy los íconos, las plantas de la milpa, el fogón, la gallina y la cabra son provisionales
(`python tools/arte/iconos_granja.py`). Para cada hoja: pegar el bloque de estilo al inicio y
adjuntar `valle_objetos.jpg` como referencia.

**`granja_iconos.png`** — íconos de objetos
```
Inventory icons for a farming game, top-down 3/4 RPG style, each icon separate with plenty of space, same size, in 4 rows: ear of corn, three brown beans, orange pumpkin, white egg, small bottle of goat milk, gray fish, chamomile flower, mint sprig, nopal cactus pad, bundle of firewood, three small cloth seed bags (one with a corn kernel, one with a bean, one with a pumpkin seed).
```

**`granja_platillos.png`** — platillos michoacanos
```
Mexican food icons in clay plates and clay cups, each separate with plenty of space, same size: grilled corn on the cob, cup of atole, eggs with beans, three corundas (triangular Michoacán tamales), bowl of sopa tarasca (bean soup), candied pumpkin, grilled nopal pads, grilled fish with mint leaves, cup of chamomile tea.
```

**`granja_milpa.png`** — plantas en 4 etapas
```
Crop growth stages on small mounds of dark soil, top-down 3/4 RPG view, 3 rows of 4 stages each (seed just planted, small sprout, growing plant, ready to harvest): row 1 corn, row 2 bean plant climbing a stick, row 3 pumpkin vine with a ripe orange pumpkin at the last stage. Same scale.
```

**`granja_corral.png`** — gallina, cabra y fogón
```
Top-down 3/4 RPG view, each separate with plenty of space: 1) a hen walking to the RIGHT, 4 frames; 2) a white and brown goat walking to the RIGHT, 4 frames; 3) a traditional Mexican clay wood stove (fogón) with a round black comal on top and fire inside, seen from the front.
```


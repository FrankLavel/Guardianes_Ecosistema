# Guardianes del Último Ecosistema — Documento de diseño (GDD)

> Versión 0.1 · 14 de octubre de 2026 · Motor: Godot 4.7
> Público: 3.º de primaria · Área: Ciencias Naturales y educación ambiental
> Entrega: ~14 de diciembre de 2026 (8 semanas) con el juego **completo al 100 %**

---

## 1. Concepto

El **Valle de Tzintzun**, inspirado en la región lacustre de Michoacán, es el último ecosistema sano de la zona… hasta ahora. Una fábrica abandonada contaminó el río, se taló el bosque de oyamel y el lago donde vive el **achoque** (ajolote de Pátzcuaro) se está enfermando.

El jugador es **el nuevo guardián o la nueva guardiana** del valle: al empezar elige **niño o niña** y escribe su nombre. Debe recorrer el valle, entender qué le pasó a cada lugar y **restaurarlo** resolviendo problemas reales: filtrar agua, cerrar fuentes de contaminación, reforestar con árboles nativos y reconstruir la cadena alimenticia.

> Los textos nunca suponen el género: se escriben con marcadores (`{guardian}`, `{muchacho}`, `{el}`, `{nuevo}`, `{nombre}`) que el juego cambia según el personaje elegido.

**Lema de diseño:** *el jugador no responde preguntas: arregla el ecosistema usando lo que aprende.*

### Pilares
| Pilar | Qué significa en el juego |
|---|---|
| **Explorar** | Mapa aéreo vivo que cambia de gris a colorido conforme se restaura. |
| **Resolver** | Cada zona tiene puzzles basados en ciencia real (no trivia). |
| **Restaurar** | Cada acción tiene un efecto visible: el agua se aclara, vuelven los animales, crecen plantas. |
| **Descubrir** | Bitácora de especies que se llena al encontrar y ayudar a los seres vivos. |

---

## 2. Estructura del juego

```
Menú principal
   └── Valle (mapa aéreo, vista desde arriba)  ← centro del juego
         ├── Zona 1: Río Cupatitzio (agua contaminada)   → nivel de plataformas + 2 puzzles
         ├── Zona 2: Bosque de oyamel (deforestación)    → nivel de plataformas + 2 puzzles
         ├── Zona 3: Lago de Pátzcuaro (hábitat del achoque) → nivel de plataformas + 2 puzzles
         └── Final: El Corazón del Valle                  → secuencia final y créditos
```

- Las zonas se **desbloquean en orden**; cada una da una **habilidad** necesaria para la siguiente.
- Al terminar una zona, su parte del mapa aéreo **se restaura visualmente** (paleta gris → colorida, aparecen animales).
- Duración objetivo: **45–60 minutos** para completar todo.

### Dos vistas
| | Mapa aéreo (Valle) | Niveles de plataformas |
|---|---|---|
| Cámara | Desde arriba (3/4) | Lateral |
| Personaje (niño o niña) | Camina en 4 direcciones | Corre, salta, interactúa |
| Se hace | Hablar con personajes, puzzles de lógica, encontrar objetos, entrar a zonas | Recorrido con obstáculos, rescates, puzzles físicos |

---

## 3. Mecánicas

### Comunes
- **Interactuar (E):** recoger, hablar, activar palancas/compuertas, plantar.
- **Bitácora (Tab):** fichas de especies (foto, nombre común, dato, estado de conservación).
- **Salud de la zona:** barra que sube con cada acción de restauración.
- **Guardado automático** al entrar/salir de zonas; 3 ranuras de partida (CP-09, CP-10).
- **Pausa (Esc):** continuar, opciones, bitácora, volver al valle, salir (CP-11).

### Plataformas (ya existe la base)
Correr, saltar con tiempo coyote, puntos de control, interactuar. Se agregan:
- **Empujar cajas/troncos** (puzzles físicos).
- **Nadar** (habilidad de la Zona 1: solo en agua limpia).
- **Plantar enredaderas** (habilidad de la Zona 2: crean plataformas temporales).

### Mapa aéreo
Movimiento en 4 direcciones, colisiones con árboles/rocas, entradas a zonas, personajes con diálogo, objetos coleccionables (semillas, fichas de especies).

### Diálogos
Cajas de texto cortas (máx. 2 líneas, lenguaje de 8–9 años), retrato del personaje, avanzar con E.

---

## 4. Zonas

### Zona 1 — Río Cupatitzio · *El agua es vida*
**Problema:** una tubería vierte agua sucia y hay basura en las orillas.
**Personaje guía:** Don Chucho, pescador.

| Parte | Contenido |
|---|---|
| Nivel de plataformas | Recorrer el río hasta la tubería: recoger basura (ya implementado), esquivar charcos tóxicos, empujar troncos para cruzar. |
| **Puzzle 1 — Compuertas** | Abrir/cerrar 3 compuertas para que el agua sucia vaya a la planta de tratamiento y la limpia siga al río. |
| **Puzzle 2 — Filtro de agua** (mapa aéreo) | Ordenar capas en un filtro: grava → arena → carbón → algodón, y ver salir el agua clara. |
| Recompensa | Habilidad **nadar** · fichas: acocil, garza blanca, martín pescador. |

**Aprende:** el agua contaminada enferma a los seres vivos; el agua se puede limpiar y debe cuidarse.

### Zona 2 — Bosque de oyamel · *Los árboles nos dan hogar*
**Problema:** tala; las mariposas monarca ya no tienen dónde pasar el invierno.
**Personaje guía:** Mari, una mariposa monarca.

| Parte | Contenido |
|---|---|
| Nivel de plataformas | Subir la montaña usando enredaderas que el personaje planta; apagar una fogata mal apagada; rescatar a un venado atorado. |
| **Puzzle 3 — Reforestar** | Elegir el árbol correcto para cada suelo/altura (oyamel arriba, pino-encino en medio) y plantarlos. |
| **Puzzle 4 — ¿Quién vive aquí?** | Llevar a cada animal a su hábitat del bosque (copa, tronco, suelo). |
| Recompensa | Habilidad **plantar enredaderas** · fichas: mariposa monarca, oyamel, venado cola blanca, pájaro carpintero. |

**Aprende:** los árboles son hogar y alimento; un ecosistema necesita de todos sus seres vivos.

### Zona 3 — Lago de Pátzcuaro · *El último achoque*
**Problema:** el lago tiene basura, lirio invasor y casi no quedan achoques.
**Personaje guía:** Achi, el último achoque.

| Parte | Contenido |
|---|---|
| Nivel de plataformas | Tramos nadando (habilidad Zona 1) y plantando (habilidad Zona 2); quitar lirio que tapa la luz; rescatar huevos de achoque. |
| **Puzzle 5 — Cadena alimenticia** | Reconstruir: sol → plantas acuáticas → insectos → achoque → garza. Si falta un eslabón, la cadena se rompe. |
| **Puzzle 6 — Separar residuos** | Clasificar la basura del lago: orgánica, plástico, papel, vidrio/metal, peligrosa (pilas). |
| Recompensa | Fichas: achoque, pato mexicano, pescado blanco, tule. |

**Aprende:** todo en el ecosistema está conectado; separar residuos protege el agua.

### Final — El Corazón del Valle
Todas las zonas restauradas. El guardián o la guardiana lleva los huevos de achoque al lago limpio; secuencia final con el valle completamente vivo, resumen de lo aprendido y créditos.

### Después del final — El valle sigue vivo
Al terminar, el juego no se acaba: desde la pantalla final se puede **seguir explorando** el valle.

- **Animales libres.** Venados, garzas, patos y mariposas monarca pasean por el valle. Cada especie aparece cuando su zona se restaura (garza → río; venado y monarca → bosque; pato → lago). Se puede hablar con ellos: cuentan un dato de su especie. Achi vive en un estanque junto al arco del lago.
- **Pedidos de ayuda.** Cada 25–50 s un animal camina hacia el guardián con un **!** y explica su problema:
  | Pedido | Quién lo pide | Qué se hace | Recompensa |
  |---|---|---|---|
  | Basura | venado, garza, pato | recoger 3 basuras cerca del animal | 5 hojas |
  | Cría perdida | venado, pato | encontrar la cría, que te sigue hasta su mamá | 8 hojas |
  | Arbolitos | venado, monarca | plantar 2 arbolitos | 6 hojas |
  | Flores | monarca | plantar 3 flores con néctar | 6 hojas |

  El pedido en curso se guarda en la partida. Los textos están en `data/pedidos.json`.
- **Granja (fase 1, inspirada en Green Farm 3).** Milpa que crece en minutos después de regarla, niveles con experiencia (cosechar, cocinar, pescar, recolectar, ayudar animales y entregar pedidos) que desbloquean surcos (6 → 9 → 12), la cabra, recetas y más pedidos, y un **tianguis** con pedidos de la gente del valle y venta de semillas. Datos en `data/granja.json`.
- **La casa del guardián (base).** Se entra por la puerta de la casa de adobe:
  - **Cama:** guarda la partida y cambia entre día y noche.
  - **Repisa de trofeos:** zonas restauradas, especies de la bitácora e insignias por tipo de ayuda (Bronce 1, Plata 3, Oro 6).
  - **Tablero:** el pedido en curso, su avance y su recompensa.
  - **Baúl:** muebles que se compran con hojas (maceta, tule, alfombra, lámpara, cuadro de la monarca, pecera con achoque) y aparecen en el cuarto.

---

## 5. Contenido educativo (correspondencia con los objetivos)

| Objetivo del proyecto | Dónde se cumple |
|---|---|
| Comprender qué es un ecosistema y sus componentes | Puzzles 4 y 5, bitácora, pantalla final de cada zona |
| Identificar cómo la contaminación del agua afecta a los seres vivos | Zona 1 completa, Zona 3 (lirio, basura) |
| Reconocer la importancia de proteger los hábitats | Zonas 2 y 3, restauración visual del mapa |
| Desarrollar conciencia ambiental y responsabilidad | Puzzle 6, mensajes de cierre, datos de basura, pedidos de ayuda de los animales después del final |

Todos los textos educativos viven en `data/` (JSON) para que el equipo y docentes puedan revisarlos sin tocar código. **Cada dato debe validarse antes de la versión 1.0.**

---

## 6. Arte y audio

- **Estilo:** pixel art de alta definición, igual que los personajes (niño y niña) (contornos oscuros, sombreado suave, colores naturales vivos).
- **Origen:** generado con IA por el equipo siguiendo `docs/arte/GUIA_ARTE.md`; integración y limpieza en el proyecto.
- **Efectos en Godot (sin arte extra):** fondos con paralaje (profundidad), shader de agua con reflejos y ondas, partículas (hojas, polvo, chispas de restauración), iluminación 2D, transición gris → color al restaurar, temblores y "juice" en interacciones.
- **Audio:** en lugar de música, sonido de ambiente de naturaleza en cada lugar (valle con pájaros y viento, río con agua corriendo, bosque con viento entre los árboles y un pájaro carpintero, lago con olas y ranas, casa tranquila; grillos de noche) y efectos (pasos, salto, agua, recoger, puzzle resuelto). Fuente: bibliotecas con licencia libre (CC0) — se documenta la licencia de cada archivo en `assets/audio/CREDITOS.md`.

---

## 7. Alcance: qué significa "100 % completo"

La versión **1.0.0** está completa cuando:
- [ ] Se puede jugar de principio a fin: menú → valle → 3 zonas → final → créditos.
- [ ] 6 puzzles funcionando y con retroalimentación clara.
- [ ] Todo el arte provisional reemplazado por arte final.
- [ ] Música y efectos de sonido en todas las escenas.
- [ ] Guardar/cargar, pausa, opciones (volumen, pantalla completa).
- [ ] Bitácora con todas las especies (≈ 15 fichas) y datos validados.
- [ ] Pasa todos los casos CP-01 a CP-14 del plan de pruebas y ≥ 30 FPS en las PCs de la escuela.
- [ ] Publicado en itch.io (Windows y Web).

**Fuera de alcance** (para no arriesgar la entrega): multijugador, más de 3 zonas, voces grabadas, idiomas además del español.

---

## 8. Plan de trabajo (sprints de 2 semanas)

| Sprint | Fechas | Programación | Arte (equipo, con IA) |
|---|---|---|---|
| **1** | 14 – 27 oct | Mapa aéreo (movimiento 4 direcciones, colisiones, entradas a zonas), transiciones, estado de partida y guardado, diálogos, pausa | Personajes en vista aérea (niño y niña), tileset del valle, tileset y fondos de la Zona 1, objetos Zona 1 |
| **2** | 28 oct – 10 nov | **Zona 1 completa y pulida** (nivel nuevo, puzzles 1–2, nadar, efectos de agua, paralaje, audio) = *demo vertical* | Personajes y animales Zona 1, UI, arte Zona 2 |
| **3** | 11 – 24 nov | Zona 2 completa (enredaderas, puzzles 3–4), bitácora | Arte Zona 3 |
| **4** | 25 nov – 8 dic | Zona 3 + final + créditos (puzzles 5–6) | Arte del final, retoques |
| **Cierre** | 9 – 14 dic | Pruebas CP-01…CP-14, corrección de errores, balance, publicación 1.0.0 en itch.io | Capturas y portada para itch.io |

Riesgo principal: **el arte**. Si una hoja de sprites llega tarde, se trabaja con el provisional y se reemplaza al llegar; el código no depende del arte final.

---

## 9. Qué se reutiliza de lo ya hecho
Movimiento y animaciones del personaje, sistema de interacción, basura con datos educativos (`data/basura.json`), HUD de salud, puntos de control, pantalla de nivel completado, pruebas GUT y pipeline de CI/CD.

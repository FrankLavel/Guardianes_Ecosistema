# Inventario del arte generado (sprint 1)

Revisado el 16 de octubre de 2026. ✅ listo para integrar · ⚠️ usable con un detalle · ❌ falta o no sirve

## Recibido

| Archivo | Contenido | Estado |
|---|---|---|
| `gara_aerea.jpg` | Gara vista desde arriba: caminar de frente, de lado y de espaldas | ✅ |
| `valle_tileset.jpg` | Pasto, caminos, río con puente, piedra y árboles pequeños | ✅ |
| `valle_objetos.jpg` | Árboles, arbusto, rocas, casa de adobe, muelle, cerca, letrero, tubería, tocón | ✅ |
| `valle_entradas.jpg` | Tres entradas a zonas (piedra con agua, troncos con mariposas, tule) | ✅ |
| `zona1_plataformas.jpg` | Bloque de suelo, islas flotantes, troncos, pilar, rampa, orillas con agua | ✅ |
| `zona1_objetos.jpg` | Basura, tubería con agua sucia, válvula, tronco, brote, árbol, lancha, charco tóxico | ⚠️ La lata tiene la marca Coca-Cola: no debe salir una marca real; regenerar solo la lata, sin logotipo |
| `zona1_animales.jpg` | Acocil, garza blanca, martín pescador y pez (4 cuadros cada uno) | ✅ |
| `zona1_fondo_panorama.jpg` | Panorama de cielo, montañas y pinos | ⚠️ Viene todo en una sola imagen; se puede usar, pero las capas separadas dan mejor profundidad |
| `don_chucho.jpg` | Don Chucho, el pescador (de pie, de lado) | ✅ (`variante2` a `variante4` son casi iguales; se pueden borrar) |
| `puzzle_filtro_vacio.jpg`, `_grava`, `_arena`, `_carbon` | Botella vacía y capas del filtro | ✅ |
| `ui_panel.jpg` | Marco de madera con hojas | ✅ |
| `ui_panel_bitacora.jpg` | Marco de madera con pestañas de categorías | ✅ (sirve para la bitácora) |
| `ui_botones.jpg` | Botón verde normal, al pasar el mouse y presionado | ✅ |
| `ui_iconos.jpg` | Corazón, hoja, gota, bolsa (repetida), libro, pausa, cerrar | ✅ |
| `zona2_fondo_talado.jpg` | Bosque talado | ✅ (para la Zona 2, sprint 3) |
| `zona2_mariposa_monarca.jpg` | Mariposa monarca de frente | ✅ (sirve para la ficha de la bitácora; para el juego se necesita también de lado y volando) |
| `zona2_isla_bosque.jpg` | Isla flotante con oyameles (vista isométrica) | ⚠️ La perspectiva no coincide con los niveles laterales; puede usarse como decoración del mapa |
| `npc_aldeana_aerea.jpg` | Una niña con trenzas, vista desde arriba | ⚠️ No es Gara; se puede usar como personaje del pueblo |
| `revisar_bosque_con_otro_personaje.jpg` | Ilustración de bosque con otro niño dentro | ❌ Trae un personaje encima; no sirve como fondo. Se puede usar como imagen para el menú o itch.io si se quita el personaje |

## Segunda tanda (16 oct)

| Archivo | Contenido | Estado |
|---|---|---|
| `zona1_fondo_cielo.jpg` / `_contaminado` | Cielo al amanecer / cielo gris con esmog | ✅ (vienen dentro de un marco; se recorta) |
| `zona1_fondo_montanas.jpg` / `_contaminado` | Montañas azules con neblina / montañas secas | ✅ |
| `zona1_fondo_arboles.jpg` / `_contaminado` | Línea de pinos / pinos secos con basura | ✅ |
| `zona1_valvula.jpg` | Válvula abierta (con agua) y cerrada | ✅ |
| `zona1_lata.jpg` | Lata aplastada sin marca | ✅ Reemplaza a la lata de `zona1_objetos` |
| `puzzle_filtro_extras.jpg` | Algodón, gota sucia y gota limpia | ✅ (el algodón tiene forma de pieza de rompecabezas, no de botella; se adapta en el juego) |
| `don_chucho_retrato.jpg` | Cara para diálogos | ⚠️ Ropa distinta a `don_chucho.jpg` (camisa blanca y paliacate azul en vez de chaleco) |
| `don_chucho_hablando.jpg` | 4 cuadros: quieto y hablando | ⚠️ Mismo diseño nuevo que el retrato, de frente y no de lado |
| `logo.jpg` | Logo del juego | ✅ (trae Garas pequeñas corriendo abajo; se recorta solo el logo) |

**Decisión pendiente — Don Chucho:** hay dos diseños. Recomendado: quedarse con el **nuevo** (retrato + hablando, que ya coinciden entre sí) y regenerar solo la pose de pie de lado con ese diseño (adjuntando `don_chucho_retrato.jpg`). Si no, se usa el nuevo diseño también para estar de pie.

## Tercera tanda (16 oct)

| Archivo | Contenido | Estado |
|---|---|---|
| `npc_aldeana_aerea.jpg` | Ahora es **la niña jugable** en el valle | ✅ |
| `nina_plataformas.jpg` | La niña de lado: quieta, caminar, correr, saltar, caer, agacharse, recoger | ⚠️ En **caminar y correr** trae el overol y las botas del niño en vez de su falda y sandalias; regenerar esas dos filas |

## Falta

Del sprint 1 ya no falta nada imprescindible. Solo, si se quiere uniformidad:
- 🟡 Don Chucho de pie (de lado) con el diseño nuevo.
- 🔴 Filas de caminar y correr de la niña con su falda y sandalias.

## Notas para la próxima tanda
- La mayoría vino como **JPG**; si la herramienta permite PNG, mejor. Con JPG también funciona.
- Algunas imágenes traen cuadrícula en el fondo (`valle_tileset`, `zona1_animales`). Se puede limpiar, pero piden "sin cuadrícula" en el prompt.

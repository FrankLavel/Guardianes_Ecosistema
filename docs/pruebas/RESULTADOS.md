# Resultados de los casos de prueba (CP-01 a CP-14)

Casos definidos en el documento *Gestión del proceso de desarrollo y DevOps* (tabla 2).
Versión probada: **1.0.0-rc1**. Criterio de salida: todas las pruebas críticas aprobadas, ningún error
bloqueante ni crítico conocido, al menos 90 % de las pruebas generales satisfactorias y mínimo 30 FPS.

| ID | Caso | Resultado esperado | Prioridad | Resultado | Fecha | Evidencia |
|---|---|---|---|---|---|---|
| CP-01 | Iniciar videojuego | Se muestra correctamente el menú principal | Crítica | ✅ Aprobado | 9 nov 2026 | [CP-01](CP-01/) |
| CP-02 | Crear nueva partida | Se carga el escenario inicial | Crítica | ✅ Aprobado | 9 nov 2026 | [CP-02](CP-02/) |
| CP-03 | Movimiento | El personaje responde correctamente | Alta | ✅ Aprobado | 9 nov 2026 | [CP-03](CP-03/) |
| CP-04 | Colisiones | El jugador no atraviesa objetos sólidos | Alta | ✅ Aprobado | 9 nov 2026 | [CP-04](CP-04/) |
| CP-05 | Recolección | El objeto aparece en el inventario | Alta | ✅ Aprobado | 9 nov 2026 | [CP-05](CP-05/) |
| CP-06 | Activar misión | La misión aparece como activa | Alta | Pendiente | | |
| CP-07 | Completar misión | Se entrega la recompensa correspondiente | Alta | Pendiente | | |
| CP-08 | Información educativa | Se muestra la información de la especie | Media | Pendiente | | |
| CP-09 | Guardar partida | El progreso queda almacenado | Crítica | Pendiente | | |
| CP-10 | Cargar partida | Se recupera el progreso anterior | Crítica | Pendiente | | |
| CP-11 | Pausar juego | El videojuego se detiene correctamente | Media | Pendiente | | |
| CP-12 | Cambio de escenario | El nuevo escenario carga correctamente | Alta | Pendiente | | |
| CP-13 | Rendimiento | Se mantienen al menos 30 FPS | Alta | Pendiente | | |
| CP-14 | Cerrar videojuego | El videojuego termina correctamente | Media | Pendiente | | |

## CP-01 · Iniciar videojuego

**Cómo se probó:** se abrió la versión de Windows que se entrega (`GuardianesDelUltimoEcosistema.exe`,
1.0.0-rc1) en las tres resoluciones del plan de compatibilidad, sin el editor de Godot.

| Resolución | Tiempo en abrir | Menú principal | Título de la ventana |
|---|---|---|---|
| 1280 × 720 | 0.8 s | Se ve completo: logo, fondo y botones | Guardianes del Último Ecosistema |
| 1366 × 768 | 0.5 s | Se ve completo | Guardianes del Último Ecosistema |
| 1920 × 1080 | 0.5 s | Se ve completo | Guardianes del Último Ecosistema |

También se comprobó que el menú abre en la versión Web (navegador e itch.io) y en Android (emulador
Pixel con la versión firmada).

**Defecto encontrado y corregido durante la prueba:** el título de la ventana decía
"guardianes del ultimo ecosistema" (en minúsculas y sin acento). Se corrigió el nombre del proyecto y,
como en Windows ese nombre es también la carpeta de las partidas, el juego ahora copia al iniciar las
partidas y opciones de la carpeta anterior para que nadie pierda su progreso ("CONTINUAR" sigue
apareciendo en las capturas).

**Resultado: ✅ Aprobado.**

## CP-02 · Crear nueva partida

**Cómo se probó:** en la versión de Windows (1280 × 720), con clics reales del mouse y partiendo de una
computadora que ya tenía una partida guardada (se respaldó antes y se restauró al terminar).

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Menú principal | Aparecen CONTINUAR, NUEVA PARTIDA, OPCIONES y SALIR | `1_menu.png` |
| 2. Clic en NUEVA PARTIDA | Aparece el aviso "¿Empezar una partida nueva?"; "NO, REGRESAR" queda seleccionado | `2_aviso.png` |
| 3. SÍ, EMPEZAR DE NUEVO | Se abre "¿Quién protegerá el valle?" | `3_personaje.png` |
| 4. Elegir NIÑA y escribir "Prueba" | La niña queda marcada y el nombre se escribe | `4_nina_nombre.png` |
| 5. COMENZAR | Se carga el valle de Tzintzun: día 1, 8 de la mañana, 0 de 3 zonas, objetivo "Habla con Don Chucho" | `5_valle.png` |

La partida guardada quedó con `genero: nina`, `nombre: Prueba`, sin zonas completadas, día 1 a las 8:00.
El personaje niño y el nombre sugerido se cubren con las pruebas automáticas de `test_seleccion.gd`, y
el inicio en Android se probó en el emulador.

**Defecto encontrado y corregido durante la prueba:** si ya había una partida, NUEVA PARTIDA →
COMENZAR la borraba sin preguntar. Ahora aparece el aviso con "NO, REGRESAR" seleccionado primero
(prueba automática `test_el_aviso_de_nueva_partida_deja_regresar`).

**Resultado: ✅ Aprobado.**

## CP-03 · Movimiento

**Cómo se probó:** en la versión de Windows (1280 × 720) con teclas reales del teclado, en las dos vistas
del juego: el valle (vista aérea, 4 direcciones) y el nivel del río (plataformas).

**Valle de Tzintzun**

| Tecla | Qué pasó | Evidencia |
|---|---|---|
| D | Camina a la derecha y la cámara lo sigue | `valle_1_derecha_D.png` |
| W | Camina hacia arriba (pasa junto a la casa) | `valle_2_arriba_W.png` |
| A | Camina a la izquierda (se ve a Don Chucho) | `valle_3_izquierda_A.png` |
| S | Camina hacia abajo y regresa al cruce de caminos | `valle_4_abajo_S.png` |
| → / ← | Las flechas hacen lo mismo que D y A | `valle_5…`, `valle_6…` |
| W + A hasta el arco | Llega al arco del río y aparece "E Río Cupatitzio"; el río no se puede cruzar | `valle_7_hacia_el_rio.png` |

**Nivel del río (plataformas)**

| Tecla | Qué pasó | Evidencia |
|---|---|---|
| E en el arco | Entra al nivel del río | `nivel_0_entrada.png` |
| → | Camina a la derecha y la cámara lo sigue | `nivel_2_derecha.png` |
| Espacio | Salta (foto en el aire) y vuelve a caer al suelo | `nivel_3_salto.png`, `nivel_4_aterriza.png` |
| ← | Se voltea y camina a la izquierda; junto a la basura aparece "E" | `nivel_5_izquierda.png` |

Lo que no se probó a mano (trepar enredaderas en el bosque y nadar en agua limpia, que se desbloquean
más adelante) lo cubren las pruebas automáticas: `test_guardian.gd` (caminar, detenerse, saltar, no
saltar en el aire, gravedad, animaciones), `test_bosque.gd` (trepar y soltarse), `test_nadar.gd` (nadar
solo con la habilidad y agua limpia) y `test_valle.gd` (4 direcciones y no cruzar el río). Todas pasan
(184 de 184). Los controles táctiles de Android se probaron en el emulador (el joystick mueve al
personaje).

**Resultado: ✅ Aprobado.** Sin defectos encontrados.

## CP-04 · Colisiones

**Cómo se probó:** con pruebas automáticas que empujan al personaje 2 segundos contra cada tipo de
objeto sólido usando la física real del juego, y con evidencia visual en la versión de Windows.

| Objeto sólido | Cómo se probó | Resultado | Evidencia |
|---|---|---|---|
| Casa | Teclas reales (W) en Windows | Se detiene contra la pared | `1_contra_la_casa.png` |
| Casa, árbol (encino) | Prueba automática | No los atraviesa | `test_no_atraviesa_la_casa`, `test_no_atraviesa_un_arbol` |
| Río | Teclas reales (CP-03) y prueba automática | No lo cruza | `test_gara_no_cruza_el_rio` |
| Orilla del mapa | Prueba automática | No sale del valle | `test_no_sale_del_mapa` |
| Cerca del valle | Prueba automática y empuje de frente con las acciones del teclado | Se detiene contra la cerca | `test_no_atraviesa_la_cerca`, `5_cerca_del_valle_*.png` |
| Cerca de los corrales | Prueba automática y empuje de frente | Se detiene contra la cerca | `test_no_atraviesa_la_cerca_de_un_corral`, `6_cerca_del_corral_*.png` |
| Suelo de los niveles | Teclas reales (CP-03) y pruebas de `test_guardian.gd` | Camina y aterriza sobre el suelo, no lo atraviesa | CP-03 `nivel_*.png` |

**Defecto encontrado y corregido durante la prueba:** la cerca suelta del valle y las cercas de los
corrales no tenían forma de choque y el personaje las atravesaba. Ahora cada tramo de cerca choca por la
línea de sus postes (al empujar de lado el personaje resbala por la cerca y la rodea por la punta, como
en cualquier juego). Los arbustos, las piedritas y el muelle se dejan pisables a propósito (el muelle es
donde se pesca).

**Resultado: ✅ Aprobado.**

## CP-05 · Recolección

**Cómo se probó:** en la versión de Windows (1280 × 720) con una partida de prueba que se borró al
terminar. Se acercó a la niña al objeto y se mandó la tecla E como evento de teclado dentro del juego,
igual que si se presionara en el teclado (así la prueba no depende de qué ventana tiene el foco). Se
probaron los dos tipos de recolección del juego.

**Valle: plantas silvestres → mochila**

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Junto al nopal | Aparece "E  Recoger nopal" | `1_junto_a_la_planta.png` |
| 2. Mochila antes (I) | "Tu mochila está vacía" | `2_mochila_antes.png` |
| 3. Presionar E | El nopal desaparece, sale "+1 Nopal" y la experiencia sube a 1 / 15 | `3_recoge_con_E.png` |
| 4. Mochila después | Aparece la tarjeta "Nopal ×1" | `4_mochila_despues.png` |

Al guardar, la partida quedó con `"inventario": {"nopal": 1}`.

**Nivel del río: basura → contador**

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Junto a la botella | "Basura recogida: 0 / 8" y la barra de salud del río vacía | `5_rio_antes.png` |
| 2. Presionar E | "Basura recogida: 1 / 8", la barra sube y aparece el dato "Botella de plástico" | `6_rio_despues.png` |

**Pruebas automáticas:** se agregó `test_recolectar_una_planta_la_pone_en_la_mochila_y_se_guarda` (la
planta pasa a la mochila, deja de estar en el valle y sigue en la mochila después de guardar y cargar). La
basura ya la cubrían `test_basura.gd` (se recoge al interactuar y no se puede recoger dos veces) y
`test_nivel1.gd` (la salud sube y se muestra el dato). Pasan 190 de 190.

**Resultado: ✅ Aprobado.** Sin defectos encontrados.

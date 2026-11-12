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
| CP-06 | Activar misión | La misión aparece como activa | Alta | ✅ Aprobado | 9 nov 2026 | [CP-06](CP-06/) |
| CP-07 | Completar misión | Se entrega la recompensa correspondiente | Alta | ✅ Aprobado | 9 nov 2026 | [CP-07](CP-07/) |
| CP-08 | Información educativa | Se muestra la información de la especie | Media | ✅ Aprobado | 12 nov 2026 | [CP-08](CP-08/) |
| CP-09 | Guardar partida | El progreso queda almacenado | Crítica | ✅ Aprobado | 12 nov 2026 | [CP-09](CP-09/) |
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

**Cómo se probó:** se corrió el juego en Windows (1280 × 720, Godot 4.7.2, el mismo código del armado
1.0.0-rc1) con un script que acerca a la niña al objeto y manda la tecla E como evento de teclado dentro
del juego, igual que si se presionara (así la prueba no depende de qué ventana tiene el foco). Se usó una
partida de prueba que se borró al terminar. Se probaron los dos tipos de recolección del juego.

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

## CP-06 · Activar misión

**Cómo se probó:** igual que CP-05 (el juego corriendo en Windows a 1280 × 720 con la tecla E mandada
como evento dentro del juego y una partida de prueba que se borró al terminar). El juego tiene dos tipos
de misión y se probaron las dos.

**Misión principal: restaurar el río**

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Partida nueva, junto a Don Chucho | El objetivo dice "Habla con Don Chucho, junto al río" y aparece "E  Hablar" | `1_antes_habla_con_don_chucho.png` |
| 2. Presionar E | Don Chucho se presenta y explica el problema del río | `2_don_chucho_explica.png` |
| 3. Terminar el diálogo | La misión queda activa: "Entra al río por el arco de piedra" | `3_mision_activa_entra_al_rio.png` |

**Pedido de ayuda de un animal (después de restaurar las 3 zonas)**

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Llega la hora del pedido | Un pato camina hacia la niña: "¡Un animal necesita tu ayuda! Habla con él (E)" | `4_un_animal_viene.png` |
| 2. El pato llega | Se detiene junto a ella con "E  Hablar" | `5_necesita_tu_ayuda.png` |
| 3. Presionar E | "¡Guardiana, ayúdame! ¡No encuentro a mi cría!" | `6_pide_ayuda.png` |
| 4. Terminar el diálogo | La misión queda activa: "Busca a la cría del pato y tráela", y la cría aparece en el valle | `7_pedido_activo.png` |

La partida guardada quedó con `"pedido": {"tipo": "cria", "animal": "Pato1", "estado": "activo"}`, así que
la misión sigue activa si se sale y se vuelve a entrar (`test_un_pedido_a_medias_reaparece_al_volver`).
Para no esperar el día de juego que tarda el pedido, el script adelantó el reloj al momento del pedido
(que tarde un día lo cubre `test_el_siguiente_pedido_tarda_un_dia`).

**Defecto encontrado y corregido durante la prueba:** el animal se detenía a 90 px de la niña, pero su
zona para hablar alcanza 80 px más medio cuerpo de ella. Si llegaba desde abajo se quedaba a 81 px: no
aparecía "E  Hablar" y la E no hacía nada hasta que el jugador diera un paso (un niño podía pensar que el
juego se trabó). Ahora se detiene a 70 px y se agregó la prueba
`test_el_animal_que_llega_de_abajo_queda_al_alcance_para_hablar`, que falla con el código anterior y
pasa con el nuevo. Pasan 191 de 191.

**Resultado: ✅ Aprobado.**

## CP-07 · Completar misión

**Cómo se probó:** igual que CP-05 y CP-06 (el juego corriendo en Windows a 1280 × 720, tecla E como
evento dentro del juego, partida de prueba borrada al final). Se completaron los dos tipos de misión.

**Misión del río** (con el nivel del río ya limpio; el nivel completo se prueba en CP-12)

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Antes | 0 / 3 zonas, sin habilidades, sin semillas; "Habla con Don Chucho: quiere enseñarte algo" | `1_rio_antes.png` |
| 2. Hablar con Don Chucho | Se abre el reto "El filtro de agua" | `2_filtro_de_don_chucho.png` |
| 3. Poner las capas en orden | "¡El agua sale limpia!" y aviso "¡Nueva especie en tu bitácora! Martín pescador" | `3_filtro_resuelto.png` |
| 4. Continuar | Don Chucho: "¡Eso es! Así se limpia el agua: capa por capa" | `4_don_chucho_felicita.png` |
| 5. Recompensa | 1 / 3 zonas restauradas y "¡Nueva habilidad: NADAR!"; en la mochila, 4 semillas de frijol; el objetivo pasa al bosque | `5_recompensa_nadar.png` |

**Pedido de ayuda: la cría perdida**

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Encontrar la cría | "E  Llamar a la cría" | `6_encuentra_la_cria.png` |
| 2. Llamarla | "La cría te sigue. Llévala con su mamá." | `7_la_cria_te_sigue.png` |
| 3. Llegar con la mamá | La cría se junta con ella, la mamá muestra "!": "¡Listo! Regresa a hablar con el animal" | `8_llega_con_su_mama.png` |
| 4. Hablar con la mamá | "¡Mi cría! ¡Gracias, guardiana!" | `9_gracias.png` |
| 5. Recompensa | "+8 hojas · Gástalas en muebles para tu casa": hojas 0 → 8 y experiencia 0 → 10 | `10_recompensa_hojas.png` |

La partida guardada quedó con 8 hojas, una ayuda contada (`"ayudas": {"cria": 1}`) y sin pedido pendiente.
Para no rodear cercas, el script llevó a la niña junto a la mamá y la cría caminó sola detrás de ella.
Lo cubren también las pruebas `test_la_cria_cuenta_al_llegar_con_su_mama`,
`test_hojas_ayudas_y_muebles_se_guardan` y `test_recoger_todo_y_arreglar_las_compuertas_limpia_el_rio`.

**Defecto encontrado y corregido durante la prueba:** la cría solo contaba si quedaba a menos de
110 px de su mamá, pero camina 70 px detrás de la niña. Si la niña llegaba por el mismo lado por donde
venía la cría y se paraba junto a la mamá (lo natural para hablarle), la cría se quedaba a unos 160 px y
la misión no avanzaba nunca, sin ninguna pista de qué hacer. Ahora también cuenta cuando la niña llega
junto a la mamá con la cría siguiéndola de cerca, y la cría camina hasta su mamá. Se agregó
`test_la_cria_cuenta_aunque_llegue_detras_del_guardian`, que falla con el código anterior. Pasan 192 de 192.

**Resultado: ✅ Aprobado.**

## CP-08 · Información educativa

**Cómo se probó:** el juego corriendo en Windows (1280 × 720) con la tecla Tab mandada como evento de
teclado dentro del juego y una partida de prueba borrada al final. Además se revisaron las 14 fichas de
`data/especies.json`.

| Paso | Qué pasó | Evidencia |
|---|---|---|
| 1. Se descubre una especie | Aviso "¡Nueva especie en tu bitácora! Garza blanca · Tab: abrir la bitácora" | `1_aviso_nueva_especie.png` |
| 2. Tab | Se abre la bitácora en la pestaña Río: dibujo, "Garza blanca", *Ardea alba*, "Sin peligro" y su dato; "Especies descubiertas: 1 / 14" | `2_ficha_garza.png` |
| 3. Tocar una especie sin descubrir | Se ve como silueta, "???" y "Sigue explorando y ayudando al ecosistema para descubrir esta especie" (no se revela antes de tiempo) | `3_sin_descubrir.png` |
| 4. Tab otra vez | La bitácora se cierra | — |
| 5. Con las 14 descubiertas | Una ficha de cada zona: Acocil (Necesita cuidado), Mariposa monarca (En peligro), Achoque (En peligro); "14 / 14" | `4_rio_acocil.png`, `5_bosque_monarca.png`, `6_lago_achoque.png` |

Las 14 especies (4 del río, 6 del bosque, 4 del lago) tienen nombre común, nombre científico, estado de
conservación, dibujo y un dato de entre 94 y 144 caracteres (`test_cada_especie_tiene_sus_datos`). En los
niveles también se muestra información educativa al recoger cada basura (CP-05, "Botella de plástico").

**Revisión del contenido:** los datos son correctos y van con el tema de Michoacán (achoque y pescado
blanco de Pátzcuaro, monarca y oyamel, peces endémicos de la familia Goodeidae). Queda un punto para
confirmar con el equipo o la maestra: la monarca dice "En peligro"; la UICN la pasó a *vulnerable* en
2023 y en México está "sujeta a protección especial", así que "Necesita cuidado" sería más exacto.

**Defecto encontrado y corregido durante la prueba:** al abrir la bitácora, la primera tarjeta toma el
foco y Tab (la tecla que indica el juego: "Tab: bitácora") solo pasaba a la siguiente tarjeta en vez de
cerrar el libro; había que usar B, Esc o el botón CERRAR. Ahora Tab la cierra. Se agregó
`test_tab_cierra_la_bitacora_aunque_una_tarjeta_tenga_el_foco`, que falla con el código anterior. Pasan
193 de 193.

**Resultado: ✅ Aprobado.**

## CP-09 · Guardar partida

**Cómo funciona:** el juego guarda solo, sin botón: cada minuto, al salir por la pausa, al cerrar la
ventana o mandar la app a segundo plano, y en momentos clave (terminar una zona, un pedido o un taller).
Cada guardado escribe primero un archivo temporal y luego lo cambia por el bueno, dejando la partida
anterior como respaldo (`partida_N.json.bak`); si el archivo se daña, al cargar se usa el respaldo.

**Cómo se probó:** el juego corriendo en Windows (1280 × 720) con una partida de prueba en la carpeta
real de partidas (`%APPDATA%/Godot/app_userdata/Guardianes del Último Ecosistema/`), borrada al final. Se
revisó el archivo después de cada forma de guardar (`registro.txt`).

| Forma de guardar | Qué se hizo | Qué quedó en el archivo | Evidencia |
|---|---|---|---|
| Salir por la pausa | Jugar (recoger leña, caminar), Esc → MENÚ PRINCIPAL | Nombre "Prueba", niña, 3 zonas, leña 1, la posición exacta del personaje, día 1 a las 9:06 | `1_jugando.png`, `2_pausa.png`, `3_menu_principal.png` |
| Automático | Volver a entrar, recoger otro leño y no tocar nada | El archivo tenía leña 1; a los 59 s se guardó solo con leña 2 | `4_despues_del_guardado_automatico.png` |
| Cerrar la ventana (X) | Ganar 5 hojas y cerrar | Hojas 0 → 5 antes de salir | `registro.txt` |

Al terminar quedaron `partida_97.json` y su respaldo `.bak`, sin archivo `.tmp` a medias. Copia del
archivo guardado: `partida_guardada.json`.

**Pruebas automáticas:** `test_juego.gd` (guardar y cargar recupera el progreso, deja respaldo y lo usa si
la partida se daña, se guarda al mandar la app a segundo plano y el personaje elegido) y las de cada parte
que se guarda (`test_la_granja_se_guarda`, `test_los_talleres_se_guardan`,
`test_hojas_ayudas_y_muebles_se_guardan`, etc.). En Android se probó en el emulador que la partida sigue
al cerrar la app. Pasan 193 de 193.

**Resultado: ✅ Aprobado.** Sin defectos encontrados. Mejora opcional: el juego no avisa cuando guarda; un
ícono pequeño de "Guardando…" daría tranquilidad a los niños.

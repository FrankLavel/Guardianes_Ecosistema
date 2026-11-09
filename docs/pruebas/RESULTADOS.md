# Resultados de los casos de prueba (CP-01 a CP-14)

Casos definidos en el documento *Gestión del proceso de desarrollo y DevOps* (tabla 2).
Versión probada: **1.0.0-rc1**. Criterio de salida: todas las pruebas críticas aprobadas, ningún error
bloqueante ni crítico conocido, al menos 90 % de las pruebas generales satisfactorias y mínimo 30 FPS.

| ID | Caso | Resultado esperado | Prioridad | Resultado | Fecha | Evidencia |
|---|---|---|---|---|---|---|
| CP-01 | Iniciar videojuego | Se muestra correctamente el menú principal | Crítica | ✅ Aprobado | 9 nov 2026 | [CP-01](CP-01/) |
| CP-02 | Crear nueva partida | Se carga el escenario inicial | Crítica | Pendiente | | |
| CP-03 | Movimiento | El personaje responde correctamente | Alta | Pendiente | | |
| CP-04 | Colisiones | El jugador no atraviesa objetos sólidos | Alta | Pendiente | | |
| CP-05 | Recolección | El objeto aparece en el inventario | Alta | Pendiente | | |
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

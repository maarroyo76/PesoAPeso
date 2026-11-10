# Iteraciones (Sprint Backlog)

El equipo trabaja con **Kanban**: las tareas avanzan por el tablero de GitHub
Projects sin sprints de duración fija. Para responder a la pauta, que pide un
Sprint Backlog por sprint, el trabajo se agrupa en **iteraciones por entrega**:
cada iteración termina en una entrega integrada a `main` (un commit o un pull
request). Las fechas, historias y tests de cada una salen del historial de
git, de los issues y de los pull requests del repositorio; no son una
planificación hecha a posteriori.

| Iteración | Fechas | Entrega | Historias | Tests declarados al cierre |
|---|---|---|---|---|
| I0. MVP | hasta el 28 ago 2026 | Primer commit | RF01–RF25 | 8 (4 archivos) |
| I1. Puesta en marcha y robustez | 28 ago – 9 oct 2026 | Commits a `main`, issues #1–#6 | Mejoras sobre RF01–RF25 | 48 (11 archivos) |
| I2. Ampliación de la propuesta | 10 – 28 oct 2026 | PR #10 | RF31–RF38, RF40–RF56, UX01–UX11 | 186 (35 archivos) |
| I3. Decidir antes de gastar | 29 oct – 10 nov 2026 | PR #11 y PR #12 | RF39, RF57–RF68 | 266 (40 archivos) |

## I0. MVP

**Objetivo.** Una app usable para registrar gastos y controlar un presupuesto
mensual, sin conexión y con los datos cifrados.

**Qué se desarrolló.** El MVP llegó completo al repositorio en el primer
commit (28 de agosto): registro de gastos y accesos rápidos, categorías,
presupuestos por categoría y total versionados por mes, pagos fijos con
registro automático, metas de ahorro con aportes, alertas al 80% y 100%,
estadísticas básicas, respaldo y restauración en JSON, onboarding y base
SQLite en esquema v8. Su desarrollo previo no forma parte de este historial.

**Pruebas al cierre.** Respaldo y restauración, migración del presupuesto
(v1 → v2), catch-up de pagos fijos y arranque de la app.

## I1. Puesta en marcha y robustez

**Objetivo.** Dejar el proyecto listo para trabajar en equipo y publicar, y
corregir los problemas de confiabilidad del MVP.

| Tarea | Evidencia |
|---|---|
| Reorganizar los documentos APT | Issue #1 |
| Identificador definitivo `cl.pesoapeso.app` | Issue #2, commit del 14 sep |
| Firma de release con keystore propio | Issue #3, commit del 14 sep |
| Base de datos local cifrada (SQLCipher) | Issue #6, cerrado el 25 sep |
| Modelo de datos y arquitectura | Issue #5, cerrado el 9 oct |
| Selector de color e ícono de categoría | Commit del 22 sep |
| Arranque, pagos fijos y respaldo más robustos | Commit del 7 oct |
| Validación de campos y corrección de la edición de gastos | Commit del 7 oct |
| Explicación de métricas y cambio de mes deslizando | Commit del 7 oct |
| Documentos de la Fase 2 | Commits del 9 oct |

**Pruebas agregadas.** Errores de respaldo con mensajes para el usuario,
validación de respaldos, límites de los campos de monto, fechas antiguas en
el formulario, mes del remanente, migración v7 → v8 y tooltips y gestos de
Resumen.

## I2. Ampliación de la propuesta

**Objetivo.** Implementar las mejoras del documento "Análisis y propuesta de
mejoras" del 27 de octubre: corregir las inconsistencias del modelo, mejorar
la experiencia de registro y agregar métodos de pago y cuotas.

| Historias | Qué se entregó |
|---|---|
| Problemas 1–3, I1–I7 | Pantalla de error de arranque con salida, catch-up en transacciones, claves foráneas activas, enlace gasto–pago fijo |
| UX01–UX11 | Guardar con "Deshacer", Ajustes con nombres, historial con búsqueda, letra grande, lector de pantalla, tema oscuro |
| RF50–RF55 | Remanente como ajuste del mes, aportes que descuentan del presupuesto, usar ahorro, archivar y fusionar categorías, alerta del total |
| RF31–RF36, RF40–RF43 | Métodos de pago (esquema v10), compras en cuotas y estadísticas por método de pago y tarjeta |
| RF37, RF38, RF44 | Revisión semanal, cuánto puedes gastar hoy y lo marcado "no tanto" |
| RF45–RF49, RF56 | "Carga bip!", cantidad en accesos rápidos, gastos habituales con recordatorio (esquema v11) y sugerencia de accesos |
| RF26–RF30 (prototipo) | Lectura del timbre de boletas; luego se retiró del alcance |

**Pruebas agregadas.** 24 archivos nuevos: deshacer, accesibilidad y letra
grande, integridad de datos, archivar y fusionar categorías, métodos de pago,
cuotas, gastos habituales (lógica y pantallas), revisión semanal, historial,
estadísticas por método de pago, catálogo del onboarding y migración v9 → v10.

## I3. Decidir antes de gastar

**Objetivo.** Reemplazar el escaneo de boletas por la nueva función estrella
y cerrar los pendientes funcionales.

| Orden | Historias | Qué se entregó | Commit |
|---|---|---|---|
| 1 | RF26–RF30, RNF17 | Retiro del escáner y archivo en `archivo/escaner-boletas` (PR #11) | `b9e0bea` |
| 2 | RF58, RNF24 | Proyección del disponible de los meses siguientes, en funciones puras | `e973530` |
| 3 | RF57, RF59, RF60 | Simulador con alternativas, interés y "Comprar así" | `def844d` |
| 4 | RF61, RF62 | Lista de espera, esquema v12 y tarjeta en Resumen | `f18e854` |
| 5 | RF63, RF64 | Costo de vida fijo y estadísticas de la lista de espera | `cd23135` |
| 6 | RF65–RF67 | Categorías esenciales (esquema v13) y revisión de lo no esencial | `b460c54` |
| 7 | RF68 | "No tanto" de la categoría en el simulador y la lista de espera | `60523a5` |
| 8 | RF39 | Widget de inicio de Android | `d047188` |

Todo entró a `main` con el PR #12 el 10 de noviembre.

**Pruebas agregadas.** Proyección con datos fijos, simulador y alternativas,
lista de espera y migración v12, costo fijo y estadísticas, categorías
esenciales y migración v13, revisión de lo no esencial, datos del widget y
pruebas de rendimiento.

## Próxima iteración (I4, propuesta)

- Probar en un teléfono el simulador, la lista de espera, las estadísticas
  nuevas y el widget.
- Validar la función estrella con 10 a 15 personas del público objetivo.
- Medir RNF06–RNF08 en un dispositivo de gama baja.
- Notificación opcional al vencer un deseo (RF62).
- Cerrar UX09: reemplazar los dos mensajes `Error: $e` que quedan.

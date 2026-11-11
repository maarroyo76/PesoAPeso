# Gestión ágil: Peso a Peso

Proyecto APT122 · Equipo: Martín Arroyo Quilcat, Carlos Loncuante, Renato Reinoso

Este documento reúne los artefactos del marco ágil del proyecto: la visión del producto, el Product Backlog, el Sprint Backlog de cada iteración, la Definition of Done y las retrospectivas.

## 1. Product Vision

### Visión

Que cualquier persona pueda saber, antes de comprar, si su plata le alcanza
este mes y los siguientes, sin entregar sus datos financieros a nadie.

### Problema

En Chile mucha gente controla sus gastos en una planilla de Excel, en una
libreta o de memoria. Las planillas cumplen mientras hay disciplina, pero
son lentas de mantener desde el teléfono, no avisan cuando un presupuesto se
está acabando y no dicen nada sobre el futuro: muestran lo que ya se gastó,
no lo que ya está comprometido.

El problema se agrava con las compras en cuotas. Pagar en 3, 6 o 12 cuotas
con tarjetas bancarias y de retail es habitual, y cada compra compromete
meses que todavía no llegan. Una persona puede tener el mes actual bajo
control y, sin darse cuenta, haber dejado los próximos tres sin margen.

Las alternativas existentes no calzan con este público:

- Las apps de los bancos muestran movimientos de una sola institución y no
  sirven como presupuesto personal.
- Las apps de finanzas que agregan cuentas piden vincular el banco o guardar
  los datos en la nube, algo que muchas personas no quieren hacer con su
  información financiera.
- Las planillas y apps de registro simples registran el pasado, pero no
  ayudan a decidir.

### Usuarios

**Usuario principal: quien hoy lleva sus gastos en una planilla.** Persona
adulta con ingresos propios (trabajador dependiente o independiente,
estudiante que trabaja) que ya tiene el hábito de anotar sus gastos o quiere
tenerlo, que usa tarjeta de crédito y compra en cuotas, y que desconfía de
entregar sus credenciales bancarias a una aplicación.

Necesidades:

- Registrar un gasto en segundos, en el momento en que ocurre.
- Saber cuánto le queda del mes y cuánto puede gastar hoy.
- Ver qué cuotas y pagos fijos ya tiene comprometidos.
- Decidir con datos si una compra en cuotas le conviene.
- Que sus datos queden en su teléfono.

**Usuario secundario: quien empieza a ordenar sus finanzas.** No tiene un
presupuesto definido ("Aún no sé"). La app debe servirle desde el primer
gasto, sin obligarlo a configurar todo antes, y sugerirle un presupuesto
cuando tenga un mes de datos.

### Propuesta de valor

Peso a Peso es una app de presupuesto y gastos de registro manual que
funciona sin conexión, guarda todo cifrado en el teléfono y convierte el
registro en información para decidir antes de gastar.

| Para el usuario | Cómo lo entrega la app |
|---|---|
| Registrar sin fricción | Accesos rápidos de un toque, con ×2 y ×3; widget en la pantalla de inicio; gastos habituales que se confirman desde la notificación |
| Saber dónde está parado | Presupuesto total y por categoría, "cuánto puedes gastar hoy", alertas al 80% y al 100% |
| Ver lo comprometido | Pagos fijos, cuotas pendientes por tarjeta y costo de vida fijo de cada mes |
| Decidir antes de gastar | Simulador de compras en cuotas que proyecta los meses siguientes con el gasto real, comparación con otras formas de pago y lista de espera para compras no urgentes |
| Aprender de su gasto | Revisión periódica "¿Valió la pena?" de lo no esencial y estadísticas de lo que no valió la pena |
| Privacidad | Sin vinculación bancaria ni nube: base cifrada con SQLCipher y respaldo en un archivo que controla el usuario |

### Función estrella: Decidir antes de gastar

La app proyecta el disponible de los meses siguientes como el presupuesto
total menos los pagos fijos, las cuotas ya comprometidas y el gasto variable
típico del usuario (la mediana de sus últimos tres meses). Sobre esa
proyección, el usuario simula una compra: ve mes a mes si le alcanza, la
compara con pagarla al contado o en otro número de cuotas, con interés si lo
hay, y puede comprarla de inmediato o dejarla en espera 48 horas, 7 o 30
días. Al vencer el plazo, la app vuelve a simularla con los datos de ese día
y le pregunta si todavía la quiere.

### Alcance

**Incluido:** registro manual de gastos, categorías, presupuestos
versionados por mes, métodos de pago y cuotas, pagos fijos y gastos
habituales, metas de ahorro, simulador y lista de espera, revisión de lo no
esencial, estadísticas, widget de Android, respaldo local, funcionamiento sin
conexión.

**Fuera de alcance:** vinculación bancaria, sincronización en la nube,
gestión compartida, múltiples monedas, registro de ingresos y escaneo de
boletas (prototipo archivado por ser lento e inconsistente).

### Indicadores de éxito

- Registrar un gasto frecuente toma un toque (acceso rápido o widget).
- La simulación de una compra se calcula en menos de 500 ms (RNF23).
- En la validación con 10 a 15 personas del público objetivo, la mayoría
  entiende sin ayuda si una compra en cuotas le alcanza.
- Ningún dato financiero sale del dispositivo: el APK no pide permiso de
  Internet (RNF01).

## 2. Product Backlog priorizado

Cada requisito funcional (RF) del documento de requisitos se expresa como una
historia de usuario con su criterio de aceptación. El identificador RF se
mantiene para poder rastrear cada historia hasta el código, los tests y los
commits. RF26 a RF30 (escaneo de boletas) se retiraron del alcance y no se
reutilizan.

**Prioridad.** *MVP* = parte del producto mínimo original; *Alta*, *Media* y
*Baja* según el documento "Análisis y propuesta de mejoras". El orden de las
épicas es el orden de prioridad.

**Iteración.** Ver la sección 3: I0 = MVP, I2 = ampliación de la
propuesta, I3 = función estrella.

### Épica 1. Registro de gastos

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF01 | Como usuario, quiero registrar un gasto con monto, categoría, fecha y nota, para llevar mi registro. | El gasto queda guardado y aparece en Resumen. | MVP | I0 | Hecho |
| RF02 | Como usuario, quiero registrar un gasto frecuente con un toque, para no escribirlo cada vez. | Tocar un acceso rápido registra el gasto sin más pasos. | MVP | I0 | Hecho |
| RF24 | Como usuario, quiero crear, editar y eliminar accesos rápidos, para adaptarlos a mis gastos. | Los cambios se ven al registrar. | MVP | I0 | Hecho |
| RF46 | Como usuario, quiero indicar ×2, ×3 o más al usar un acceso rápido, para registrar varios de una vez. | Se registra un solo gasto por el monto multiplicado. | Alta | I2 | Hecho |
| RF45 | Como usuario de transporte público, quiero un acceso rápido "Carga bip!", para registrar mis recargas. | Una instalación nueva lo trae en Transporte. | Alta | I2 | Hecho |
| RF56 | Como usuario, quiero que la app me sugiera un acceso rápido cuando repito un gasto, para registrarlo más rápido. | Con el mismo monto y nota 3 veces en 30 días se sugiere, una sola vez. | Media | I2 | Hecho |
| RF39 | Como usuario de Android, quiero un widget con mis accesos rápidos, para registrar sin abrir la app. | Registrar desde el widget toma como máximo dos toques. | Media | I3 | Hecho |
| RF07 | Como usuario, quiero ver mis movimientos recientes, para revisar lo que registré. | Resumen muestra los últimos gastos; el historial permite buscar y filtrar (UX06). | MVP | I0 | Hecho |
| RF08 | Como usuario, quiero editar o eliminar un gasto, para corregir errores. | El cambio se refleja en presupuestos y estadísticas; eliminar se puede deshacer (UX02). | MVP | I0 | Hecho |
| RF23 | Como usuario nuevo, quiero una configuración inicial corta, para empezar a usar la app de inmediato. | Bienvenida, presupuesto (con "Aún no sé"), categorías y primer gasto; los pasos se pueden omitir. | MVP | I0 | Hecho |

### Épica 2. Presupuestos y categorías

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF03 | Como usuario, quiero crear, editar y eliminar categorías, para ordenar mis gastos a mi manera. | No se elimina una categoría con gastos; se ofrece archivarla. | MVP | I0 | Hecho |
| RF04 | Como usuario, quiero un presupuesto mensual por categoría, para controlar cada tipo de gasto. | El presupuesto se versiona por mes: cambiarlo no altera los meses pasados. | MVP | I0 | Hecho |
| RF21 | Como usuario, quiero un presupuesto mensual total, para controlar el mes completo. | Es independiente de la suma de categorías y se versiona por mes. | MVP | I0 | Hecho |
| RF22 | Como usuario, quiero ver el monto sin asignar, para saber cuánto me queda de reserva. | Se advierte si las categorías superan el total. | MVP | I0 | Hecho |
| RF05 | Como usuario, quiero ver el saldo disponible del mes, para saber cuánto me queda. | Disponible = presupuesto − gastado − ahorrado. | MVP | I0 | Hecho |
| RF06 | Como usuario, quiero ver cuándo una categoría supera su presupuesto, para corregir a tiempo. | La categoría excedida se marca en rojo. | MVP | I0 | Hecho |
| RF18 | Como usuario, quiero un aviso al llegar al 80% o al 100% de una categoría, para frenar antes de pasarme. | El aviso aparece en pantalla al registrar el gasto que cruza el umbral. | MVP | I0 | Hecho |
| RF55 | Como usuario, quiero el mismo aviso para el presupuesto total, para cuidar el mes completo. | Un aviso por umbral y por mes. | Media | I2 | Hecho |
| RF38 | Como usuario, quiero saber cuánto puedo gastar hoy, para repartir lo que me queda. | Disponible dividido por los días que quedan; $0 si se superó. | Media | I2 | Hecho |
| RF50 | Como usuario, quiero sumar el remanente del mes al presupuesto del mes siguiente, para aprovecharlo. | El ajuste vale solo ese mes. | Alta | I2 | Hecho |
| RF15 | Como usuario, quiero que la app me pregunte qué hacer con lo que sobró del mes, para decidirlo. | Se pregunta una vez por mes: sumarlo al presupuesto o aportarlo a una meta. | MVP | I0 | Hecho |
| RF53 | Como usuario, quiero archivar categorías que ya no uso, sin perder su historial. | Las archivadas no se ofrecen al registrar y se pueden restaurar. | Media | I2 | Hecho |
| RF54 | Como usuario, quiero fusionar una categoría en otra, para ordenar mis categorías. | Los gastos se mueven en una transacción y la app informa cuántos. | Media | I2 | Hecho |
| RF65 | Como usuario, quiero marcar cada categoría como esencial o no, para revisar solo lo que puedo evitar. | El catálogo trae una clasificación por defecto; el cambio vale desde ese momento. | Alta | I3 | Hecho |

### Épica 3. Pagos fijos, habituales y cuotas

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF12 | Como usuario, quiero registrar pagos fijos mensuales, para no anotarlos cada mes. | La app los registra sola al abrirse, una vez por mes. | MVP | I0 | Hecho |
| RF25 | Como usuario, quiero ver, editar y eliminar mis pagos fijos, para mantenerlos al día. | Los cambios valen desde el mes siguiente. | MVP | I0 | Hecho |
| RF20 | Como usuario, quiero una notificación si un pago fijo registrado solo lleva una categoría al 80% o al 100%. | La notificación solo sale por gastos generados automáticamente. | MVP | I0 | Hecho |
| RF47 | Como usuario, quiero gastos habituales que pidan confirmación (metro, colación), porque no siempre ocurren. | Se crean, editan, pausan y eliminan con días y hora de recordatorio. | Media | I2 | Hecho |
| RF48 | Como usuario, quiero confirmar un gasto habitual desde la notificación, sin abrir la app. | Los botones "Registrar" y "Hoy no" funcionan en segundo plano. | Media | I2 | Hecho |
| RF49 | Como usuario, quiero ver los días sin confirmar en Resumen, para ponerme al día. | Registrar todos o uno por uno; los de más de 7 días se descartan. | Media | I2 | Hecho |
| RF31 | Como usuario, quiero registrar mis métodos de pago, para saber con qué pago. | Alias, tipo y hasta 4 dígitos; no se elimina uno con gastos. | Alta | I2 | Hecho |
| RF32 | Como usuario, quiero elegir el método de pago al registrar, con el último usado por defecto. | El gasto queda asociado al método. | Alta | I2 | Hecho |
| RF33 | Como usuario de tarjeta de crédito, quiero indicar sus días de facturación y pago. | Se calcula el período de facturación. | Media | I2 | Hecho |
| RF34 | Como usuario, quiero registrar una compra en cuotas, para ver cada cuota en su mes. | De 2 a 48 cuotas; se generan N gastos "Cuota k de N" enlazados al plan. | Alta | I2 | Hecho |
| RF35 | Como usuario, quiero ver y editar mis compras en cuotas, o marcarlas como prepagadas. | Se ven las cuotas pagadas y pendientes de cada plan. | Media | I2 | Hecho |
| RF36 | Como usuario, quiero ver en Presupuestos lo comprometido en cuotas para los meses siguientes. | Se muestra el monto de cuotas por mes futuro. | Alta | I2 | Hecho |

### Épica 4. Decidir antes de gastar (función estrella)

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF58 | Como usuario, quiero ver cuánto me quedaría cada mes con y sin una compra, para saber si me alcanza. | Los valores siguen la base de cálculo común; los meses bajo cero muestran cuánto falta. | Alta | I3 | Hecho |
| RF57 | Como usuario, quiero simular una compra con monto, cuotas, tarjeta e interés, antes de comprometerme. | La simulación no escribe nada en la base hasta confirmar. | Alta | I3 | Hecho |
| RF59 | Como usuario, quiero comparar pagar al contado o en 3, 6 y 12 cuotas, para elegir la mejor opción. | Con tasa 0 el total es igual en todas; con tasa, la cuota sigue la fórmula de cuota fija. | Media | I3 | Hecho |
| RF60 | Como usuario, quiero comprar desde la simulación o dejarla en espera. | El plan creado es idéntico al registrado a mano. | Alta | I3 | Hecho |
| RF61 | Como usuario, quiero una lista de espera para compras no urgentes, con un plazo. | Se crean, editan y eliminan deseos con plazo de 48 horas, 7 o 30 días. | Alta | I3 | Hecho |
| RF62 | Como usuario, quiero que la app me pregunte al vencer el plazo si todavía quiero la compra. | Una tarjeta por deseo vencido con la simulación recalculada: comprar, descartar o ahorrar. | Media | I3 | Hecho (sin la notificación opcional) |
| RF63 | Como usuario, quiero ver cuánto dejé de gastar gracias a la lista de espera. | Comprados + descartados + esperando = deseos del período. | Media | I3 | Hecho |
| RF64 | Como usuario, quiero conocer mi costo de vida fijo, para saber cuánto de mi presupuesto ya está comprometido. | Suma de pagos fijos, cuotas y habituales; sin presupuesto total, solo el monto. | Media | I3 | Hecho |
| RF68 | Como usuario, quiero ver al simular qué tan seguido no me valieron la pena gastos de esa categoría. | Se muestra solo con 5 o más gastos revisados. | Media | I3 | Hecho |

### Épica 5. Hábitos y revisión

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF37 | Como usuario, quiero revisar mis gastos recientes y marcar si valieron la pena. | La revisión se puede omitir. | Media | I2 | Hecho |
| RF66 | Como usuario, quiero revisar solo lo no esencial, cada semana o cada 15 días. | Un gasto de una categoría esencial no aparece en la revisión. | Alta | I3 | Hecho |

### Épica 6. Ahorro

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF13 | Como usuario, quiero crear metas de ahorro con un monto objetivo. | La meta muestra su progreso. | MVP | I0 | Hecho |
| RF14 | Como usuario, quiero registrar aportes a una meta. | El progreso se actualiza con cada aporte. | MVP | I0 | Hecho |
| RF19 | Como usuario, quiero accesos rápidos de aporte (monto fijo o % del presupuesto). | Un toque registra el aporte. | MVP | I0 | Hecho |
| RF51 | Como usuario, quiero que mis aportes descuenten del presupuesto sin contar como gasto. | Resumen separa gastado, ahorrado y disponible. | Alta | I2 | Hecho |
| RF52 | Como usuario, quiero pagar un gasto con lo ahorrado en una meta. | El gasto descuenta de la meta y no del presupuesto del mes. | Media | I2 | Hecho |

### Épica 7. Estadísticas

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF09 | Como usuario, quiero ver en un gráfico cómo se reparte mi gasto por categoría. | Gráfico de torta del mes. | MVP | I0 | Hecho |
| RF10 | Como usuario, quiero comparar presupuesto y gasto real por categoría. | Barra por categoría con su porcentaje. | MVP | I0 | Hecho |
| RF11 | Como usuario, quiero ver mi gasto total de cada mes. | Barras de los últimos 6 meses. | MVP | I0 | Hecho |
| RF40 | Como usuario, quiero ver mi gasto por método de pago. | Incluye "Sin especificar". | Media | I2 | Hecho |
| RF41 | Como usuario, quiero saber qué parte pago con crédito, débito o efectivo. | Evolución de 6 meses. | Media | I2 | Hecho |
| RF42 | Como usuario, quiero ver mi deuda en cuotas por tarjeta. | Lo que falta pagar desde el próximo mes. | Media | I2 | Hecho |
| RF43 | Como usuario, quiero un estado de cuenta estimado por tarjeta. | Compras y cuotas del período de facturación en curso. | Baja | I2 | Hecho |
| RF44 | Como usuario, quiero ver cuánto del mes marqué como "no tanto". | Ampliado por RF67. | Baja | I2 | Hecho |
| RF67 | Como usuario, quiero ver cuánto de mi gasto no esencial no valió la pena. | Los gastos sin revisar se informan aparte y no cuentan en el porcentaje. | Alta | I3 | Hecho |

### Épica 8. Datos y respaldo

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF16 | Como usuario, quiero exportar todos mis datos a un archivo. | El respaldo JSON incluye todas las tablas. | MVP | I0 | Hecho |
| RF17 | Como usuario, quiero restaurar mis datos desde un respaldo. | Se valida antes de reemplazar; acepta respaldos de versiones anteriores (RNF19). | MVP | I0 | Hecho |

### Resumen

| Estado | Historias |
|---|---|
| Hecho | 63 |
| Retiradas | 5 (RF26–RF30) |

Pendiente fuera del backlog funcional: notificación opcional de RF62 y
mediciones de rendimiento en un dispositivo de gama baja (RNF06–RNF08).

## 3. Sprint Backlog: iteraciones

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

### I0. MVP

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

### I1. Puesta en marcha y robustez

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

### I2. Ampliación de la propuesta

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

### I3. Decidir antes de gastar

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

### Próxima iteración (I4, propuesta)

- Probar en un teléfono el simulador, la lista de espera, las estadísticas
  nuevas y el widget.
- Validar la función estrella con 10 a 15 personas del público objetivo.
- Medir RNF06–RNF08 en un dispositivo de gama baja.
- Notificación opcional al vencer un deseo (RF62).
- Sumar el simulador y la lista de espera a los tests de accesibilidad (RNF22).

## 4. Definition of Done

Una historia de usuario está **terminada** cuando cumple su criterio de
aceptación (sección 2) y todos los puntos de esta lista. La
lista refleja lo que el proyecto ya exige en la práctica: buena parte la
verifica la integración continua en cada push y pull request.

### Código

- [ ] Cumple el criterio de aceptación de la historia, comprobado en la app.
- [ ] El código lleva comentarios con el identificador del requisito
  (por ejemplo `/// RF61: ...`), para rastrear cada historia hasta el código.
- [ ] Los cálculos (presupuestos, proyección, cuotas, estadísticas) están en
  funciones puras de `lib/core/utils/`, separadas de la interfaz (RNF24).
- [ ] `flutter analyze` termina sin problemas. *(CI)*
- [ ] El código está formateado con `dart format`.

### Pruebas

- [ ] Hay tests nuevos que cubren el criterio de aceptación: la lógica con
  datos fijos y, cuando toca la base o la pantalla, un test con base en
  memoria o un test de widget.
- [ ] Se prueban los casos borde que apliquen: meses sin historial, cambio de
  año, presupuesto ausente, montos en el límite.
- [ ] `flutter test` pasa completo, no solo los tests nuevos. *(CI)*

### Datos

- [ ] Si cambia el esquema, sube `schemaVersion`, la migración conserva los
  datos existentes y hay un test de migración desde la versión anterior.
- [ ] El código generado de Drift (`app_database.g.dart`) está al día. *(CI)*
- [ ] Si cambia lo que se guarda, el respaldo lo incluye, su versión sube y
  los respaldos anteriores se siguen aceptando (RNF19).
- [ ] Borrar o fusionar lo que la historia toca no deja datos huérfanos
  (claves foráneas o limpieza explícita).

### Seguridad y privacidad

- [ ] Ningún dato financiero sale del dispositivo: no se agregan permisos de
  Internet ni servicios en la nube (RNF01).
- [ ] No se guardan números completos de tarjeta, CVV ni vencimientos
  (RNF16).
- [ ] Los datos nuevos viven en la base cifrada; si algo tiene que quedar
  fuera de ella (por ejemplo, el widget), se justifica y se limita a lo
  mínimo.

### Experiencia

- [ ] Los textos para el usuario están en español de Chile, sin jerga técnica
  ni errores crudos (UX09).
- [ ] Lo tocable tiene nombre para el lector de pantalla y la pantalla no se
  desborda con letra grande (UX07, UX08).
- [ ] Las acciones destructivas o que registran algo se pueden deshacer
  (UX01, UX02).
- [ ] Se ve bien en tema claro y oscuro.

### Integración

- [ ] El trabajo está en una rama y entra a `main` con un pull request.
- [ ] Los commits tienen un título corto en español que dice qué cambió y
  nombran los requisitos que cubren.
- [ ] El documento de requisitos o la documentación técnica se actualizan si
  la historia cambia el alcance, el esquema o el formato del respaldo.

### Fuera de la DoD por ahora

Estos puntos se revisan antes de una entrega al público, no en cada historia:

- Prueba manual en un teléfono Android de gama baja.
- Medición de tiempos en dispositivo (RNF06–RNF08).
- Revisión de permisos del APK de release (`aapt2 dump permissions`).

## 5. Retrospectivas

Las retrospectivas son reuniones del equipo al cierre de cada iteración. Las
actas se completan con lo conversado en cada reunión; este documento no
reemplaza esa conversación.

Para cada iteración se registran también los **cambios de práctica que se
ven en el repositorio**. Son hechos verificables (commits, pull requests,
tests) que muestran qué mejoró el equipo, y sirven como punto de partida para
la reunión.

### Plantilla de acta

```
Iteración:            I_
Fecha de la reunión:
Asistentes:

1. ¿Qué funcionó bien?
2. ¿Qué no funcionó o nos frenó?
3. ¿Qué vamos a cambiar en la próxima iteración? (acciones concretas,
   con responsable)
4. Seguimiento de las acciones de la retrospectiva anterior:
```

### I1. Puesta en marcha y robustez

**Cambios de práctica observados en el repositorio**

- Se ordenaron los documentos APT en el repositorio (issue #1).
- Se pasó del identificador de ejemplo a `cl.pesoapeso.app` y se configuró
  la firma de release con un keystore fuera del control de versiones
  (issues #2 y #3).
- Las tareas se empezaron a registrar como issues de GitHub (#1 a #9).
- Los tests pasaron de 8 a 48 casos declarados.

**Acta del equipo:** *pendiente de completar.*

### I2. Ampliación de la propuesta

**Cambios de práctica observados en el repositorio**

- Antes de seguir agregando funciones se hizo un análisis del estado del
  proyecto ("Análisis y propuesta de mejoras", 27 de octubre), que detectó
  inconsistencias del modelo y problemas de integridad, y se corrigieron
  primero.
- Se agregó integración continua con GitHub Actions: análisis, tests y
  verificación del código generado en cada push.
- El trabajo entró a `main` con un pull request (#10) en vez de commits
  directos.
- Los tests pasaron de 48 a 186 casos declarados, incluidos tests de
  accesibilidad y letra grande.

**Acta del equipo:** *pendiente de completar.*

### I3. Decidir antes de gastar

**Cambios de práctica observados en el repositorio**

- Se probó el escaneo de boletas con un prototipo antes de comprometerse con
  él; al ver que era lento e inconsistente, se retiró del alcance y su código
  se archivó en una rama, en vez de seguir invirtiendo en él.
- La nueva función estrella se implementó en el orden acordado: primero la
  lógica de proyección con tests de datos fijos y después las pantallas.
- Cada requisito quedó en un commit propio que lo nombra, lo que hace
  rastreable cada historia.
- Se agregaron pruebas de rendimiento con límites concretos (RNF23).
- Los tests pasaron de 186 a 266 casos declarados.

**Acta del equipo:** *pendiente de completar.*

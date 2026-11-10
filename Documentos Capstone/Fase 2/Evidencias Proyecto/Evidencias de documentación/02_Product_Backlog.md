# Product Backlog priorizado: Peso a Peso

Cada requisito funcional (RF) del documento de requisitos se expresa como una
historia de usuario con su criterio de aceptación. El identificador RF se
mantiene para poder rastrear cada historia hasta el código, los tests y los
commits. RF26 a RF30 (escaneo de boletas) se retiraron del alcance y no se
reutilizan.

**Prioridad.** *MVP* = parte del producto mínimo original; *Alta*, *Media* y
*Baja* según el documento "Análisis y propuesta de mejoras". El orden de las
épicas es el orden de prioridad.

**Iteración.** Ver `03_Iteraciones.md`: I0 = MVP, I2 = ampliación de la
propuesta, I3 = función estrella.

## Épica 1. Registro de gastos

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

## Épica 2. Presupuestos y categorías

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

## Épica 3. Pagos fijos, habituales y cuotas

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

## Épica 4. Decidir antes de gastar (función estrella)

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

## Épica 5. Hábitos y revisión

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF37 | Como usuario, quiero revisar mis gastos recientes y marcar si valieron la pena. | La revisión se puede omitir. | Media | I2 | Hecho |
| RF66 | Como usuario, quiero revisar solo lo no esencial, cada semana o cada 15 días. | Un gasto de una categoría esencial no aparece en la revisión. | Alta | I3 | Hecho |

## Épica 6. Ahorro

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF13 | Como usuario, quiero crear metas de ahorro con un monto objetivo. | La meta muestra su progreso. | MVP | I0 | Hecho |
| RF14 | Como usuario, quiero registrar aportes a una meta. | El progreso se actualiza con cada aporte. | MVP | I0 | Hecho |
| RF19 | Como usuario, quiero accesos rápidos de aporte (monto fijo o % del presupuesto). | Un toque registra el aporte. | MVP | I0 | Hecho |
| RF51 | Como usuario, quiero que mis aportes descuenten del presupuesto sin contar como gasto. | Resumen separa gastado, ahorrado y disponible. | Alta | I2 | Hecho |
| RF52 | Como usuario, quiero pagar un gasto con lo ahorrado en una meta. | El gasto descuenta de la meta y no del presupuesto del mes. | Media | I2 | Hecho |

## Épica 7. Estadísticas

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

## Épica 8. Datos y respaldo

| ID | Historia de usuario | Criterio de aceptación | Prioridad | Iteración | Estado |
|---|---|---|---|---|---|
| RF16 | Como usuario, quiero exportar todos mis datos a un archivo. | El respaldo JSON incluye todas las tablas. | MVP | I0 | Hecho |
| RF17 | Como usuario, quiero restaurar mis datos desde un respaldo. | Se valida antes de reemplazar; acepta respaldos de versiones anteriores (RNF19). | MVP | I0 | Hecho |

## Resumen

| Estado | Historias |
|---|---|
| Hecho | 63 |
| Retiradas | 5 (RF26–RF30) |

Pendiente fuera del backlog funcional: notificación opcional de RF62 y
mediciones de rendimiento en un dispositivo de gama baja (RNF06–RNF08).

# Product Vision: Peso a Peso

Proyecto APT122 · Equipo: Martín Arroyo Quilcat, Carlos Loncuante, Renato Reinoso

## Visión

Que cualquier persona pueda saber, antes de comprar, si su plata le alcanza
este mes y los siguientes, sin entregar sus datos financieros a nadie.

## Problema

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

## Usuarios

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

## Propuesta de valor

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

## Función estrella: Decidir antes de gastar

La app proyecta el disponible de los meses siguientes como el presupuesto
total menos los pagos fijos, las cuotas ya comprometidas y el gasto variable
típico del usuario (la mediana de sus últimos tres meses). Sobre esa
proyección, el usuario simula una compra: ve mes a mes si le alcanza, la
compara con pagarla al contado o en otro número de cuotas, con interés si lo
hay, y puede comprarla de inmediato o dejarla en espera 48 horas, 7 o 30
días. Al vencer el plazo, la app vuelve a simularla con los datos de ese día
y le pregunta si todavía la quiere.

## Alcance

**Incluido:** registro manual de gastos, categorías, presupuestos
versionados por mes, métodos de pago y cuotas, pagos fijos y gastos
habituales, metas de ahorro, simulador y lista de espera, revisión de lo no
esencial, estadísticas, widget de Android, respaldo local, funcionamiento sin
conexión.

**Fuera de alcance:** vinculación bancaria, sincronización en la nube,
gestión compartida, múltiples monedas, registro de ingresos y escaneo de
boletas (prototipo archivado por ser lento e inconsistente).

## Indicadores de éxito

- Registrar un gasto frecuente toma un toque (acceso rápido o widget).
- La simulación de una compra se calcula en menos de 500 ms (RNF23).
- En la validación con 10 a 15 personas del público objetivo, la mayoría
  entiende sin ayuda si una compra en cuotas le alcanza.
- Ningún dato financiero sale del dispositivo: el APK no pide permiso de
  Internet (RNF01).

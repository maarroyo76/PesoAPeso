# Definition of Done

Una historia de usuario está **terminada** cuando cumple su criterio de
aceptación (ver `02_Product_Backlog.md`) y todos los puntos de esta lista. La
lista refleja lo que el proyecto ya exige en la práctica: buena parte la
verifica la integración continua en cada push y pull request.

## Código

- [ ] Cumple el criterio de aceptación de la historia, comprobado en la app.
- [ ] El código lleva comentarios con el identificador del requisito
  (por ejemplo `/// RF61: ...`), para rastrear cada historia hasta el código.
- [ ] Los cálculos (presupuestos, proyección, cuotas, estadísticas) están en
  funciones puras de `lib/core/utils/`, separadas de la interfaz (RNF24).
- [ ] `flutter analyze` termina sin problemas. *(CI)*
- [ ] El código está formateado con `dart format`.

## Pruebas

- [ ] Hay tests nuevos que cubren el criterio de aceptación: la lógica con
  datos fijos y, cuando toca la base o la pantalla, un test con base en
  memoria o un test de widget.
- [ ] Se prueban los casos borde que apliquen: meses sin historial, cambio de
  año, presupuesto ausente, montos en el límite.
- [ ] `flutter test` pasa completo, no solo los tests nuevos. *(CI)*

## Datos

- [ ] Si cambia el esquema, sube `schemaVersion`, la migración conserva los
  datos existentes y hay un test de migración desde la versión anterior.
- [ ] El código generado de Drift (`app_database.g.dart`) está al día. *(CI)*
- [ ] Si cambia lo que se guarda, el respaldo lo incluye, su versión sube y
  los respaldos anteriores se siguen aceptando (RNF19).
- [ ] Borrar o fusionar lo que la historia toca no deja datos huérfanos
  (claves foráneas o limpieza explícita).

## Seguridad y privacidad

- [ ] Ningún dato financiero sale del dispositivo: no se agregan permisos de
  Internet ni servicios en la nube (RNF01).
- [ ] No se guardan números completos de tarjeta, CVV ni vencimientos
  (RNF16).
- [ ] Los datos nuevos viven en la base cifrada; si algo tiene que quedar
  fuera de ella (por ejemplo, el widget), se justifica y se limita a lo
  mínimo.

## Experiencia

- [ ] Los textos para el usuario están en español de Chile, sin jerga técnica
  ni errores crudos (UX09).
- [ ] Lo tocable tiene nombre para el lector de pantalla y la pantalla no se
  desborda con letra grande (UX07, UX08).
- [ ] Las acciones destructivas o que registran algo se pueden deshacer
  (UX01, UX02).
- [ ] Se ve bien en tema claro y oscuro.

## Integración

- [ ] El trabajo está en una rama y entra a `main` con un pull request.
- [ ] Los commits tienen un título corto en español que dice qué cambió y
  nombran los requisitos que cubren.
- [ ] El documento de requisitos o la documentación técnica se actualizan si
  la historia cambia el alcance, el esquema o el formato del respaldo.

## Fuera de la DoD por ahora

Estos puntos se revisan antes de una entrega al público, no en cada historia:

- Prueba manual en un teléfono Android de gama baja.
- Medición de tiempos en dispositivo (RNF06–RNF08).
- Revisión de permisos del APK de release (`aapt2 dump permissions`).

# Retrospectivas

Las retrospectivas son reuniones del equipo al cierre de cada iteración. Las
actas se completan con lo conversado en cada reunión; este documento no
reemplaza esa conversación.

Para cada iteración se registran también los **cambios de práctica que se
ven en el repositorio**. Son hechos verificables (commits, pull requests,
tests) que muestran qué mejoró el equipo, y sirven como punto de partida para
la reunión.

## Plantilla de acta

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

## I1. Puesta en marcha y robustez

**Cambios de práctica observados en el repositorio**

- Se ordenaron los documentos APT en el repositorio (issue #1).
- Se pasó del identificador de ejemplo a `cl.pesoapeso.app` y se configuró
  la firma de release con un keystore fuera del control de versiones
  (issues #2 y #3).
- Las tareas se empezaron a registrar como issues de GitHub (#1 a #9).
- Los tests pasaron de 8 a 48 casos declarados.

**Acta del equipo:** *pendiente de completar.*

## I2. Ampliación de la propuesta

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

## I3. Decidir antes de gastar

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

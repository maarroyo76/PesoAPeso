# Plan de pruebas

## 1. Estrategia

Las pruebas son automáticas y viven en `test/`. Cada historia agrega sus
tests antes de darse por terminada (ver la Definition of Done en `01_Gestion_Agil.md`), y GitHub
Actions corre el análisis y todas las pruebas en cada push y pull request.

| Tipo | Qué prueba | Cómo |
|---|---|---|
| Unitarias | Funciones puras de `lib/core/utils/`: presupuestos, proyección, cuotas e interés, costo fijo, revisión, plazos | `test()` con datos fijos y fechas fijas, sin base ni interfaz |
| Integración con la base | Repositorios, transacciones, migraciones y respaldo | Base SQLite real en memoria (`NativeDatabase.memory()`) o en un archivo temporal para las migraciones |
| Integración de pantallas | Flujos completos: registrar, deshacer, simular y comprar, decidir un deseo | `testWidgets()` con la pantalla real sobre una base en memoria |
| Rendimiento | Simulación, estadísticas y consultas con 24 meses de historial | Cronómetro sobre el mejor de 5 intentos, con un límite por test |
| Seguridad | Integridad, validación de entradas y respaldos, privacidad de tarjetas | Tests automáticos más revisión de permisos del APK |
| Accesibilidad | Etiquetas para el lector de pantalla, área táctil y letra grande | Guías de accesibilidad de Flutter y pantallas con letra al 200% |

**Cómo ejecutarlas**

```
flutter analyze
flutter test
flutter test test/performance_test.dart --reporter expanded   # muestra los tiempos
```

**Resultado actual (10 de noviembre de 2026, rama `docs/estructura-capstone`):**
`flutter analyze` sin problemas y `flutter test` con **346 pruebas
aprobadas, 0 fallidas**, en 41 archivos.

## 2. Pruebas por tipo

### 2.1 Unitarias

| Archivo | Requisitos |
|---|---|
| `projection_test.dart` | RF58, RNF24: disponible proyectado, mediana del gasto variable, meses sin historial, sin presupuesto, ajustes del mes, cuotas que cruzan de año |
| `purchase_simulation_test.dart` (parte unitaria) | RF57, RF59: tasa, cuota fija, alternativas, costo total igual con tasa 0 |
| `fixed_costs_test.dart` (parte unitaria) | RF63, RF64: días de gastos habituales, costo fijo por mes, cuotas comprometidas, estadísticas de la lista de espera |
| `weekly_review_test.dart` (parte unitaria) | RF37, RF65–RF68: candidatos de la revisión, frecuencia, "no tanto" por categoría, cambios de esencial con fecha |
| `daily_allowance_test.dart` (parte unitaria) | RF38, RF51 |
| `payment_stats_test.dart` | RF33, RF40–RF43 |
| `installments_test.dart` (parte unitaria) | RF34, RF36: montos y fechas de las cuotas |
| `history_test.dart`, `quick_suggestion_test.dart`, `quick_widget_test.dart`, `amount_input_test.dart`, `remainder_month_test.dart`, `backup_validation_test.dart` | UX06, RF56, RF39, validación de montos, RF15, validación de respaldos |

### 2.2 Integración

| Archivo | Requisitos |
|---|---|
| `wishlist_test.dart` | RF60–RF62, RF68: crear, editar y decidir deseos; ahorrar en una meta; "Esperar" desde el simulador; comprar desde la tarjeta; migración v11 → v12 |
| `purchase_simulation_test.dart` (pantalla) | RF57, RF60, RF68: simular no escribe nada; "Comprar así" crea el mismo plan que el registro a mano |
| `essential_categories_test.dart` | RF65: catálogo, cambios con fecha, respaldo y migración v12 → v13 |
| `installments_test.dart`, `payment_methods_test.dart` | RF31–RF36, RNF18: planes de cuotas, prepago, métodos de pago, migración v9 → v10 |
| `habitual_test.dart`, `habitual_widgets_test.dart` | RF47–RF49: días pendientes, registrar desde la notificación, tarjeta de Resumen |
| `recurring_catchup_test.dart`, `recurring_origin_test.dart` | RF12, I4: catch-up de pagos fijos |
| `categories_archive_test.dart` | RF53, RF54, RF65: archivar, fusionar y marcar esencial |
| `backup_test.dart`, `backup_errors_test.dart` | RF16, RF17, RNF19 |
| `budget_migration_test.dart`, `migration_v8_test.dart` | Migraciones v1 → v2 y v7 → v8 |
| `agregar_undo_test.dart`, `undo_delete_test.dart`, `detail_sheet_test.dart` | UX01, UX02 |
| `daily_allowance_test.dart`, `total_budget_alert_test.dart`, `month_remainder_test.dart`, `use_savings_test.dart` | RF38, RF51, RF52, RF55 |
| `onboarding_catalog_test.dart`, `quick_defaults_test.dart`, `widget_test.dart` | RF23, RF45: arranque y onboarding |
| `ux_widgets_test.dart`, `expense_form_date_test.dart` | Gestos, tooltips y fechas antiguas |

### 2.3 Rendimiento

`performance_test.dart` arma 24 meses de historial con unos 6.100 gastos
(8 gastos variables al día, un arriendo mensual y una compra en 12 cuotas
cada mes).

| Prueba | Requisito | Límite | Resultado |
|---|---|---|---|
| Simular una compra en 48 cuotas y sus 5 alternativas | RNF23 | 500 ms | 110 ms |
| Estadísticas de 6 meses (costo fijo y "valió la pena") | RNF08 | 500 ms | 1 ms |
| Consultar los gastos de un mes en la base | RNF12 | 200 ms | 1 ms |

Los tiempos se midieron en el computador de desarrollo. Son una cota contra
regresiones, no la medición en un teléfono de gama baja que piden RNF06 a
RNF08, que sigue pendiente.

### 2.4 Seguridad

| Prueba | Archivo | Requisito |
|---|---|---|
| Solo se aceptan hasta 4 dígitos de una tarjeta, también en la base | `payment_methods_test.dart` | RNF16 |
| Las claves foráneas están activas y los borrados no dejan huérfanos | `data_integrity_test.dart` | RNF11 |
| Un respaldo malformado, con referencias rotas o de una versión futura se rechaza antes de tocar los datos | `backup_validation_test.dart`, `backup_errors_test.dart`, `wishlist_test.dart` | RF17, RNF04 |
| Un respaldo que falla deja los datos actuales intactos | `backup_errors_test.dart` | RNF11 |
| Los montos tienen un tope y solo aceptan dígitos | `amount_input_test.dart` | Validación de entradas |
| Simular no escribe nada en la base | `purchase_simulation_test.dart` | RF57 |
| El widget solo recibe etiqueta y monto de los accesos | `quick_widget_test.dart` | RNF01 |
| Revisión de permisos del APK de release | Manual: `aapt2 dump permissions` | RNF01 |

Las consultas a la base son parametrizadas por Drift (RNF03). El cifrado de
la base (RNF21) se verifica al abrirla: la app consulta `PRAGMA
cipher_version` y se niega a continuar si SQLCipher no está activo. Ese
chequeo corre en el teléfono y no en los tests, que usan el SQLite del
sistema.

### 2.5 Accesibilidad

| Prueba | Archivo |
|---|---|
| Lo tocable tiene nombre para el lector de pantalla | `accessibility_test.dart` |
| Las áreas táctiles miden al menos 48×48 | `accessibility_test.dart` |
| El texto cumple contraste AA (4,5:1) | `accessibility_test.dart` |
| Las pantallas no se desbordan con letra al 200% | `large_text_test.dart` |

Cubren las 6 pantallas principales (Resumen, Registrar, Presupuestos, Metas,
Estadísticas y Ajustes), en tema claro y oscuro. El simulador y la lista de
espera todavía no están en estos tests.

## 3. Pruebas por iteración

| Iteración | Tests declarados al cierre | Qué se agregó |
|---|---|---|
| I0. MVP | 8 (4 archivos) | Respaldo, migración v1 → v2, catch-up de pagos fijos, arranque |
| I1. Puesta en marcha | 48 (11 archivos) | Errores y validación de respaldos, montos, fechas antiguas, mes del remanente, migración v7 → v8, gestos de Resumen |
| I2. Ampliación | 186 (35 archivos) | Deshacer, accesibilidad, letra grande, integridad, categorías, métodos de pago, cuotas, gastos habituales, revisión, historial, estadísticas por método de pago, onboarding |
| I3. Decidir antes de gastar | 266 (40 archivos) | Proyección, simulador, lista de espera, costo fijo, categorías esenciales, revisión de lo no esencial, widget |
| Documentación | 270 (41 archivos) | Pruebas de rendimiento |

Los tests declarados son los `test()` y `testWidgets()` escritos en el
código. Al ejecutarlos salen más (346), porque algunos se generan dentro de
ciclos.

## 4. Pruebas manuales pendientes

Lo siguiente requiere un teléfono y no se puede automatizar en la CI:

| Prueba | Requisito |
|---|---|
| Registrar un gasto y ver el resumen actualizado en menos de 1 s en un teléfono de gama baja | RNF06 |
| Abrir la app en menos de 3 s con pagos fijos pendientes | RNF07 |
| Agregar el widget, registrar desde él con la app cerrada y abierta, y ver que se actualiza al cambiar los accesos | RF39 |
| Confirmar un gasto habitual desde la notificación con la app cerrada | RF48 |
| Reinstalar la app y restaurar un respaldo | RF17 |
| Contraste y lector de pantalla en el simulador y la lista de espera | RNF22 |
| Validación de la función estrella con 10 a 15 personas del público objetivo | RF57–RF64 |

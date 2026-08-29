# Peso a Peso

App de Flutter para registrar gastos e ingresos de forma manual, local-first
y sin conexión a bancos: "peso a peso". Base de datos cifrada en el
dispositivo (sin nube, sin sincronización), presupuestos por categoría y
totales, gastos recurrentes con motor de catch-up, metas de ahorro,
respaldo/restauración en JSON y estadísticas con gráficos.

## Stack

- **Flutter** / Dart (Material)
- **Riverpod** — manejo de estado (`flutter_riverpod`)
- **Drift** sobre SQLite cifrado con **SQLCipher** (`sqlcipher_flutter_libs`),
  clave de cifrado guardada en Keystore/Keychain vía `flutter_secure_storage`
- **fl_chart** — gráficos de torta y barras en Estadísticas
- **flutter_local_notifications** — avisos locales para gastos recurrentes
  generados automáticamente
- Soporte de plataformas: Android, iOS, web y Linux

## Estructura del proyecto

```
lib/
  core/            theme, providers, utils compartidos (alertas de presupuesto,
                   formato de moneda/fecha, notificaciones)
  data/
    local/         esquema Drift (app_database.dart) y conexión nativa/web
    repositories/  capa de acceso a datos por dominio
    backup/        exportación/restauración a JSON
  features/        una carpeta por pantalla (resumen, agregar gasto,
                   presupuestos, estadísticas, metas, recurrentes,
                   categorías, respaldo, onboarding)
test/              tests de widgets y de lógica (backup, migraciones,
                   catch-up de recurrentes)
brand/             logo e isotipo en SVG
assets/            fuentes (Crimson Pro, IBM Plex Mono) e ícono de la app
```

## Cómo correr el proyecto

1. `flutter pub get`
2. Generar el código de Drift:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Correr en el dispositivo/plataforma que prefieras:
   ```
   flutter run              # Android/Linux conectado
   flutter run -d chrome    # Web
   ```

### Soporte web (Drift + SQLite WASM)

El proyecto ya incluye `web/sqlite3.wasm` y `web/drift_worker.js`
precompilados para que `flutter run -d chrome` funcione sin pasos extra. Si
se actualiza la versión del paquete `sqlite3` en `pubspec.yaml`, hay que
regenerar ambos archivos (ver comentarios en `lib/data/local/connection_web.dart`
y `lib/data/local/connection_native.dart`).

### Cifrado (SQLCipher)

`lib/data/local/app_database.dart` deja marcado con un comentario
`NOTA IMPORTANTE` el punto exacto a revisar contra la guía oficial de drift
para SQLCipher antes de compilar un build de release.

## Tests

```
flutter analyze
flutter test
```
## Licencia

MIT (en inglés y español) — ver [LICENSE](LICENSE).

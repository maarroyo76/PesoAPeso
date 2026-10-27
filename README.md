# Peso a Peso

[![CI](https://github.com/maarroyo76/PesoAPeso/actions/workflows/ci.yml/badge.svg)](https://github.com/maarroyo76/PesoAPeso/actions/workflows/ci.yml)

App de Flutter para registrar gastos de forma manual, local-first y sin
conexión a bancos: "peso a peso". Base de datos cifrada en el dispositivo
(sin nube, sin sincronización), presupuestos por categoría y totales, gastos
recurrentes con motor de catch-up, metas de ahorro, respaldo/restauración en
JSON y estadísticas con gráficos. La app no registra ingresos.

## Stack

- **Flutter** / Dart (Material)
- **Riverpod** — manejo de estado (`flutter_riverpod`)
- **Drift** sobre SQLite cifrado con **SQLCipher** (`sqlcipher_flutter_libs`),
  clave de cifrado guardada en Keystore/Keychain vía `flutter_secure_storage`
- **fl_chart** — gráficos de torta y barras en Estadísticas
- **flutter_local_notifications** — avisos locales para gastos recurrentes
  generados automáticamente
- Soporte de plataformas: Android e iOS (objetivo principal); web y Linux
  para desarrollo y demostración (ver limitaciones abajo)

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
2. El código generado de Drift (`app_database.g.dart`) está versionado. Solo
   hay que regenerarlo al cambiar el esquema en `app_database.dart`:
   ```
   dart run build_runner build --delete-conflicting-outputs
   ```
   La CI falla si el archivo generado no coincide con el esquema.
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

**Limitación (RNF01):** en web la base usa SQLite WASM **sin cifrar**,
guardada en el almacenamiento del navegador. La versión web sirve para
desarrollo y demostración; los datos reales deben registrarse en Android o
iOS.

### Cifrado (SQLCipher)

En Android e iOS la base se cifra con SQLCipher (ver
`lib/data/local/connection_native.dart`). La clave se genera al primer
arranque (32 bytes de `Random.secure()`) y vive solo en Keystore/Keychain;
si SQLCipher no está disponible, la app se niega a abrir la base en vez de
guardar los datos sin cifrar. Android tiene `allowBackup="false"` para no
respaldar el archivo cifrado sin su clave.

Si la base no se puede abrir (por ejemplo, tras reinstalar la app y perder la
clave), la pantalla de error de arranque permite restaurar un respaldo JSON o
empezar de cero.

## Tests

```
flutter analyze
flutter test
```

Los tests de base de datos corren sobre el SQLite del sistema
(`libsqlite3.so.0`); en Debian/Ubuntu viene en el paquete `libsqlite3-0`.
GitHub Actions ejecuta ambos comandos en cada push y pull request
(`.github/workflows/ci.yml`).
## Licencia

MIT (en inglés y español) — ver [LICENSE](LICENSE).

# Manual técnico y de despliegue

## 1. Requisitos del entorno

| Herramienta | Versión | Para qué |
|---|---|---|
| Flutter | 3.44.8, canal estable (la misma que usa la CI) | Compilar y probar |
| Android SDK | El que instala Flutter; `minSdk` 24 | Compilar el APK |
| Java | 17 | Gradle de Android |
| SQLite del sistema | `libsqlite3.so.0` (paquete `libsqlite3-0` en Debian o Ubuntu) | Tests de base de datos en el computador |
| Xcode | Solo para compilar en iOS | — |

## 2. Instalación del proyecto

```
git clone https://github.com/maarroyo76/PesoAPeso.git
cd PesoAPeso
flutter pub get
```

No hay variables de entorno ni servicios externos que configurar: la app no
usa servidores ni claves de API.

## 3. Ejecutar en desarrollo

```
flutter run              # teléfono Android conectado, emulador o Linux
flutter run -d chrome    # versión web, solo para demostración
```

**Versión web.** Usa SQLite compilado a WebAssembly (`web/sqlite3.wasm` y
`web/drift_worker.js`, ya incluidos) y guarda los datos **sin cifrar** en el
navegador. Sirve para mostrar la app, no para datos reales. Si se actualiza
el paquete `sqlite3`, hay que regenerar ambos archivos (ver comentarios en
`lib/data/local/connection_web.dart`).

## 4. Verificar antes de integrar

```
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs   # si cambió el esquema
```

GitHub Actions (`.github/workflows/ci.yml`) corre estos mismos pasos en cada
push y pull request, en Ubuntu con Flutter 3.44.8, y falla si el código
generado de Drift no coincide con el esquema.

## 5. Despliegue en Android

### 5.1 Firma de release

La firma usa un keystore propio que **no está en el repositorio**:

- `android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y
  `keyPassword`.
- `android/app/upload-keystore.jks`, el keystore.

Ambos están en `android/.gitignore`. Quien tenga el keystore los copia en
esas rutas. Sin ellos, `flutter build` firma con la clave de debug, para que
cualquier integrante pueda compilar; ese APK sirve para probar, pero no para
publicar ni para actualizar una instalación firmada con la clave de release.

### 5.2 Compilar

```
flutter build apk --release          # APK para instalar directamente
flutter build appbundle --release    # AAB para Google Play
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk` (unos 77 MB).
La versión se toma de `version:` en `pubspec.yaml`.

### 5.3 Instalar

- **En un teléfono de prueba:** copiar el APK y abrirlo (requiere permitir
  instalar apps de origen desconocido), o `flutter install` con el teléfono
  conectado.
- **En Google Play:** subir el AAB a la consola de Google Play. La
  publicación en la tienda no forma parte de esta entrega.

### 5.4 Revisar permisos

Antes de entregar un APK, confirmar que no pide Internet (RNF01):

```
$ANDROID_HOME/build-tools/<versión>/aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

Permisos esperados: `RECEIVE_BOOT_COMPLETED`, `VIBRATE`,
`POST_NOTIFICATIONS` (notificaciones y recordatorios) y `WAKE_LOCK`,
`ACCESS_NETWORK_STATE` y `FOREGROUND_SERVICE` (agregados por WorkManager, que
llega con `home_widget`). No debe aparecer `INTERNET` ni `CAMERA`.

## 6. Datos y actualizaciones

**Cifrado.** En Android e iOS la base se cifra con SQLCipher. La clave
(32 bytes aleatorios) se crea al primer arranque y se guarda en
Keystore/Keychain. Si SQLCipher no está disponible, la app no abre la base.
Android tiene `allowBackup="false"`, así que el sistema no respalda el
archivo cifrado sin su clave.

**Migraciones.** Al instalar una versión nueva sobre una anterior, la base
se migra sola al abrir la app (`onUpgrade` en `app_database.dart`). El
esquema actual es el v13. Cada migración tiene un test.

**Respaldo.** Desde Ajustes → Respaldo el usuario exporta todo a un archivo
JSON (formato v4) y lo restaura en otro teléfono o tras reinstalar. La
restauración valida el archivo antes de tocar los datos y acepta respaldos de
versiones anteriores. El archivo **no está cifrado**, y la app lo advierte.

**Si la base no abre** (por ejemplo, tras reinstalar y perder la clave), la
pantalla de error de arranque ofrece restaurar un respaldo o empezar de cero.

## 7. Docker

El proyecto **no usa Docker**, y es una decisión de diseño, no una omisión:

- **No hay nada que desplegar en un servidor.** Peso a Peso es una app
  móvil local-first: no tiene backend, API ni base de datos en la nube. Todo
  corre en el teléfono del usuario y se instala como un APK.
- **Un contenedor no puede ejecutar la app.** Docker empaqueta servicios
  para Linux; una app de Android corre en el teléfono o en un emulador, no
  dentro de un contenedor.
- **La portabilidad ya la resuelve Flutter.** Un mismo código compila para
  Android e iOS (RNF14).
- **La reproducibilidad del build la resuelve la CI.** GitHub Actions compila
  y prueba el proyecto en una máquina limpia con una versión fija de Flutter
  en cada cambio, que es lo que aportaría un contenedor de build.

Si en el futuro se implementa la versión web con cuenta de usuario (RNF13),
ese backend sí se desplegaría con Docker y docker-compose.

## 8. Estructura del código

```
lib/
  main.dart            arranque, shell principal y manejo del widget
  core/
    providers/         providers de Riverpod
    utils/             lógica pura (presupuestos, proyección, cuotas, revisión)
    notifications/     notificaciones y recordatorios
    home_widget/       datos y enlaces del widget de inicio
    startup/           remanente del mes y sugerencia de presupuesto
    theme/             paleta, tipografías e íconos
    widgets/           componentes compartidos
  data/
    local/             esquema Drift, migraciones y conexión cifrada
    repositories/      acceso a datos por dominio
    backup/            validación del respaldo
  features/            una carpeta por pantalla
test/                  pruebas automáticas (ver 03_Plan_de_Pruebas.md)
android/app/src/main/  manifiesto, widget de inicio (Kotlin) y recursos
```

## 9. Problemas frecuentes

| Problema | Causa y solución |
|---|---|
| Los tests de base fallan con "libsqlite3.so.0 not found" | Falta el SQLite del sistema: instalar `libsqlite3-0` |
| La CI falla en "Código generado de Drift al día" | Se cambió el esquema sin regenerar: correr `build_runner` y comitear `app_database.g.dart` |
| El APK de release no actualiza la app instalada | Se firmó con la clave de debug: falta `key.properties` o el keystore |
| La app muestra la pantalla de error de arranque | No se pudo abrir la base (clave perdida o archivo dañado): restaurar un respaldo o empezar de cero |

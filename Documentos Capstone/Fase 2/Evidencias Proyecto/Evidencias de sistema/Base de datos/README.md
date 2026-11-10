# Evidencia de sistema: base de datos

Base local SQLite cifrada con SQLCipher, definida con Drift.

- Esquema, migraciones y consultas: [`lib/data/local/app_database.dart`](../../../../../lib/data/local/app_database.dart) (versión 13, 16 tablas).
- Formato del respaldo y su validación: [`lib/data/backup/backup_validation.dart`](../../../../../lib/data/backup/backup_validation.dart) (versión 4).
- Pruebas de migraciones y respaldo: [`test/`](../../../../../test) (por ejemplo `migration_v8_test.dart`, `wishlist_test.dart`, `essential_categories_test.dart` y `backup_test.dart`).

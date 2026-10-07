// Los errores al restaurar un respaldo salen como mensajes amigables (sin
// jerga técnica) y nunca tocan los datos actuales.

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/backup/backup_validation.dart';
import 'package:peso_a_peso/data/local/app_database.dart';
import 'package:peso_a_peso/data/repositories/backup_repository.dart';
import 'package:sqlite3/open.dart';

Uint8List _json(Object o) => Uint8List.fromList(utf8.encode(jsonEncode(o)));

void main() {
  setUpAll(() {
    open.overrideFor(
        OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  });

  late AppDatabase db;
  late BackupRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BackupRepository(db);
  });
  tearDown(() => db.close());

  Future<void> expectFriendlyFailure(Uint8List bytes, String message) async {
    await expectLater(
      repo.restoreFromBytes(bytes),
      throwsA(isA<FormatException>()
          .having((e) => e.message, 'message', message)),
    );
    // Los datos de siempre (las 6 categorías seed) siguen intactos.
    expect(await db.select(db.categories).get(), hasLength(6));
  }

  test('archivo vacío', () async {
    await expectFriendlyFailure(Uint8List(0), kBackupUnreadableMessage);
  });

  test('texto que no es JSON ni UTF-8 válido', () async {
    await expectFriendlyFailure(
        Uint8List.fromList(utf8.encode('esto no es json')),
        kBackupNotARespaldoMessage);
    await expectFriendlyFailure(
        Uint8List.fromList([0xff, 0xfe, 0x00, 0x80]), kBackupNotARespaldoMessage);
  });

  test('JSON válido pero de otra cosa', () async {
    await expectFriendlyFailure(_json({'hola': 'mundo'}), kBackupNotARespaldoMessage);
    await expectFriendlyFailure(_json([1, 2, 3]), kBackupNotARespaldoMessage);
  });

  test('respaldo dañado (referencias rotas o campos con tipo equivocado)',
      () async {
    final good = await db.exportAllData();

    final orphan = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
    (orphan['transactions'] as List).add(
        {'id': 1, 'categoryId': 'no_existe', 'amount': 5, 'date': 0});
    await expectFriendlyFailure(_json(orphan), kBackupCorruptMessage);

    final badTypes = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
    (badTypes['categories'] as List).first['name'] = 12345;
    await expectFriendlyFailure(_json(badTypes), kBackupCorruptMessage);
  });

  test('archivo demasiado grande', () async {
    await expectFriendlyFailure(
        Uint8List(kMaxBackupBytes + 1), kBackupTooLargeMessage);
  });

  test('ningún mensaje muestra jerga técnica', () {
    for (final m in [
      kBackupNotARespaldoMessage,
      kBackupCorruptMessage,
      kBackupUnreadableMessage,
      kBackupTooLargeMessage,
    ]) {
      expect(m.toLowerCase(), isNot(contains('exception')));
      expect(m.toLowerCase(), isNot(contains('type')));
      expect(m.toLowerCase(), isNot(contains('null')));
    }
  });

  test('un respaldo válido se restaura', () async {
    final good = await db.exportAllData();
    expect(await repo.restoreFromBytes(_json(good)), isTrue);
    expect(await db.select(db.categories).get(), hasLength(6));
  });
}

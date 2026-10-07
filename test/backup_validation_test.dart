import 'package:flutter_test/flutter_test.dart';
import 'package:peso_a_peso/data/backup/backup_validation.dart';

Map<String, dynamic> _valid() => {
      'version': 1,
      'categories': [
        {'id': 'a', 'name': 'A', 'colorValue': 1, 'iconKey': 'home'}
      ],
      'categoryBudgets': [
        {'categoryId': 'a', 'year': 2026, 'month': 1, 'amount': 10}
      ],
      'transactions': [
        {'id': 1, 'categoryId': 'a', 'amount': 5}
      ],
      'recurringTemplates': [],
      'savingsGoals': [
        {'id': 1, 'name': 'M', 'targetAmount': 10}
      ],
      'savingsContributions': [
        {'id': 1, 'goalId': 1, 'amount': 5}
      ],
      'savingsQuickAdds': [],
    };

void main() {
  test('acepta un respaldo válido (sin tablas opcionales)', () {
    expect(() => validateBackupData(_valid()), returnsNormally);
  });

  test('rechaza lo que no es un objeto o no trae versión', () {
    expect(() => validateBackupData([]), throwsFormatException);
    expect(() => validateBackupData(_valid()..remove('version')),
        throwsFormatException);
  });

  test('rechaza una versión más nueva que la soportada', () {
    final data = _valid()..['version'] = kBackupFormatVersion + 1;
    expect(
        () => validateBackupData(data),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('más nueva'))));
  });

  test('rechaza tablas faltantes o con tipo equivocado', () {
    expect(() => validateBackupData(_valid()..remove('transactions')),
        throwsFormatException);
    expect(() => validateBackupData(_valid()..['categories'] = 'x'),
        throwsFormatException);
    expect(() => validateBackupData(_valid()..['categories'] = [1]),
        throwsFormatException);
  });

  test('rechaza referencias huérfanas a categorías y metas', () {
    final orphanTx = _valid()
      ..['transactions'] = [
        {'id': 1, 'categoryId': 'borrada', 'amount': 5}
      ];
    expect(() => validateBackupData(orphanTx), throwsFormatException);

    final orphanContribution = _valid()
      ..['savingsContributions'] = [
        {'id': 1, 'goalId': 99, 'amount': 5}
      ];
    expect(() => validateBackupData(orphanContribution), throwsFormatException);
  });
}

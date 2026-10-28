// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
      'color_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('category'));
  @override
  List<GeneratedColumn> get $columns => [id, name, colorValue, iconKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_value'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  const Category(
      {required this.id,
      required this.name,
      required this.colorValue,
      required this.iconKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    map['icon_key'] = Variable<String>(iconKey);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
      iconKey: Value(iconKey),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconKey': serializer.toJson<String>(iconKey),
    };
  }

  Category copyWith(
          {String? id, String? name, int? colorValue, String? iconKey}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        iconKey: iconKey ?? this.iconKey,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconKey: $iconKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, iconKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.iconKey == this.iconKey);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<String> iconKey;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required int colorValue,
    this.iconKey = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        colorValue = Value(colorValue);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<String>? iconKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (iconKey != null) 'icon_key': iconKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? colorValue,
      Value<String>? iconKey,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconKey: $iconKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryBudgetsTable extends CategoryBudgets
    with TableInfo<$CategoryBudgetsTable, CategoryBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [categoryId, year, month, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_budgets';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryBudget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryId, year, month};
  @override
  CategoryBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryBudget(
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $CategoryBudgetsTable createAlias(String alias) {
    return $CategoryBudgetsTable(attachedDatabase, alias);
  }
}

class CategoryBudget extends DataClass implements Insertable<CategoryBudget> {
  final String categoryId;
  final int year;
  final int month;
  final int amount;
  const CategoryBudget(
      {required this.categoryId,
      required this.year,
      required this.month,
      required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_id'] = Variable<String>(categoryId);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  CategoryBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CategoryBudgetsCompanion(
      categoryId: Value(categoryId),
      year: Value(year),
      month: Value(month),
      amount: Value(amount),
    );
  }

  factory CategoryBudget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryBudget(
      categoryId: serializer.fromJson<String>(json['categoryId']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryId': serializer.toJson<String>(categoryId),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'amount': serializer.toJson<int>(amount),
    };
  }

  CategoryBudget copyWith(
          {String? categoryId, int? year, int? month, int? amount}) =>
      CategoryBudget(
        categoryId: categoryId ?? this.categoryId,
        year: year ?? this.year,
        month: month ?? this.month,
        amount: amount ?? this.amount,
      );
  CategoryBudget copyWithCompanion(CategoryBudgetsCompanion data) {
    return CategoryBudget(
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudget(')
          ..write('categoryId: $categoryId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryId, year, month, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryBudget &&
          other.categoryId == this.categoryId &&
          other.year == this.year &&
          other.month == this.month &&
          other.amount == this.amount);
}

class CategoryBudgetsCompanion extends UpdateCompanion<CategoryBudget> {
  final Value<String> categoryId;
  final Value<int> year;
  final Value<int> month;
  final Value<int> amount;
  final Value<int> rowid;
  const CategoryBudgetsCompanion({
    this.categoryId = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryBudgetsCompanion.insert({
    required String categoryId,
    required int year,
    required int month,
    required int amount,
    this.rowid = const Value.absent(),
  })  : categoryId = Value(categoryId),
        year = Value(year),
        month = Value(month),
        amount = Value(amount);
  static Insertable<CategoryBudget> custom({
    Expression<String>? categoryId,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryId != null) 'category_id': categoryId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryBudgetsCompanion copyWith(
      {Value<String>? categoryId,
      Value<int>? year,
      Value<int>? month,
      Value<int>? amount,
      Value<int>? rowid}) {
    return CategoryBudgetsCompanion(
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryBudgetsCompanion(')
          ..write('categoryId: $categoryId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringTemplatesTable extends RecurringTemplates
    with TableInfo<$RecurringTemplatesTable, RecurringTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dayOfMonthMeta =
      const VerificationMeta('dayOfMonth');
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
      'day_of_month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _lastGeneratedYearMonthMeta =
      const VerificationMeta('lastGeneratedYearMonth');
  @override
  late final GeneratedColumn<int> lastGeneratedYearMonth = GeneratedColumn<int>(
      'last_generated_year_month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        categoryId,
        amount,
        note,
        dayOfMonth,
        active,
        lastGeneratedYearMonth
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_templates';
  @override
  VerificationContext validateIntegrity(Insertable<RecurringTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
          _dayOfMonthMeta,
          dayOfMonth.isAcceptableOrUnknown(
              data['day_of_month']!, _dayOfMonthMeta));
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('last_generated_year_month')) {
      context.handle(
          _lastGeneratedYearMonthMeta,
          lastGeneratedYearMonth.isAcceptableOrUnknown(
              data['last_generated_year_month']!, _lastGeneratedYearMonthMeta));
    } else if (isInserting) {
      context.missing(_lastGeneratedYearMonthMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      dayOfMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_month'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      lastGeneratedYearMonth: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_generated_year_month'])!,
    );
  }

  @override
  $RecurringTemplatesTable createAlias(String alias) {
    return $RecurringTemplatesTable(attachedDatabase, alias);
  }
}

class RecurringTemplate extends DataClass
    implements Insertable<RecurringTemplate> {
  final int id;
  final String categoryId;
  final int amount;
  final String note;
  final int dayOfMonth;
  final bool active;
  final int lastGeneratedYearMonth;
  const RecurringTemplate(
      {required this.id,
      required this.categoryId,
      required this.amount,
      required this.note,
      required this.dayOfMonth,
      required this.active,
      required this.lastGeneratedYearMonth});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['amount'] = Variable<int>(amount);
    map['note'] = Variable<String>(note);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['active'] = Variable<bool>(active);
    map['last_generated_year_month'] = Variable<int>(lastGeneratedYearMonth);
    return map;
  }

  RecurringTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RecurringTemplatesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      amount: Value(amount),
      note: Value(note),
      dayOfMonth: Value(dayOfMonth),
      active: Value(active),
      lastGeneratedYearMonth: Value(lastGeneratedYearMonth),
    );
  }

  factory RecurringTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTemplate(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      active: serializer.fromJson<bool>(json['active']),
      lastGeneratedYearMonth:
          serializer.fromJson<int>(json['lastGeneratedYearMonth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'amount': serializer.toJson<int>(amount),
      'note': serializer.toJson<String>(note),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'active': serializer.toJson<bool>(active),
      'lastGeneratedYearMonth': serializer.toJson<int>(lastGeneratedYearMonth),
    };
  }

  RecurringTemplate copyWith(
          {int? id,
          String? categoryId,
          int? amount,
          String? note,
          int? dayOfMonth,
          bool? active,
          int? lastGeneratedYearMonth}) =>
      RecurringTemplate(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        active: active ?? this.active,
        lastGeneratedYearMonth:
            lastGeneratedYearMonth ?? this.lastGeneratedYearMonth,
      );
  RecurringTemplate copyWithCompanion(RecurringTemplatesCompanion data) {
    return RecurringTemplate(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      dayOfMonth:
          data.dayOfMonth.present ? data.dayOfMonth.value : this.dayOfMonth,
      active: data.active.present ? data.active.value : this.active,
      lastGeneratedYearMonth: data.lastGeneratedYearMonth.present
          ? data.lastGeneratedYearMonth.value
          : this.lastGeneratedYearMonth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplate(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('active: $active, ')
          ..write('lastGeneratedYearMonth: $lastGeneratedYearMonth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, categoryId, amount, note, dayOfMonth, active, lastGeneratedYearMonth);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTemplate &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.dayOfMonth == this.dayOfMonth &&
          other.active == this.active &&
          other.lastGeneratedYearMonth == this.lastGeneratedYearMonth);
}

class RecurringTemplatesCompanion extends UpdateCompanion<RecurringTemplate> {
  final Value<int> id;
  final Value<String> categoryId;
  final Value<int> amount;
  final Value<String> note;
  final Value<int> dayOfMonth;
  final Value<bool> active;
  final Value<int> lastGeneratedYearMonth;
  const RecurringTemplatesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.active = const Value.absent(),
    this.lastGeneratedYearMonth = const Value.absent(),
  });
  RecurringTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String categoryId,
    required int amount,
    this.note = const Value.absent(),
    required int dayOfMonth,
    this.active = const Value.absent(),
    required int lastGeneratedYearMonth,
  })  : categoryId = Value(categoryId),
        amount = Value(amount),
        dayOfMonth = Value(dayOfMonth),
        lastGeneratedYearMonth = Value(lastGeneratedYearMonth);
  static Insertable<RecurringTemplate> custom({
    Expression<int>? id,
    Expression<String>? categoryId,
    Expression<int>? amount,
    Expression<String>? note,
    Expression<int>? dayOfMonth,
    Expression<bool>? active,
    Expression<int>? lastGeneratedYearMonth,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (active != null) 'active': active,
      if (lastGeneratedYearMonth != null)
        'last_generated_year_month': lastGeneratedYearMonth,
    });
  }

  RecurringTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? categoryId,
      Value<int>? amount,
      Value<String>? note,
      Value<int>? dayOfMonth,
      Value<bool>? active,
      Value<int>? lastGeneratedYearMonth}) {
    return RecurringTemplatesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      active: active ?? this.active,
      lastGeneratedYearMonth:
          lastGeneratedYearMonth ?? this.lastGeneratedYearMonth,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (lastGeneratedYearMonth.present) {
      map['last_generated_year_month'] =
          Variable<int>(lastGeneratedYearMonth.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('active: $active, ')
          ..write('lastGeneratedYearMonth: $lastGeneratedYearMonth')
          ..write(')'))
        .toString();
  }
}

class $PaymentMethodsTable extends PaymentMethods
    with TableInfo<$PaymentMethodsTable, PaymentMethod> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentMethodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
      'alias', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
      'color_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
      'last4', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _billingDayMeta =
      const VerificationMeta('billingDay');
  @override
  late final GeneratedColumn<int> billingDay = GeneratedColumn<int>(
      'billing_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
      'due_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, alias, kind, colorValue, last4, billingDay, dueDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payment_methods';
  @override
  VerificationContext validateIntegrity(Insertable<PaymentMethod> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alias')) {
      context.handle(
          _aliasMeta, alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta));
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
          _last4Meta, last4.isAcceptableOrUnknown(data['last4']!, _last4Meta));
    }
    if (data.containsKey('billing_day')) {
      context.handle(
          _billingDayMeta,
          billingDay.isAcceptableOrUnknown(
              data['billing_day']!, _billingDayMeta));
    }
    if (data.containsKey('due_day')) {
      context.handle(_dueDayMeta,
          dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentMethod map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentMethod(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      alias: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alias'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_value'])!,
      last4: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last4']),
      billingDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}billing_day']),
      dueDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_day']),
    );
  }

  @override
  $PaymentMethodsTable createAlias(String alias) {
    return $PaymentMethodsTable(attachedDatabase, alias);
  }
}

class PaymentMethod extends DataClass implements Insertable<PaymentMethod> {
  final int id;
  final String alias;
  final String kind;
  final int colorValue;
  final String? last4;
  final int? billingDay;
  final int? dueDay;
  const PaymentMethod(
      {required this.id,
      required this.alias,
      required this.kind,
      required this.colorValue,
      this.last4,
      this.billingDay,
      this.dueDay});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alias'] = Variable<String>(alias);
    map['kind'] = Variable<String>(kind);
    map['color_value'] = Variable<int>(colorValue);
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    if (!nullToAbsent || billingDay != null) {
      map['billing_day'] = Variable<int>(billingDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    return map;
  }

  PaymentMethodsCompanion toCompanion(bool nullToAbsent) {
    return PaymentMethodsCompanion(
      id: Value(id),
      alias: Value(alias),
      kind: Value(kind),
      colorValue: Value(colorValue),
      last4:
          last4 == null && nullToAbsent ? const Value.absent() : Value(last4),
      billingDay: billingDay == null && nullToAbsent
          ? const Value.absent()
          : Value(billingDay),
      dueDay:
          dueDay == null && nullToAbsent ? const Value.absent() : Value(dueDay),
    );
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentMethod(
      id: serializer.fromJson<int>(json['id']),
      alias: serializer.fromJson<String>(json['alias']),
      kind: serializer.fromJson<String>(json['kind']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      last4: serializer.fromJson<String?>(json['last4']),
      billingDay: serializer.fromJson<int?>(json['billingDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alias': serializer.toJson<String>(alias),
      'kind': serializer.toJson<String>(kind),
      'colorValue': serializer.toJson<int>(colorValue),
      'last4': serializer.toJson<String?>(last4),
      'billingDay': serializer.toJson<int?>(billingDay),
      'dueDay': serializer.toJson<int?>(dueDay),
    };
  }

  PaymentMethod copyWith(
          {int? id,
          String? alias,
          String? kind,
          int? colorValue,
          Value<String?> last4 = const Value.absent(),
          Value<int?> billingDay = const Value.absent(),
          Value<int?> dueDay = const Value.absent()}) =>
      PaymentMethod(
        id: id ?? this.id,
        alias: alias ?? this.alias,
        kind: kind ?? this.kind,
        colorValue: colorValue ?? this.colorValue,
        last4: last4.present ? last4.value : this.last4,
        billingDay: billingDay.present ? billingDay.value : this.billingDay,
        dueDay: dueDay.present ? dueDay.value : this.dueDay,
      );
  PaymentMethod copyWithCompanion(PaymentMethodsCompanion data) {
    return PaymentMethod(
      id: data.id.present ? data.id.value : this.id,
      alias: data.alias.present ? data.alias.value : this.alias,
      kind: data.kind.present ? data.kind.value : this.kind,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      last4: data.last4.present ? data.last4.value : this.last4,
      billingDay:
          data.billingDay.present ? data.billingDay.value : this.billingDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethod(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('kind: $kind, ')
          ..write('colorValue: $colorValue, ')
          ..write('last4: $last4, ')
          ..write('billingDay: $billingDay, ')
          ..write('dueDay: $dueDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, alias, kind, colorValue, last4, billingDay, dueDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentMethod &&
          other.id == this.id &&
          other.alias == this.alias &&
          other.kind == this.kind &&
          other.colorValue == this.colorValue &&
          other.last4 == this.last4 &&
          other.billingDay == this.billingDay &&
          other.dueDay == this.dueDay);
}

class PaymentMethodsCompanion extends UpdateCompanion<PaymentMethod> {
  final Value<int> id;
  final Value<String> alias;
  final Value<String> kind;
  final Value<int> colorValue;
  final Value<String?> last4;
  final Value<int?> billingDay;
  final Value<int?> dueDay;
  const PaymentMethodsCompanion({
    this.id = const Value.absent(),
    this.alias = const Value.absent(),
    this.kind = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.last4 = const Value.absent(),
    this.billingDay = const Value.absent(),
    this.dueDay = const Value.absent(),
  });
  PaymentMethodsCompanion.insert({
    this.id = const Value.absent(),
    required String alias,
    required String kind,
    required int colorValue,
    this.last4 = const Value.absent(),
    this.billingDay = const Value.absent(),
    this.dueDay = const Value.absent(),
  })  : alias = Value(alias),
        kind = Value(kind),
        colorValue = Value(colorValue);
  static Insertable<PaymentMethod> custom({
    Expression<int>? id,
    Expression<String>? alias,
    Expression<String>? kind,
    Expression<int>? colorValue,
    Expression<String>? last4,
    Expression<int>? billingDay,
    Expression<int>? dueDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alias != null) 'alias': alias,
      if (kind != null) 'kind': kind,
      if (colorValue != null) 'color_value': colorValue,
      if (last4 != null) 'last4': last4,
      if (billingDay != null) 'billing_day': billingDay,
      if (dueDay != null) 'due_day': dueDay,
    });
  }

  PaymentMethodsCompanion copyWith(
      {Value<int>? id,
      Value<String>? alias,
      Value<String>? kind,
      Value<int>? colorValue,
      Value<String?>? last4,
      Value<int?>? billingDay,
      Value<int?>? dueDay}) {
    return PaymentMethodsCompanion(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      kind: kind ?? this.kind,
      colorValue: colorValue ?? this.colorValue,
      last4: last4 ?? this.last4,
      billingDay: billingDay ?? this.billingDay,
      dueDay: dueDay ?? this.dueDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (billingDay.present) {
      map['billing_day'] = Variable<int>(billingDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentMethodsCompanion(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('kind: $kind, ')
          ..write('colorValue: $colorValue, ')
          ..write('last4: $last4, ')
          ..write('billingDay: $billingDay, ')
          ..write('dueDay: $dueDay')
          ..write(')'))
        .toString();
  }
}

class $InstallmentPlansTable extends InstallmentPlans
    with TableInfo<$InstallmentPlansTable, InstallmentPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _paymentMethodIdMeta =
      const VerificationMeta('paymentMethodId');
  @override
  late final GeneratedColumn<int> paymentMethodId = GeneratedColumn<int>(
      'payment_method_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<int> totalAmount = GeneratedColumn<int>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _installmentCountMeta =
      const VerificationMeta('installmentCount');
  @override
  late final GeneratedColumn<int> installmentCount = GeneratedColumn<int>(
      'installment_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _purchaseDateMeta =
      const VerificationMeta('purchaseDate');
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
      'purchase_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _prepaidMeta =
      const VerificationMeta('prepaid');
  @override
  late final GeneratedColumn<bool> prepaid = GeneratedColumn<bool>(
      'prepaid', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("prepaid" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        paymentMethodId,
        categoryId,
        note,
        totalAmount,
        installmentCount,
        purchaseDate,
        prepaid
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_plans';
  @override
  VerificationContext validateIntegrity(Insertable<InstallmentPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
          _paymentMethodIdMeta,
          paymentMethodId.isAcceptableOrUnknown(
              data['payment_method_id']!, _paymentMethodIdMeta));
    } else if (isInserting) {
      context.missing(_paymentMethodIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('installment_count')) {
      context.handle(
          _installmentCountMeta,
          installmentCount.isAcceptableOrUnknown(
              data['installment_count']!, _installmentCountMeta));
    } else if (isInserting) {
      context.missing(_installmentCountMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
          _purchaseDateMeta,
          purchaseDate.isAcceptableOrUnknown(
              data['purchase_date']!, _purchaseDateMeta));
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('prepaid')) {
      context.handle(_prepaidMeta,
          prepaid.isAcceptableOrUnknown(data['prepaid']!, _prepaidMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallmentPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      paymentMethodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_method_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_amount'])!,
      installmentCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}installment_count'])!,
      purchaseDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}purchase_date'])!,
      prepaid: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}prepaid'])!,
    );
  }

  @override
  $InstallmentPlansTable createAlias(String alias) {
    return $InstallmentPlansTable(attachedDatabase, alias);
  }
}

class InstallmentPlan extends DataClass implements Insertable<InstallmentPlan> {
  final int id;
  final int paymentMethodId;
  final String categoryId;
  final String note;
  final int totalAmount;
  final int installmentCount;
  final DateTime purchaseDate;

  /// RF35: prepagado; las cuotas futuras se reemplazaron por un solo pago.
  final bool prepaid;
  const InstallmentPlan(
      {required this.id,
      required this.paymentMethodId,
      required this.categoryId,
      required this.note,
      required this.totalAmount,
      required this.installmentCount,
      required this.purchaseDate,
      required this.prepaid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payment_method_id'] = Variable<int>(paymentMethodId);
    map['category_id'] = Variable<String>(categoryId);
    map['note'] = Variable<String>(note);
    map['total_amount'] = Variable<int>(totalAmount);
    map['installment_count'] = Variable<int>(installmentCount);
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['prepaid'] = Variable<bool>(prepaid);
    return map;
  }

  InstallmentPlansCompanion toCompanion(bool nullToAbsent) {
    return InstallmentPlansCompanion(
      id: Value(id),
      paymentMethodId: Value(paymentMethodId),
      categoryId: Value(categoryId),
      note: Value(note),
      totalAmount: Value(totalAmount),
      installmentCount: Value(installmentCount),
      purchaseDate: Value(purchaseDate),
      prepaid: Value(prepaid),
    );
  }

  factory InstallmentPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentPlan(
      id: serializer.fromJson<int>(json['id']),
      paymentMethodId: serializer.fromJson<int>(json['paymentMethodId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      note: serializer.fromJson<String>(json['note']),
      totalAmount: serializer.fromJson<int>(json['totalAmount']),
      installmentCount: serializer.fromJson<int>(json['installmentCount']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      prepaid: serializer.fromJson<bool>(json['prepaid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'paymentMethodId': serializer.toJson<int>(paymentMethodId),
      'categoryId': serializer.toJson<String>(categoryId),
      'note': serializer.toJson<String>(note),
      'totalAmount': serializer.toJson<int>(totalAmount),
      'installmentCount': serializer.toJson<int>(installmentCount),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'prepaid': serializer.toJson<bool>(prepaid),
    };
  }

  InstallmentPlan copyWith(
          {int? id,
          int? paymentMethodId,
          String? categoryId,
          String? note,
          int? totalAmount,
          int? installmentCount,
          DateTime? purchaseDate,
          bool? prepaid}) =>
      InstallmentPlan(
        id: id ?? this.id,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        totalAmount: totalAmount ?? this.totalAmount,
        installmentCount: installmentCount ?? this.installmentCount,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        prepaid: prepaid ?? this.prepaid,
      );
  InstallmentPlan copyWithCompanion(InstallmentPlansCompanion data) {
    return InstallmentPlan(
      id: data.id.present ? data.id.value : this.id,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      installmentCount: data.installmentCount.present
          ? data.installmentCount.value
          : this.installmentCount,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      prepaid: data.prepaid.present ? data.prepaid.value : this.prepaid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlan(')
          ..write('id: $id, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('prepaid: $prepaid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, paymentMethodId, categoryId, note,
      totalAmount, installmentCount, purchaseDate, prepaid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentPlan &&
          other.id == this.id &&
          other.paymentMethodId == this.paymentMethodId &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.totalAmount == this.totalAmount &&
          other.installmentCount == this.installmentCount &&
          other.purchaseDate == this.purchaseDate &&
          other.prepaid == this.prepaid);
}

class InstallmentPlansCompanion extends UpdateCompanion<InstallmentPlan> {
  final Value<int> id;
  final Value<int> paymentMethodId;
  final Value<String> categoryId;
  final Value<String> note;
  final Value<int> totalAmount;
  final Value<int> installmentCount;
  final Value<DateTime> purchaseDate;
  final Value<bool> prepaid;
  const InstallmentPlansCompanion({
    this.id = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.installmentCount = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.prepaid = const Value.absent(),
  });
  InstallmentPlansCompanion.insert({
    this.id = const Value.absent(),
    required int paymentMethodId,
    required String categoryId,
    this.note = const Value.absent(),
    required int totalAmount,
    required int installmentCount,
    required DateTime purchaseDate,
    this.prepaid = const Value.absent(),
  })  : paymentMethodId = Value(paymentMethodId),
        categoryId = Value(categoryId),
        totalAmount = Value(totalAmount),
        installmentCount = Value(installmentCount),
        purchaseDate = Value(purchaseDate);
  static Insertable<InstallmentPlan> custom({
    Expression<int>? id,
    Expression<int>? paymentMethodId,
    Expression<String>? categoryId,
    Expression<String>? note,
    Expression<int>? totalAmount,
    Expression<int>? installmentCount,
    Expression<DateTime>? purchaseDate,
    Expression<bool>? prepaid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (installmentCount != null) 'installment_count': installmentCount,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (prepaid != null) 'prepaid': prepaid,
    });
  }

  InstallmentPlansCompanion copyWith(
      {Value<int>? id,
      Value<int>? paymentMethodId,
      Value<String>? categoryId,
      Value<String>? note,
      Value<int>? totalAmount,
      Value<int>? installmentCount,
      Value<DateTime>? purchaseDate,
      Value<bool>? prepaid}) {
    return InstallmentPlansCompanion(
      id: id ?? this.id,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentCount: installmentCount ?? this.installmentCount,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      prepaid: prepaid ?? this.prepaid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<int>(paymentMethodId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<int>(totalAmount.value);
    }
    if (installmentCount.present) {
      map['installment_count'] = Variable<int>(installmentCount.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (prepaid.present) {
      map['prepaid'] = Variable<bool>(prepaid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlansCompanion(')
          ..write('id: $id, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('prepaid: $prepaid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isRecurringMeta =
      const VerificationMeta('isRecurring');
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
      'is_recurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_recurring" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recurringTemplateIdMeta =
      const VerificationMeta('recurringTemplateId');
  @override
  late final GeneratedColumn<int> recurringTemplateId = GeneratedColumn<int>(
      'recurring_template_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _paymentMethodIdMeta =
      const VerificationMeta('paymentMethodId');
  @override
  late final GeneratedColumn<int> paymentMethodId = GeneratedColumn<int>(
      'payment_method_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _installmentPlanIdMeta =
      const VerificationMeta('installmentPlanId');
  @override
  late final GeneratedColumn<int> installmentPlanId = GeneratedColumn<int>(
      'installment_plan_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _installmentNumberMeta =
      const VerificationMeta('installmentNumber');
  @override
  late final GeneratedColumn<int> installmentNumber = GeneratedColumn<int>(
      'installment_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        categoryId,
        amount,
        date,
        note,
        isRecurring,
        recurringTemplateId,
        paymentMethodId,
        installmentPlanId,
        installmentNumber
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
          _isRecurringMeta,
          isRecurring.isAcceptableOrUnknown(
              data['is_recurring']!, _isRecurringMeta));
    }
    if (data.containsKey('recurring_template_id')) {
      context.handle(
          _recurringTemplateIdMeta,
          recurringTemplateId.isAcceptableOrUnknown(
              data['recurring_template_id']!, _recurringTemplateIdMeta));
    }
    if (data.containsKey('payment_method_id')) {
      context.handle(
          _paymentMethodIdMeta,
          paymentMethodId.isAcceptableOrUnknown(
              data['payment_method_id']!, _paymentMethodIdMeta));
    }
    if (data.containsKey('installment_plan_id')) {
      context.handle(
          _installmentPlanIdMeta,
          installmentPlanId.isAcceptableOrUnknown(
              data['installment_plan_id']!, _installmentPlanIdMeta));
    }
    if (data.containsKey('installment_number')) {
      context.handle(
          _installmentNumberMeta,
          installmentNumber.isAcceptableOrUnknown(
              data['installment_number']!, _installmentNumberMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      isRecurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_recurring'])!,
      recurringTemplateId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}recurring_template_id']),
      paymentMethodId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}payment_method_id']),
      installmentPlanId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}installment_plan_id']),
      installmentNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}installment_number']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final String categoryId;
  final int amount;
  final DateTime date;
  final String note;
  final bool isRecurring;

  /// Plantilla recurrente (RF12) que generó este gasto, para poder ir de un
  /// gasto a su recurrente. Null en gastos manuales, en los anteriores a v9
  /// que no se pudieron enlazar, y si la plantilla se eliminó.
  final int? recurringTemplateId;

  /// RF32: con qué se pagó. Null = "Sin especificar": todos los gastos
  /// anteriores a v10 (RNF18) y los que el usuario no asignó.
  final int? paymentMethodId;

  /// RF34: plan de cuotas al que pertenece, y qué cuota es (desde 1). El
  /// prepago (RF35) también lleva el plan, pero sin número de cuota.
  final int? installmentPlanId;
  final int? installmentNumber;
  const Transaction(
      {required this.id,
      required this.categoryId,
      required this.amount,
      required this.date,
      required this.note,
      required this.isRecurring,
      this.recurringTemplateId,
      this.paymentMethodId,
      this.installmentPlanId,
      this.installmentNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<DateTime>(date);
    map['note'] = Variable<String>(note);
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurringTemplateId != null) {
      map['recurring_template_id'] = Variable<int>(recurringTemplateId);
    }
    if (!nullToAbsent || paymentMethodId != null) {
      map['payment_method_id'] = Variable<int>(paymentMethodId);
    }
    if (!nullToAbsent || installmentPlanId != null) {
      map['installment_plan_id'] = Variable<int>(installmentPlanId);
    }
    if (!nullToAbsent || installmentNumber != null) {
      map['installment_number'] = Variable<int>(installmentNumber);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      amount: Value(amount),
      date: Value(date),
      note: Value(note),
      isRecurring: Value(isRecurring),
      recurringTemplateId: recurringTemplateId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringTemplateId),
      paymentMethodId: paymentMethodId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethodId),
      installmentPlanId: installmentPlanId == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentPlanId),
      installmentNumber: installmentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentNumber),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String>(json['note']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurringTemplateId:
          serializer.fromJson<int?>(json['recurringTemplateId']),
      paymentMethodId: serializer.fromJson<int?>(json['paymentMethodId']),
      installmentPlanId: serializer.fromJson<int?>(json['installmentPlanId']),
      installmentNumber: serializer.fromJson<int?>(json['installmentNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String>(note),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurringTemplateId': serializer.toJson<int?>(recurringTemplateId),
      'paymentMethodId': serializer.toJson<int?>(paymentMethodId),
      'installmentPlanId': serializer.toJson<int?>(installmentPlanId),
      'installmentNumber': serializer.toJson<int?>(installmentNumber),
    };
  }

  Transaction copyWith(
          {int? id,
          String? categoryId,
          int? amount,
          DateTime? date,
          String? note,
          bool? isRecurring,
          Value<int?> recurringTemplateId = const Value.absent(),
          Value<int?> paymentMethodId = const Value.absent(),
          Value<int?> installmentPlanId = const Value.absent(),
          Value<int?> installmentNumber = const Value.absent()}) =>
      Transaction(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringTemplateId: recurringTemplateId.present
            ? recurringTemplateId.value
            : this.recurringTemplateId,
        paymentMethodId: paymentMethodId.present
            ? paymentMethodId.value
            : this.paymentMethodId,
        installmentPlanId: installmentPlanId.present
            ? installmentPlanId.value
            : this.installmentPlanId,
        installmentNumber: installmentNumber.present
            ? installmentNumber.value
            : this.installmentNumber,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      isRecurring:
          data.isRecurring.present ? data.isRecurring.value : this.isRecurring,
      recurringTemplateId: data.recurringTemplateId.present
          ? data.recurringTemplateId.value
          : this.recurringTemplateId,
      paymentMethodId: data.paymentMethodId.present
          ? data.paymentMethodId.value
          : this.paymentMethodId,
      installmentPlanId: data.installmentPlanId.present
          ? data.installmentPlanId.value
          : this.installmentPlanId,
      installmentNumber: data.installmentNumber.present
          ? data.installmentNumber.value
          : this.installmentNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringTemplateId: $recurringTemplateId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('installmentPlanId: $installmentPlanId, ')
          ..write('installmentNumber: $installmentNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      categoryId,
      amount,
      date,
      note,
      isRecurring,
      recurringTemplateId,
      paymentMethodId,
      installmentPlanId,
      installmentNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.note == this.note &&
          other.isRecurring == this.isRecurring &&
          other.recurringTemplateId == this.recurringTemplateId &&
          other.paymentMethodId == this.paymentMethodId &&
          other.installmentPlanId == this.installmentPlanId &&
          other.installmentNumber == this.installmentNumber);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<String> categoryId;
  final Value<int> amount;
  final Value<DateTime> date;
  final Value<String> note;
  final Value<bool> isRecurring;
  final Value<int?> recurringTemplateId;
  final Value<int?> paymentMethodId;
  final Value<int?> installmentPlanId;
  final Value<int?> installmentNumber;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringTemplateId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.installmentPlanId = const Value.absent(),
    this.installmentNumber = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String categoryId,
    required int amount,
    required DateTime date,
    this.note = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringTemplateId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.installmentPlanId = const Value.absent(),
    this.installmentNumber = const Value.absent(),
  })  : categoryId = Value(categoryId),
        amount = Value(amount),
        date = Value(date);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<String>? categoryId,
    Expression<int>? amount,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<bool>? isRecurring,
    Expression<int>? recurringTemplateId,
    Expression<int>? paymentMethodId,
    Expression<int>? installmentPlanId,
    Expression<int>? installmentNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurringTemplateId != null)
        'recurring_template_id': recurringTemplateId,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (installmentPlanId != null) 'installment_plan_id': installmentPlanId,
      if (installmentNumber != null) 'installment_number': installmentNumber,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? categoryId,
      Value<int>? amount,
      Value<DateTime>? date,
      Value<String>? note,
      Value<bool>? isRecurring,
      Value<int?>? recurringTemplateId,
      Value<int?>? paymentMethodId,
      Value<int?>? installmentPlanId,
      Value<int?>? installmentNumber}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringTemplateId: recurringTemplateId ?? this.recurringTemplateId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurringTemplateId.present) {
      map['recurring_template_id'] = Variable<int>(recurringTemplateId.value);
    }
    if (paymentMethodId.present) {
      map['payment_method_id'] = Variable<int>(paymentMethodId.value);
    }
    if (installmentPlanId.present) {
      map['installment_plan_id'] = Variable<int>(installmentPlanId.value);
    }
    if (installmentNumber.present) {
      map['installment_number'] = Variable<int>(installmentNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringTemplateId: $recurringTemplateId, ')
          ..write('paymentMethodId: $paymentMethodId, ')
          ..write('installmentPlanId: $installmentPlanId, ')
          ..write('installmentNumber: $installmentNumber')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<int> targetAmount = GeneratedColumn<int>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, targetAmount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(Insertable<SavingsGoal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_amount'])!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final int id;
  final String name;
  final int targetAmount;
  const SavingsGoal(
      {required this.id, required this.name, required this.targetAmount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_amount'] = Variable<int>(targetAmount);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetAmount: Value(targetAmount),
    );
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmount: serializer.fromJson<int>(json['targetAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetAmount': serializer.toJson<int>(targetAmount),
    };
  }

  SavingsGoal copyWith({int? id, String? name, int? targetAmount}) =>
      SavingsGoal(
        id: id ?? this.id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
      );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, targetAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmount == this.targetAmount);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> targetAmount;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmount = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int targetAmount,
  })  : name = Value(name),
        targetAmount = Value(targetAmount);
  static Insertable<SavingsGoal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? targetAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmount != null) 'target_amount': targetAmount,
    });
  }

  SavingsGoalsCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<int>? targetAmount}) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<int>(targetAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmount: $targetAmount')
          ..write(')'))
        .toString();
  }
}

class $SavingsContributionsTable extends SavingsContributions
    with TableInfo<$SavingsContributionsTable, SavingsContribution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsContributionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [id, goalId, amount, date, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_contributions';
  @override
  VerificationContext validateIntegrity(
      Insertable<SavingsContribution> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsContribution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsContribution(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}goal_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
    );
  }

  @override
  $SavingsContributionsTable createAlias(String alias) {
    return $SavingsContributionsTable(attachedDatabase, alias);
  }
}

class SavingsContribution extends DataClass
    implements Insertable<SavingsContribution> {
  final int id;
  final int goalId;
  final int amount;
  final DateTime date;
  final String note;
  const SavingsContribution(
      {required this.id,
      required this.goalId,
      required this.amount,
      required this.date,
      required this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['goal_id'] = Variable<int>(goalId);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<DateTime>(date);
    map['note'] = Variable<String>(note);
    return map;
  }

  SavingsContributionsCompanion toCompanion(bool nullToAbsent) {
    return SavingsContributionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      amount: Value(amount),
      date: Value(date),
      note: Value(note),
    );
  }

  factory SavingsContribution.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsContribution(
      id: serializer.fromJson<int>(json['id']),
      goalId: serializer.fromJson<int>(json['goalId']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'goalId': serializer.toJson<int>(goalId),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String>(note),
    };
  }

  SavingsContribution copyWith(
          {int? id, int? goalId, int? amount, DateTime? date, String? note}) =>
      SavingsContribution(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        note: note ?? this.note,
      );
  SavingsContribution copyWithCompanion(SavingsContributionsCompanion data) {
    return SavingsContribution(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsContribution(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, amount, date, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsContribution &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.note == this.note);
}

class SavingsContributionsCompanion
    extends UpdateCompanion<SavingsContribution> {
  final Value<int> id;
  final Value<int> goalId;
  final Value<int> amount;
  final Value<DateTime> date;
  final Value<String> note;
  const SavingsContributionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
  });
  SavingsContributionsCompanion.insert({
    this.id = const Value.absent(),
    required int goalId,
    required int amount,
    required DateTime date,
    this.note = const Value.absent(),
  })  : goalId = Value(goalId),
        amount = Value(amount),
        date = Value(date);
  static Insertable<SavingsContribution> custom({
    Expression<int>? id,
    Expression<int>? goalId,
    Expression<int>? amount,
    Expression<DateTime>? date,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
    });
  }

  SavingsContributionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? goalId,
      Value<int>? amount,
      Value<DateTime>? date,
      Value<String>? note}) {
    return SavingsContributionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsContributionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $SavingsQuickAddsTable extends SavingsQuickAdds
    with TableInfo<$SavingsQuickAddsTable, SavingsQuickAdd> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsQuickAddsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
      'value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, goalId, label, mode, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_quick_adds';
  @override
  VerificationContext validateIntegrity(Insertable<SavingsQuickAdd> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsQuickAdd map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsQuickAdd(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}goal_id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SavingsQuickAddsTable createAlias(String alias) {
    return $SavingsQuickAddsTable(attachedDatabase, alias);
  }
}

class SavingsQuickAdd extends DataClass implements Insertable<SavingsQuickAdd> {
  final int id;
  final int goalId;
  final String label;
  final String mode;
  final int value;
  const SavingsQuickAdd(
      {required this.id,
      required this.goalId,
      required this.label,
      required this.mode,
      required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['goal_id'] = Variable<int>(goalId);
    map['label'] = Variable<String>(label);
    map['mode'] = Variable<String>(mode);
    map['value'] = Variable<int>(value);
    return map;
  }

  SavingsQuickAddsCompanion toCompanion(bool nullToAbsent) {
    return SavingsQuickAddsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      label: Value(label),
      mode: Value(mode),
      value: Value(value),
    );
  }

  factory SavingsQuickAdd.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsQuickAdd(
      id: serializer.fromJson<int>(json['id']),
      goalId: serializer.fromJson<int>(json['goalId']),
      label: serializer.fromJson<String>(json['label']),
      mode: serializer.fromJson<String>(json['mode']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'goalId': serializer.toJson<int>(goalId),
      'label': serializer.toJson<String>(label),
      'mode': serializer.toJson<String>(mode),
      'value': serializer.toJson<int>(value),
    };
  }

  SavingsQuickAdd copyWith(
          {int? id, int? goalId, String? label, String? mode, int? value}) =>
      SavingsQuickAdd(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        label: label ?? this.label,
        mode: mode ?? this.mode,
        value: value ?? this.value,
      );
  SavingsQuickAdd copyWithCompanion(SavingsQuickAddsCompanion data) {
    return SavingsQuickAdd(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      label: data.label.present ? data.label.value : this.label,
      mode: data.mode.present ? data.mode.value : this.mode,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsQuickAdd(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('label: $label, ')
          ..write('mode: $mode, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, label, mode, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsQuickAdd &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.label == this.label &&
          other.mode == this.mode &&
          other.value == this.value);
}

class SavingsQuickAddsCompanion extends UpdateCompanion<SavingsQuickAdd> {
  final Value<int> id;
  final Value<int> goalId;
  final Value<String> label;
  final Value<String> mode;
  final Value<int> value;
  const SavingsQuickAddsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.label = const Value.absent(),
    this.mode = const Value.absent(),
    this.value = const Value.absent(),
  });
  SavingsQuickAddsCompanion.insert({
    this.id = const Value.absent(),
    required int goalId,
    required String label,
    required String mode,
    required int value,
  })  : goalId = Value(goalId),
        label = Value(label),
        mode = Value(mode),
        value = Value(value);
  static Insertable<SavingsQuickAdd> custom({
    Expression<int>? id,
    Expression<int>? goalId,
    Expression<String>? label,
    Expression<String>? mode,
    Expression<int>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (label != null) 'label': label,
      if (mode != null) 'mode': mode,
      if (value != null) 'value': value,
    });
  }

  SavingsQuickAddsCompanion copyWith(
      {Value<int>? id,
      Value<int>? goalId,
      Value<String>? label,
      Value<String>? mode,
      Value<int>? value}) {
    return SavingsQuickAddsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      label: label ?? this.label,
      mode: mode ?? this.mode,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsQuickAddsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('label: $label, ')
          ..write('mode: $mode, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $MonthlyBudgetsTable extends MonthlyBudgets
    with TableInfo<$MonthlyBudgetsTable, MonthlyBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [year, month, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_budgets';
  @override
  VerificationContext validateIntegrity(Insertable<MonthlyBudget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year, month};
  @override
  MonthlyBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyBudget(
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $MonthlyBudgetsTable createAlias(String alias) {
    return $MonthlyBudgetsTable(attachedDatabase, alias);
  }
}

class MonthlyBudget extends DataClass implements Insertable<MonthlyBudget> {
  final int year;
  final int month;
  final int amount;
  const MonthlyBudget(
      {required this.year, required this.month, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  MonthlyBudgetsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyBudgetsCompanion(
      year: Value(year),
      month: Value(month),
      amount: Value(amount),
    );
  }

  factory MonthlyBudget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyBudget(
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'amount': serializer.toJson<int>(amount),
    };
  }

  MonthlyBudget copyWith({int? year, int? month, int? amount}) => MonthlyBudget(
        year: year ?? this.year,
        month: month ?? this.month,
        amount: amount ?? this.amount,
      );
  MonthlyBudget copyWithCompanion(MonthlyBudgetsCompanion data) {
    return MonthlyBudget(
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyBudget(')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(year, month, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyBudget &&
          other.year == this.year &&
          other.month == this.month &&
          other.amount == this.amount);
}

class MonthlyBudgetsCompanion extends UpdateCompanion<MonthlyBudget> {
  final Value<int> year;
  final Value<int> month;
  final Value<int> amount;
  final Value<int> rowid;
  const MonthlyBudgetsCompanion({
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlyBudgetsCompanion.insert({
    required int year,
    required int month,
    required int amount,
    this.rowid = const Value.absent(),
  })  : year = Value(year),
        month = Value(month),
        amount = Value(amount);
  static Insertable<MonthlyBudget> custom({
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlyBudgetsCompanion copyWith(
      {Value<int>? year,
      Value<int>? month,
      Value<int>? amount,
      Value<int>? rowid}) {
    return MonthlyBudgetsCompanion(
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyBudgetsCompanion(')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuickExpenseTemplatesTable extends QuickExpenseTemplates
    with TableInfo<$QuickExpenseTemplatesTable, QuickExpenseTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuickExpenseTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, label, amount, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quick_expense_templates';
  @override
  VerificationContext validateIntegrity(
      Insertable<QuickExpenseTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuickExpenseTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuickExpenseTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
    );
  }

  @override
  $QuickExpenseTemplatesTable createAlias(String alias) {
    return $QuickExpenseTemplatesTable(attachedDatabase, alias);
  }
}

class QuickExpenseTemplate extends DataClass
    implements Insertable<QuickExpenseTemplate> {
  final int id;
  final String label;
  final int amount;
  final String categoryId;
  const QuickExpenseTemplate(
      {required this.id,
      required this.label,
      required this.amount,
      required this.categoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    map['amount'] = Variable<int>(amount);
    map['category_id'] = Variable<String>(categoryId);
    return map;
  }

  QuickExpenseTemplatesCompanion toCompanion(bool nullToAbsent) {
    return QuickExpenseTemplatesCompanion(
      id: Value(id),
      label: Value(label),
      amount: Value(amount),
      categoryId: Value(categoryId),
    );
  }

  factory QuickExpenseTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuickExpenseTemplate(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<String>(categoryId),
    };
  }

  QuickExpenseTemplate copyWith(
          {int? id, String? label, int? amount, String? categoryId}) =>
      QuickExpenseTemplate(
        id: id ?? this.id,
        label: label ?? this.label,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
      );
  QuickExpenseTemplate copyWithCompanion(QuickExpenseTemplatesCompanion data) {
    return QuickExpenseTemplate(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuickExpenseTemplate(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, amount, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuickExpenseTemplate &&
          other.id == this.id &&
          other.label == this.label &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId);
}

class QuickExpenseTemplatesCompanion
    extends UpdateCompanion<QuickExpenseTemplate> {
  final Value<int> id;
  final Value<String> label;
  final Value<int> amount;
  final Value<String> categoryId;
  const QuickExpenseTemplatesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  QuickExpenseTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String label,
    required int amount,
    required String categoryId,
  })  : label = Value(label),
        amount = Value(amount),
        categoryId = Value(categoryId);
  static Insertable<QuickExpenseTemplate> custom({
    Expression<int>? id,
    Expression<String>? label,
    Expression<int>? amount,
    Expression<String>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  QuickExpenseTemplatesCompanion copyWith(
      {Value<int>? id,
      Value<String>? label,
      Value<int>? amount,
      Value<String>? categoryId}) {
    return QuickExpenseTemplatesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuickExpenseTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

class $MonthlyAdjustmentsTable extends MonthlyAdjustments
    with TableInfo<$MonthlyAdjustmentsTable, MonthlyAdjustment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyAdjustmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
      'month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, year, month, categoryId, amount, reason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_adjustments';
  @override
  VerificationContext validateIntegrity(Insertable<MonthlyAdjustment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthlyAdjustment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyAdjustment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
    );
  }

  @override
  $MonthlyAdjustmentsTable createAlias(String alias) {
    return $MonthlyAdjustmentsTable(attachedDatabase, alias);
  }
}

class MonthlyAdjustment extends DataClass
    implements Insertable<MonthlyAdjustment> {
  final int id;
  final int year;
  final int month;
  final String? categoryId;
  final int amount;
  final String reason;
  const MonthlyAdjustment(
      {required this.id,
      required this.year,
      required this.month,
      this.categoryId,
      required this.amount,
      required this.reason});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount'] = Variable<int>(amount);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  MonthlyAdjustmentsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyAdjustmentsCompanion(
      id: Value(id),
      year: Value(year),
      month: Value(month),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      reason: Value(reason),
    );
  }

  factory MonthlyAdjustment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyAdjustment(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<String>(reason),
    };
  }

  MonthlyAdjustment copyWith(
          {int? id,
          int? year,
          int? month,
          Value<String?> categoryId = const Value.absent(),
          int? amount,
          String? reason}) =>
      MonthlyAdjustment(
        id: id ?? this.id,
        year: year ?? this.year,
        month: month ?? this.month,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
      );
  MonthlyAdjustment copyWithCompanion(MonthlyAdjustmentsCompanion data) {
    return MonthlyAdjustment(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyAdjustment(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, year, month, categoryId, amount, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyAdjustment &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.reason == this.reason);
}

class MonthlyAdjustmentsCompanion extends UpdateCompanion<MonthlyAdjustment> {
  final Value<int> id;
  final Value<int> year;
  final Value<int> month;
  final Value<String?> categoryId;
  final Value<int> amount;
  final Value<String> reason;
  const MonthlyAdjustmentsCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
  });
  MonthlyAdjustmentsCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required int month,
    this.categoryId = const Value.absent(),
    required int amount,
    this.reason = const Value.absent(),
  })  : year = Value(year),
        month = Value(month),
        amount = Value(amount);
  static Insertable<MonthlyAdjustment> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<String>? categoryId,
    Expression<int>? amount,
    Expression<String>? reason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
    });
  }

  MonthlyAdjustmentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? year,
      Value<int>? month,
      Value<String?>? categoryId,
      Value<int>? amount,
      Value<String>? reason}) {
    return MonthlyAdjustmentsCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyAdjustmentsCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $CategoryBudgetsTable categoryBudgets =
      $CategoryBudgetsTable(this);
  late final $RecurringTemplatesTable recurringTemplates =
      $RecurringTemplatesTable(this);
  late final $PaymentMethodsTable paymentMethods = $PaymentMethodsTable(this);
  late final $InstallmentPlansTable installmentPlans =
      $InstallmentPlansTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  late final $SavingsContributionsTable savingsContributions =
      $SavingsContributionsTable(this);
  late final $SavingsQuickAddsTable savingsQuickAdds =
      $SavingsQuickAddsTable(this);
  late final $MonthlyBudgetsTable monthlyBudgets = $MonthlyBudgetsTable(this);
  late final $QuickExpenseTemplatesTable quickExpenseTemplates =
      $QuickExpenseTemplatesTable(this);
  late final $MonthlyAdjustmentsTable monthlyAdjustments =
      $MonthlyAdjustmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        categoryBudgets,
        recurringTemplates,
        paymentMethods,
        installmentPlans,
        transactions,
        appSettings,
        savingsGoals,
        savingsContributions,
        savingsQuickAdds,
        monthlyBudgets,
        quickExpenseTemplates,
        monthlyAdjustments
      ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required int colorValue,
  Value<String> iconKey,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> colorValue,
  Value<String> iconKey,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> colorValue = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            colorValue: colorValue,
            iconKey: iconKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int colorValue,
            Value<String> iconKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            colorValue: colorValue,
            iconKey: iconKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()>;
typedef $$CategoryBudgetsTableCreateCompanionBuilder = CategoryBudgetsCompanion
    Function({
  required String categoryId,
  required int year,
  required int month,
  required int amount,
  Value<int> rowid,
});
typedef $$CategoryBudgetsTableUpdateCompanionBuilder = CategoryBudgetsCompanion
    Function({
  Value<String> categoryId,
  Value<int> year,
  Value<int> month,
  Value<int> amount,
  Value<int> rowid,
});

class $$CategoryBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));
}

class $$CategoryBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));
}

class $$CategoryBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryBudgetsTable> {
  $$CategoryBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$CategoryBudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryBudgetsTable,
    CategoryBudget,
    $$CategoryBudgetsTableFilterComposer,
    $$CategoryBudgetsTableOrderingComposer,
    $$CategoryBudgetsTableAnnotationComposer,
    $$CategoryBudgetsTableCreateCompanionBuilder,
    $$CategoryBudgetsTableUpdateCompanionBuilder,
    (
      CategoryBudget,
      BaseReferences<_$AppDatabase, $CategoryBudgetsTable, CategoryBudget>
    ),
    CategoryBudget,
    PrefetchHooks Function()> {
  $$CategoryBudgetsTableTableManager(
      _$AppDatabase db, $CategoryBudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> categoryId = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<int> month = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryBudgetsCompanion(
            categoryId: categoryId,
            year: year,
            month: month,
            amount: amount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String categoryId,
            required int year,
            required int month,
            required int amount,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryBudgetsCompanion.insert(
            categoryId: categoryId,
            year: year,
            month: month,
            amount: amount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryBudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoryBudgetsTable,
    CategoryBudget,
    $$CategoryBudgetsTableFilterComposer,
    $$CategoryBudgetsTableOrderingComposer,
    $$CategoryBudgetsTableAnnotationComposer,
    $$CategoryBudgetsTableCreateCompanionBuilder,
    $$CategoryBudgetsTableUpdateCompanionBuilder,
    (
      CategoryBudget,
      BaseReferences<_$AppDatabase, $CategoryBudgetsTable, CategoryBudget>
    ),
    CategoryBudget,
    PrefetchHooks Function()>;
typedef $$RecurringTemplatesTableCreateCompanionBuilder
    = RecurringTemplatesCompanion Function({
  Value<int> id,
  required String categoryId,
  required int amount,
  Value<String> note,
  required int dayOfMonth,
  Value<bool> active,
  required int lastGeneratedYearMonth,
});
typedef $$RecurringTemplatesTableUpdateCompanionBuilder
    = RecurringTemplatesCompanion Function({
  Value<int> id,
  Value<String> categoryId,
  Value<int> amount,
  Value<String> note,
  Value<int> dayOfMonth,
  Value<bool> active,
  Value<int> lastGeneratedYearMonth,
});

class $$RecurringTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastGeneratedYearMonth => $composableBuilder(
      column: $table.lastGeneratedYearMonth,
      builder: (column) => ColumnFilters(column));
}

class $$RecurringTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastGeneratedYearMonth => $composableBuilder(
      column: $table.lastGeneratedYearMonth,
      builder: (column) => ColumnOrderings(column));
}

class $$RecurringTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTemplatesTable> {
  $$RecurringTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
      column: $table.dayOfMonth, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get lastGeneratedYearMonth => $composableBuilder(
      column: $table.lastGeneratedYearMonth, builder: (column) => column);
}

class $$RecurringTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringTemplatesTable,
    RecurringTemplate,
    $$RecurringTemplatesTableFilterComposer,
    $$RecurringTemplatesTableOrderingComposer,
    $$RecurringTemplatesTableAnnotationComposer,
    $$RecurringTemplatesTableCreateCompanionBuilder,
    $$RecurringTemplatesTableUpdateCompanionBuilder,
    (
      RecurringTemplate,
      BaseReferences<_$AppDatabase, $RecurringTemplatesTable, RecurringTemplate>
    ),
    RecurringTemplate,
    PrefetchHooks Function()> {
  $$RecurringTemplatesTableTableManager(
      _$AppDatabase db, $RecurringTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> dayOfMonth = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<int> lastGeneratedYearMonth = const Value.absent(),
          }) =>
              RecurringTemplatesCompanion(
            id: id,
            categoryId: categoryId,
            amount: amount,
            note: note,
            dayOfMonth: dayOfMonth,
            active: active,
            lastGeneratedYearMonth: lastGeneratedYearMonth,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String categoryId,
            required int amount,
            Value<String> note = const Value.absent(),
            required int dayOfMonth,
            Value<bool> active = const Value.absent(),
            required int lastGeneratedYearMonth,
          }) =>
              RecurringTemplatesCompanion.insert(
            id: id,
            categoryId: categoryId,
            amount: amount,
            note: note,
            dayOfMonth: dayOfMonth,
            active: active,
            lastGeneratedYearMonth: lastGeneratedYearMonth,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurringTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurringTemplatesTable,
    RecurringTemplate,
    $$RecurringTemplatesTableFilterComposer,
    $$RecurringTemplatesTableOrderingComposer,
    $$RecurringTemplatesTableAnnotationComposer,
    $$RecurringTemplatesTableCreateCompanionBuilder,
    $$RecurringTemplatesTableUpdateCompanionBuilder,
    (
      RecurringTemplate,
      BaseReferences<_$AppDatabase, $RecurringTemplatesTable, RecurringTemplate>
    ),
    RecurringTemplate,
    PrefetchHooks Function()>;
typedef $$PaymentMethodsTableCreateCompanionBuilder = PaymentMethodsCompanion
    Function({
  Value<int> id,
  required String alias,
  required String kind,
  required int colorValue,
  Value<String?> last4,
  Value<int?> billingDay,
  Value<int?> dueDay,
});
typedef $$PaymentMethodsTableUpdateCompanionBuilder = PaymentMethodsCompanion
    Function({
  Value<int> id,
  Value<String> alias,
  Value<String> kind,
  Value<int> colorValue,
  Value<String?> last4,
  Value<int?> billingDay,
  Value<int?> dueDay,
});

class $$PaymentMethodsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alias => $composableBuilder(
      column: $table.alias, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get last4 => $composableBuilder(
      column: $table.last4, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get billingDay => $composableBuilder(
      column: $table.billingDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDay => $composableBuilder(
      column: $table.dueDay, builder: (column) => ColumnFilters(column));
}

class $$PaymentMethodsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alias => $composableBuilder(
      column: $table.alias, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get last4 => $composableBuilder(
      column: $table.last4, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get billingDay => $composableBuilder(
      column: $table.billingDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDay => $composableBuilder(
      column: $table.dueDay, builder: (column) => ColumnOrderings(column));
}

class $$PaymentMethodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentMethodsTable> {
  $$PaymentMethodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<int> get billingDay => $composableBuilder(
      column: $table.billingDay, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);
}

class $$PaymentMethodsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PaymentMethodsTable,
    PaymentMethod,
    $$PaymentMethodsTableFilterComposer,
    $$PaymentMethodsTableOrderingComposer,
    $$PaymentMethodsTableAnnotationComposer,
    $$PaymentMethodsTableCreateCompanionBuilder,
    $$PaymentMethodsTableUpdateCompanionBuilder,
    (
      PaymentMethod,
      BaseReferences<_$AppDatabase, $PaymentMethodsTable, PaymentMethod>
    ),
    PaymentMethod,
    PrefetchHooks Function()> {
  $$PaymentMethodsTableTableManager(
      _$AppDatabase db, $PaymentMethodsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentMethodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentMethodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentMethodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> alias = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> colorValue = const Value.absent(),
            Value<String?> last4 = const Value.absent(),
            Value<int?> billingDay = const Value.absent(),
            Value<int?> dueDay = const Value.absent(),
          }) =>
              PaymentMethodsCompanion(
            id: id,
            alias: alias,
            kind: kind,
            colorValue: colorValue,
            last4: last4,
            billingDay: billingDay,
            dueDay: dueDay,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String alias,
            required String kind,
            required int colorValue,
            Value<String?> last4 = const Value.absent(),
            Value<int?> billingDay = const Value.absent(),
            Value<int?> dueDay = const Value.absent(),
          }) =>
              PaymentMethodsCompanion.insert(
            id: id,
            alias: alias,
            kind: kind,
            colorValue: colorValue,
            last4: last4,
            billingDay: billingDay,
            dueDay: dueDay,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PaymentMethodsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PaymentMethodsTable,
    PaymentMethod,
    $$PaymentMethodsTableFilterComposer,
    $$PaymentMethodsTableOrderingComposer,
    $$PaymentMethodsTableAnnotationComposer,
    $$PaymentMethodsTableCreateCompanionBuilder,
    $$PaymentMethodsTableUpdateCompanionBuilder,
    (
      PaymentMethod,
      BaseReferences<_$AppDatabase, $PaymentMethodsTable, PaymentMethod>
    ),
    PaymentMethod,
    PrefetchHooks Function()>;
typedef $$InstallmentPlansTableCreateCompanionBuilder
    = InstallmentPlansCompanion Function({
  Value<int> id,
  required int paymentMethodId,
  required String categoryId,
  Value<String> note,
  required int totalAmount,
  required int installmentCount,
  required DateTime purchaseDate,
  Value<bool> prepaid,
});
typedef $$InstallmentPlansTableUpdateCompanionBuilder
    = InstallmentPlansCompanion Function({
  Value<int> id,
  Value<int> paymentMethodId,
  Value<String> categoryId,
  Value<String> note,
  Value<int> totalAmount,
  Value<int> installmentCount,
  Value<DateTime> purchaseDate,
  Value<bool> prepaid,
});

class $$InstallmentPlansTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentPlansTable> {
  $$InstallmentPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentMethodId => $composableBuilder(
      column: $table.paymentMethodId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get installmentCount => $composableBuilder(
      column: $table.installmentCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get prepaid => $composableBuilder(
      column: $table.prepaid, builder: (column) => ColumnFilters(column));
}

class $$InstallmentPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentPlansTable> {
  $$InstallmentPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentMethodId => $composableBuilder(
      column: $table.paymentMethodId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get installmentCount => $composableBuilder(
      column: $table.installmentCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get prepaid => $composableBuilder(
      column: $table.prepaid, builder: (column) => ColumnOrderings(column));
}

class $$InstallmentPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentPlansTable> {
  $$InstallmentPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get paymentMethodId => $composableBuilder(
      column: $table.paymentMethodId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<int> get installmentCount => $composableBuilder(
      column: $table.installmentCount, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate, builder: (column) => column);

  GeneratedColumn<bool> get prepaid =>
      $composableBuilder(column: $table.prepaid, builder: (column) => column);
}

class $$InstallmentPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InstallmentPlansTable,
    InstallmentPlan,
    $$InstallmentPlansTableFilterComposer,
    $$InstallmentPlansTableOrderingComposer,
    $$InstallmentPlansTableAnnotationComposer,
    $$InstallmentPlansTableCreateCompanionBuilder,
    $$InstallmentPlansTableUpdateCompanionBuilder,
    (
      InstallmentPlan,
      BaseReferences<_$AppDatabase, $InstallmentPlansTable, InstallmentPlan>
    ),
    InstallmentPlan,
    PrefetchHooks Function()> {
  $$InstallmentPlansTableTableManager(
      _$AppDatabase db, $InstallmentPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstallmentPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> paymentMethodId = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> totalAmount = const Value.absent(),
            Value<int> installmentCount = const Value.absent(),
            Value<DateTime> purchaseDate = const Value.absent(),
            Value<bool> prepaid = const Value.absent(),
          }) =>
              InstallmentPlansCompanion(
            id: id,
            paymentMethodId: paymentMethodId,
            categoryId: categoryId,
            note: note,
            totalAmount: totalAmount,
            installmentCount: installmentCount,
            purchaseDate: purchaseDate,
            prepaid: prepaid,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int paymentMethodId,
            required String categoryId,
            Value<String> note = const Value.absent(),
            required int totalAmount,
            required int installmentCount,
            required DateTime purchaseDate,
            Value<bool> prepaid = const Value.absent(),
          }) =>
              InstallmentPlansCompanion.insert(
            id: id,
            paymentMethodId: paymentMethodId,
            categoryId: categoryId,
            note: note,
            totalAmount: totalAmount,
            installmentCount: installmentCount,
            purchaseDate: purchaseDate,
            prepaid: prepaid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InstallmentPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InstallmentPlansTable,
    InstallmentPlan,
    $$InstallmentPlansTableFilterComposer,
    $$InstallmentPlansTableOrderingComposer,
    $$InstallmentPlansTableAnnotationComposer,
    $$InstallmentPlansTableCreateCompanionBuilder,
    $$InstallmentPlansTableUpdateCompanionBuilder,
    (
      InstallmentPlan,
      BaseReferences<_$AppDatabase, $InstallmentPlansTable, InstallmentPlan>
    ),
    InstallmentPlan,
    PrefetchHooks Function()>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required String categoryId,
  required int amount,
  required DateTime date,
  Value<String> note,
  Value<bool> isRecurring,
  Value<int?> recurringTemplateId,
  Value<int?> paymentMethodId,
  Value<int?> installmentPlanId,
  Value<int?> installmentNumber,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<String> categoryId,
  Value<int> amount,
  Value<DateTime> date,
  Value<String> note,
  Value<bool> isRecurring,
  Value<int?> recurringTemplateId,
  Value<int?> paymentMethodId,
  Value<int?> installmentPlanId,
  Value<int?> installmentNumber,
});

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recurringTemplateId => $composableBuilder(
      column: $table.recurringTemplateId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get paymentMethodId => $composableBuilder(
      column: $table.paymentMethodId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get installmentPlanId => $composableBuilder(
      column: $table.installmentPlanId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get installmentNumber => $composableBuilder(
      column: $table.installmentNumber,
      builder: (column) => ColumnFilters(column));
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recurringTemplateId => $composableBuilder(
      column: $table.recurringTemplateId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get paymentMethodId => $composableBuilder(
      column: $table.paymentMethodId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get installmentPlanId => $composableBuilder(
      column: $table.installmentPlanId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get installmentNumber => $composableBuilder(
      column: $table.installmentNumber,
      builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => column);

  GeneratedColumn<int> get recurringTemplateId => $composableBuilder(
      column: $table.recurringTemplateId, builder: (column) => column);

  GeneratedColumn<int> get paymentMethodId => $composableBuilder(
      column: $table.paymentMethodId, builder: (column) => column);

  GeneratedColumn<int> get installmentPlanId => $composableBuilder(
      column: $table.installmentPlanId, builder: (column) => column);

  GeneratedColumn<int> get installmentNumber => $composableBuilder(
      column: $table.installmentNumber, builder: (column) => column);
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<int?> recurringTemplateId = const Value.absent(),
            Value<int?> paymentMethodId = const Value.absent(),
            Value<int?> installmentPlanId = const Value.absent(),
            Value<int?> installmentNumber = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            categoryId: categoryId,
            amount: amount,
            date: date,
            note: note,
            isRecurring: isRecurring,
            recurringTemplateId: recurringTemplateId,
            paymentMethodId: paymentMethodId,
            installmentPlanId: installmentPlanId,
            installmentNumber: installmentNumber,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String categoryId,
            required int amount,
            required DateTime date,
            Value<String> note = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<int?> recurringTemplateId = const Value.absent(),
            Value<int?> paymentMethodId = const Value.absent(),
            Value<int?> installmentPlanId = const Value.absent(),
            Value<int?> installmentNumber = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            categoryId: categoryId,
            amount: amount,
            date: date,
            note: note,
            isRecurring: isRecurring,
            recurringTemplateId: recurringTemplateId,
            paymentMethodId: paymentMethodId,
            installmentPlanId: installmentPlanId,
            installmentNumber: installmentNumber,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      Transaction,
      BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>
    ),
    Transaction,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$SavingsGoalsTableCreateCompanionBuilder = SavingsGoalsCompanion
    Function({
  Value<int> id,
  required String name,
  required int targetAmount,
});
typedef $$SavingsGoalsTableUpdateCompanionBuilder = SavingsGoalsCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> targetAmount,
});

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);
}

class $$SavingsGoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingsGoalsTable,
    SavingsGoal,
    $$SavingsGoalsTableFilterComposer,
    $$SavingsGoalsTableOrderingComposer,
    $$SavingsGoalsTableAnnotationComposer,
    $$SavingsGoalsTableCreateCompanionBuilder,
    $$SavingsGoalsTableUpdateCompanionBuilder,
    (
      SavingsGoal,
      BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal>
    ),
    SavingsGoal,
    PrefetchHooks Function()> {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> targetAmount = const Value.absent(),
          }) =>
              SavingsGoalsCompanion(
            id: id,
            name: name,
            targetAmount: targetAmount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int targetAmount,
          }) =>
              SavingsGoalsCompanion.insert(
            id: id,
            name: name,
            targetAmount: targetAmount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavingsGoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavingsGoalsTable,
    SavingsGoal,
    $$SavingsGoalsTableFilterComposer,
    $$SavingsGoalsTableOrderingComposer,
    $$SavingsGoalsTableAnnotationComposer,
    $$SavingsGoalsTableCreateCompanionBuilder,
    $$SavingsGoalsTableUpdateCompanionBuilder,
    (
      SavingsGoal,
      BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal>
    ),
    SavingsGoal,
    PrefetchHooks Function()>;
typedef $$SavingsContributionsTableCreateCompanionBuilder
    = SavingsContributionsCompanion Function({
  Value<int> id,
  required int goalId,
  required int amount,
  required DateTime date,
  Value<String> note,
});
typedef $$SavingsContributionsTableUpdateCompanionBuilder
    = SavingsContributionsCompanion Function({
  Value<int> id,
  Value<int> goalId,
  Value<int> amount,
  Value<DateTime> date,
  Value<String> note,
});

class $$SavingsContributionsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsContributionsTable> {
  $$SavingsContributionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$SavingsContributionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsContributionsTable> {
  $$SavingsContributionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$SavingsContributionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsContributionsTable> {
  $$SavingsContributionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$SavingsContributionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingsContributionsTable,
    SavingsContribution,
    $$SavingsContributionsTableFilterComposer,
    $$SavingsContributionsTableOrderingComposer,
    $$SavingsContributionsTableAnnotationComposer,
    $$SavingsContributionsTableCreateCompanionBuilder,
    $$SavingsContributionsTableUpdateCompanionBuilder,
    (
      SavingsContribution,
      BaseReferences<_$AppDatabase, $SavingsContributionsTable,
          SavingsContribution>
    ),
    SavingsContribution,
    PrefetchHooks Function()> {
  $$SavingsContributionsTableTableManager(
      _$AppDatabase db, $SavingsContributionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsContributionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsContributionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsContributionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> goalId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> note = const Value.absent(),
          }) =>
              SavingsContributionsCompanion(
            id: id,
            goalId: goalId,
            amount: amount,
            date: date,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int goalId,
            required int amount,
            required DateTime date,
            Value<String> note = const Value.absent(),
          }) =>
              SavingsContributionsCompanion.insert(
            id: id,
            goalId: goalId,
            amount: amount,
            date: date,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavingsContributionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SavingsContributionsTable,
        SavingsContribution,
        $$SavingsContributionsTableFilterComposer,
        $$SavingsContributionsTableOrderingComposer,
        $$SavingsContributionsTableAnnotationComposer,
        $$SavingsContributionsTableCreateCompanionBuilder,
        $$SavingsContributionsTableUpdateCompanionBuilder,
        (
          SavingsContribution,
          BaseReferences<_$AppDatabase, $SavingsContributionsTable,
              SavingsContribution>
        ),
        SavingsContribution,
        PrefetchHooks Function()>;
typedef $$SavingsQuickAddsTableCreateCompanionBuilder
    = SavingsQuickAddsCompanion Function({
  Value<int> id,
  required int goalId,
  required String label,
  required String mode,
  required int value,
});
typedef $$SavingsQuickAddsTableUpdateCompanionBuilder
    = SavingsQuickAddsCompanion Function({
  Value<int> id,
  Value<int> goalId,
  Value<String> label,
  Value<String> mode,
  Value<int> value,
});

class $$SavingsQuickAddsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsQuickAddsTable> {
  $$SavingsQuickAddsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SavingsQuickAddsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsQuickAddsTable> {
  $$SavingsQuickAddsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goalId => $composableBuilder(
      column: $table.goalId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SavingsQuickAddsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsQuickAddsTable> {
  $$SavingsQuickAddsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SavingsQuickAddsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavingsQuickAddsTable,
    SavingsQuickAdd,
    $$SavingsQuickAddsTableFilterComposer,
    $$SavingsQuickAddsTableOrderingComposer,
    $$SavingsQuickAddsTableAnnotationComposer,
    $$SavingsQuickAddsTableCreateCompanionBuilder,
    $$SavingsQuickAddsTableUpdateCompanionBuilder,
    (
      SavingsQuickAdd,
      BaseReferences<_$AppDatabase, $SavingsQuickAddsTable, SavingsQuickAdd>
    ),
    SavingsQuickAdd,
    PrefetchHooks Function()> {
  $$SavingsQuickAddsTableTableManager(
      _$AppDatabase db, $SavingsQuickAddsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsQuickAddsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsQuickAddsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsQuickAddsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> goalId = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<int> value = const Value.absent(),
          }) =>
              SavingsQuickAddsCompanion(
            id: id,
            goalId: goalId,
            label: label,
            mode: mode,
            value: value,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int goalId,
            required String label,
            required String mode,
            required int value,
          }) =>
              SavingsQuickAddsCompanion.insert(
            id: id,
            goalId: goalId,
            label: label,
            mode: mode,
            value: value,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavingsQuickAddsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavingsQuickAddsTable,
    SavingsQuickAdd,
    $$SavingsQuickAddsTableFilterComposer,
    $$SavingsQuickAddsTableOrderingComposer,
    $$SavingsQuickAddsTableAnnotationComposer,
    $$SavingsQuickAddsTableCreateCompanionBuilder,
    $$SavingsQuickAddsTableUpdateCompanionBuilder,
    (
      SavingsQuickAdd,
      BaseReferences<_$AppDatabase, $SavingsQuickAddsTable, SavingsQuickAdd>
    ),
    SavingsQuickAdd,
    PrefetchHooks Function()>;
typedef $$MonthlyBudgetsTableCreateCompanionBuilder = MonthlyBudgetsCompanion
    Function({
  required int year,
  required int month,
  required int amount,
  Value<int> rowid,
});
typedef $$MonthlyBudgetsTableUpdateCompanionBuilder = MonthlyBudgetsCompanion
    Function({
  Value<int> year,
  Value<int> month,
  Value<int> amount,
  Value<int> rowid,
});

class $$MonthlyBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));
}

class $$MonthlyBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));
}

class $$MonthlyBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$MonthlyBudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MonthlyBudgetsTable,
    MonthlyBudget,
    $$MonthlyBudgetsTableFilterComposer,
    $$MonthlyBudgetsTableOrderingComposer,
    $$MonthlyBudgetsTableAnnotationComposer,
    $$MonthlyBudgetsTableCreateCompanionBuilder,
    $$MonthlyBudgetsTableUpdateCompanionBuilder,
    (
      MonthlyBudget,
      BaseReferences<_$AppDatabase, $MonthlyBudgetsTable, MonthlyBudget>
    ),
    MonthlyBudget,
    PrefetchHooks Function()> {
  $$MonthlyBudgetsTableTableManager(
      _$AppDatabase db, $MonthlyBudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> year = const Value.absent(),
            Value<int> month = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MonthlyBudgetsCompanion(
            year: year,
            month: month,
            amount: amount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int year,
            required int month,
            required int amount,
            Value<int> rowid = const Value.absent(),
          }) =>
              MonthlyBudgetsCompanion.insert(
            year: year,
            month: month,
            amount: amount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MonthlyBudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MonthlyBudgetsTable,
    MonthlyBudget,
    $$MonthlyBudgetsTableFilterComposer,
    $$MonthlyBudgetsTableOrderingComposer,
    $$MonthlyBudgetsTableAnnotationComposer,
    $$MonthlyBudgetsTableCreateCompanionBuilder,
    $$MonthlyBudgetsTableUpdateCompanionBuilder,
    (
      MonthlyBudget,
      BaseReferences<_$AppDatabase, $MonthlyBudgetsTable, MonthlyBudget>
    ),
    MonthlyBudget,
    PrefetchHooks Function()>;
typedef $$QuickExpenseTemplatesTableCreateCompanionBuilder
    = QuickExpenseTemplatesCompanion Function({
  Value<int> id,
  required String label,
  required int amount,
  required String categoryId,
});
typedef $$QuickExpenseTemplatesTableUpdateCompanionBuilder
    = QuickExpenseTemplatesCompanion Function({
  Value<int> id,
  Value<String> label,
  Value<int> amount,
  Value<String> categoryId,
});

class $$QuickExpenseTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $QuickExpenseTemplatesTable> {
  $$QuickExpenseTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));
}

class $$QuickExpenseTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuickExpenseTemplatesTable> {
  $$QuickExpenseTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));
}

class $$QuickExpenseTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuickExpenseTemplatesTable> {
  $$QuickExpenseTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);
}

class $$QuickExpenseTemplatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuickExpenseTemplatesTable,
    QuickExpenseTemplate,
    $$QuickExpenseTemplatesTableFilterComposer,
    $$QuickExpenseTemplatesTableOrderingComposer,
    $$QuickExpenseTemplatesTableAnnotationComposer,
    $$QuickExpenseTemplatesTableCreateCompanionBuilder,
    $$QuickExpenseTemplatesTableUpdateCompanionBuilder,
    (
      QuickExpenseTemplate,
      BaseReferences<_$AppDatabase, $QuickExpenseTemplatesTable,
          QuickExpenseTemplate>
    ),
    QuickExpenseTemplate,
    PrefetchHooks Function()> {
  $$QuickExpenseTemplatesTableTableManager(
      _$AppDatabase db, $QuickExpenseTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuickExpenseTemplatesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$QuickExpenseTemplatesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuickExpenseTemplatesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
          }) =>
              QuickExpenseTemplatesCompanion(
            id: id,
            label: label,
            amount: amount,
            categoryId: categoryId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String label,
            required int amount,
            required String categoryId,
          }) =>
              QuickExpenseTemplatesCompanion.insert(
            id: id,
            label: label,
            amount: amount,
            categoryId: categoryId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuickExpenseTemplatesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $QuickExpenseTemplatesTable,
        QuickExpenseTemplate,
        $$QuickExpenseTemplatesTableFilterComposer,
        $$QuickExpenseTemplatesTableOrderingComposer,
        $$QuickExpenseTemplatesTableAnnotationComposer,
        $$QuickExpenseTemplatesTableCreateCompanionBuilder,
        $$QuickExpenseTemplatesTableUpdateCompanionBuilder,
        (
          QuickExpenseTemplate,
          BaseReferences<_$AppDatabase, $QuickExpenseTemplatesTable,
              QuickExpenseTemplate>
        ),
        QuickExpenseTemplate,
        PrefetchHooks Function()>;
typedef $$MonthlyAdjustmentsTableCreateCompanionBuilder
    = MonthlyAdjustmentsCompanion Function({
  Value<int> id,
  required int year,
  required int month,
  Value<String?> categoryId,
  required int amount,
  Value<String> reason,
});
typedef $$MonthlyAdjustmentsTableUpdateCompanionBuilder
    = MonthlyAdjustmentsCompanion Function({
  Value<int> id,
  Value<int> year,
  Value<int> month,
  Value<String?> categoryId,
  Value<int> amount,
  Value<String> reason,
});

class $$MonthlyAdjustmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyAdjustmentsTable> {
  $$MonthlyAdjustmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));
}

class $$MonthlyAdjustmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyAdjustmentsTable> {
  $$MonthlyAdjustmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));
}

class $$MonthlyAdjustmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyAdjustmentsTable> {
  $$MonthlyAdjustmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$MonthlyAdjustmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MonthlyAdjustmentsTable,
    MonthlyAdjustment,
    $$MonthlyAdjustmentsTableFilterComposer,
    $$MonthlyAdjustmentsTableOrderingComposer,
    $$MonthlyAdjustmentsTableAnnotationComposer,
    $$MonthlyAdjustmentsTableCreateCompanionBuilder,
    $$MonthlyAdjustmentsTableUpdateCompanionBuilder,
    (
      MonthlyAdjustment,
      BaseReferences<_$AppDatabase, $MonthlyAdjustmentsTable, MonthlyAdjustment>
    ),
    MonthlyAdjustment,
    PrefetchHooks Function()> {
  $$MonthlyAdjustmentsTableTableManager(
      _$AppDatabase db, $MonthlyAdjustmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyAdjustmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyAdjustmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyAdjustmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> year = const Value.absent(),
            Value<int> month = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<String> reason = const Value.absent(),
          }) =>
              MonthlyAdjustmentsCompanion(
            id: id,
            year: year,
            month: month,
            categoryId: categoryId,
            amount: amount,
            reason: reason,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int year,
            required int month,
            Value<String?> categoryId = const Value.absent(),
            required int amount,
            Value<String> reason = const Value.absent(),
          }) =>
              MonthlyAdjustmentsCompanion.insert(
            id: id,
            year: year,
            month: month,
            categoryId: categoryId,
            amount: amount,
            reason: reason,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MonthlyAdjustmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MonthlyAdjustmentsTable,
    MonthlyAdjustment,
    $$MonthlyAdjustmentsTableFilterComposer,
    $$MonthlyAdjustmentsTableOrderingComposer,
    $$MonthlyAdjustmentsTableAnnotationComposer,
    $$MonthlyAdjustmentsTableCreateCompanionBuilder,
    $$MonthlyAdjustmentsTableUpdateCompanionBuilder,
    (
      MonthlyAdjustment,
      BaseReferences<_$AppDatabase, $MonthlyAdjustmentsTable, MonthlyAdjustment>
    ),
    MonthlyAdjustment,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$CategoryBudgetsTableTableManager get categoryBudgets =>
      $$CategoryBudgetsTableTableManager(_db, _db.categoryBudgets);
  $$RecurringTemplatesTableTableManager get recurringTemplates =>
      $$RecurringTemplatesTableTableManager(_db, _db.recurringTemplates);
  $$PaymentMethodsTableTableManager get paymentMethods =>
      $$PaymentMethodsTableTableManager(_db, _db.paymentMethods);
  $$InstallmentPlansTableTableManager get installmentPlans =>
      $$InstallmentPlansTableTableManager(_db, _db.installmentPlans);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
  $$SavingsContributionsTableTableManager get savingsContributions =>
      $$SavingsContributionsTableTableManager(_db, _db.savingsContributions);
  $$SavingsQuickAddsTableTableManager get savingsQuickAdds =>
      $$SavingsQuickAddsTableTableManager(_db, _db.savingsQuickAdds);
  $$MonthlyBudgetsTableTableManager get monthlyBudgets =>
      $$MonthlyBudgetsTableTableManager(_db, _db.monthlyBudgets);
  $$QuickExpenseTemplatesTableTableManager get quickExpenseTemplates =>
      $$QuickExpenseTemplatesTableTableManager(_db, _db.quickExpenseTemplates);
  $$MonthlyAdjustmentsTableTableManager get monthlyAdjustments =>
      $$MonthlyAdjustmentsTableTableManager(_db, _db.monthlyAdjustments);
}

import 'package:sqflite/sqflite.dart';

import 'flow_database.dart';
import 'models/models.dart';

class DefaultCategorySeeder {
  DefaultCategorySeeder(this._database);
  final FlowDatabase _database;

  static const defaults = <Category>[
    Category(
      name: 'Salary',
      transactionType: TransactionType.income,
      icon: 'payments',
      color: '#168C78',
      isDefault: true,
    ),
    Category(
      name: 'Bonus',
      transactionType: TransactionType.income,
      icon: 'card_giftcard',
      color: '#168C78',
      isDefault: true,
    ),
    Category(
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
      isDefault: true,
    ),
    Category(
      name: 'Transport',
      transactionType: TransactionType.expense,
      icon: 'directions_car',
      color: '#C96B6B',
      isDefault: true,
    ),
    Category(
      name: 'Bills',
      transactionType: TransactionType.expense,
      icon: 'receipt_long',
      color: '#C96B6B',
      isDefault: true,
    ),
  ];

  /// Seeds only an empty default-category set. Existing rows, including edited
  /// or archived defaults, are never replaced and transaction IDs stay stable.
  Future<void> seed() async {
    final count =
        Sqflite.firstIntValue(
          await _database.database.rawQuery(
            'SELECT COUNT(*) FROM categories WHERE is_default = 1',
          ),
        ) ??
        0;
    if (count > 0) return;
    await _database.database.transaction((transaction) async {
      for (final category in defaults) {
        await transaction.insert('categories', category.toMap());
      }
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/models/models.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 8, 12);

  test('account round-trips its SQLite map', () {
    final account = Account(
      name: 'Cash',
      type: AccountType.cash,
      openingBalance: 250000,
      icon: 'wallet',
      color: '#168C78',
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final restored = Account.fromMap(account.toMap());
    expect(restored.name, account.name);
    expect(restored.type, account.type);
    expect(restored.openingBalance, account.openingBalance);
    expect(restored.isArchived, isFalse);
  });

  test('transaction preserves positive amount and optional references', () {
    final transaction = Transaction(
      type: TransactionType.expense,
      amount: 50000,
      accountId: 1,
      categoryId: 2,
      note: 'Lunch',
      occurredAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final map = transaction.toMap();
    expect(map['amount'], 50000);
    expect(map['destination_account_id'], isNull);
    expect(Transaction.fromMap(map).note, 'Lunch');
  });

  test('settings defaults to IDR and system theme', () {
    final settings = AppSettings.fromMap(const AppSettings().toMap());
    expect(settings.currency, 'IDR');
    expect(settings.themeMode, ThemeModeSetting.system);
    expect(settings.hideBalance, isFalse);
  });
}

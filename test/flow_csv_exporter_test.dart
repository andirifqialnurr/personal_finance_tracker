import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';

void main() {
  test('exports stable headers, labels, and escaped notes', () {
    final timestamp = DateTime.utc(2026, 8, 9, 12);
    final csv = FlowCsvExporter.build(
      accounts: [
        Account(
          id: 1,
          name: 'Cash, wallet',
          type: AccountType.cash,
          openingBalance: 0,
          icon: 'wallet',
          color: '#168C78',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
      categories: const [
        Category(
          id: 2,
          name: 'Food',
          transactionType: TransactionType.expense,
          icon: 'restaurant',
          color: '#C96B6B',
        ),
      ],
      transactions: [
        Transaction(
          type: TransactionType.expense,
          amount: 50000,
          accountId: 1,
          categoryId: 2,
          note: 'Lunch, "team"',
          occurredAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    );

    expect(csv.split('\r\n').first, 'Date,Type,Amount,Account,Destination Account,Category,Note');
    expect(csv, contains('"Cash, wallet"'));
    expect(csv, contains('"Lunch, ""team"""'));
    expect(csv, contains('Expense'));
    expect(csv, contains('Food'));
  });

  test('exports only the selected month for reports', () {
    final august = DateTime.utc(2026, 8, 9, 12);
    final september = DateTime.utc(2026, 9, 1, 12);
    final csv = FlowCsvExporter.buildMonthly(
      month: DateTime(2026, 8),
      accounts: [
        Account(
          id: 1,
          name: 'Cash',
          type: AccountType.cash,
          openingBalance: 0,
          icon: 'wallet',
          color: '#168C78',
          createdAt: august,
          updatedAt: august,
        ),
      ],
      categories: const [
        Category(
          id: 2,
          name: 'Food',
          transactionType: TransactionType.expense,
          icon: 'restaurant',
          color: '#C96B6B',
        ),
      ],
      transactions: [
        Transaction(
          type: TransactionType.expense,
          amount: 50000,
          accountId: 1,
          categoryId: 2,
          note: 'August lunch',
          occurredAt: august,
          createdAt: august,
          updatedAt: august,
        ),
        Transaction(
          type: TransactionType.expense,
          amount: 75000,
          accountId: 1,
          categoryId: 2,
          note: 'September lunch',
          occurredAt: september,
          createdAt: september,
          updatedAt: september,
        ),
      ],
    );

    expect(csv, contains('August lunch'));
    expect(csv, isNot(contains('September lunch')));
  });
}

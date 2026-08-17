import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 17, 9);
  final importedAt = DateTime.utc(2026, 8, 17, 10);
  final accounts = [
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
    Account(
      id: 2,
      name: 'Bank',
      type: AccountType.bank,
      openingBalance: 0,
      icon: 'account_balance',
      color: '#168C78',
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  ];
  const categories = [
    Category(
      id: 1,
      name: 'Salary',
      transactionType: TransactionType.income,
      icon: 'payments',
      color: '#168C78',
    ),
    Category(
      id: 2,
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
    ),
  ];

  test('previews rows exported by FlowCsvExporter', () {
    final csv = FlowCsvExporter.build(
      accounts: accounts,
      categories: categories,
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
        Transaction(
          type: TransactionType.transfer,
          amount: 75000,
          accountId: 1,
          destinationAccountId: 2,
          occurredAt: timestamp.add(const Duration(hours: 1)),
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    );

    final preview = FlowCsvImporter.preview(
      csv: csv,
      accounts: accounts,
      categories: categories,
      existingTransactions: const [],
      importedAt: importedAt,
    );

    expect(preview.readyCount, 2);
    expect(preview.errorCount, 0);
    expect(preview.skippedDuplicates, 0);
    expect(preview.matchedAccountNames, containsAll(['Cash, wallet', 'Bank']));
    expect(preview.matchedCategoryNames, contains('Food'));
    expect(preview.transactions.first.type, TransactionType.transfer);
    expect(preview.transactions.last.note, 'Lunch, "team"');
    expect(preview.transactions.last.createdAt, importedAt);
  });

  test('skips existing and in-file duplicate transactions deterministically', () {
    final row = FlowCsvExporter.build(
      accounts: accounts,
      categories: categories,
      transactions: [
        Transaction(
          type: TransactionType.expense,
          amount: 50000,
          accountId: 1,
          categoryId: 2,
          note: 'Lunch',
          occurredAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    ).split('\r\n').last;
    final csv = [FlowCsvExporter.headers.join(','), row, row].join('\r\n');

    final preview = FlowCsvImporter.preview(
      csv: csv,
      accounts: accounts,
      categories: categories,
      existingTransactions: [
        Transaction(
          id: 9,
          type: TransactionType.expense,
          amount: 50000,
          accountId: 1,
          categoryId: 2,
          note: 'Lunch',
          occurredAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
      importedAt: importedAt,
    );

    expect(preview.readyCount, 0);
    expect(preview.skippedDuplicates, 2);
    expect(preview.errors, isEmpty);
  });

  test('reports invalid rows without blocking valid rows', () {
    final csv = [
      FlowCsvExporter.headers.join(','),
      '${timestamp.toIso8601String()},Income,100000,Bank,,Salary,Payroll',
      '${timestamp.toIso8601String()},Expense,0,Bank,,Food,Bad amount',
      '${timestamp.toIso8601String()},Transfer,25000,Bank,,Food,Bad transfer',
      '${timestamp.toIso8601String()},Expense,20000,Missing,,Food,Bad account',
    ].join('\r\n');

    final preview = FlowCsvImporter.preview(
      csv: csv,
      accounts: accounts,
      categories: categories,
      existingTransactions: const [],
      importedAt: importedAt,
    );

    expect(preview.readyCount, 1);
    expect(preview.errorCount, 3);
    expect(preview.errors.map((error) => error.rowNumber), [3, 4, 5]);
    expect(preview.errors.first.message, contains('Amount'));
  });

  test('rejects non Flow export headers', () {
    final preview = FlowCsvImporter.preview(
      csv: 'wrong,headers\nvalue,value',
      accounts: accounts,
      categories: categories,
      existingTransactions: const [],
    );

    expect(preview.readyCount, 0);
    expect(preview.singleError, contains('headers'));
  });
}

extension on FlowCsvImportPreview {
  String get singleError => errors.single.message;
}

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models/models.dart';

class FlowCsvExporter {
  const FlowCsvExporter._();

  static const headers = [
    'Date',
    'Type',
    'Amount',
    'Account',
    'Destination Account',
    'Category',
    'Note',
  ];

  static String build({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    final accountNames = {
      for (final account in accounts)
        if (account.id != null) account.id!: account.name,
    };
    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };
    final sorted = transactions.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final rows = <List<String>>[
      headers,
      for (final transaction in sorted)
        [
          transaction.occurredAt.toIso8601String(),
          _typeLabel(transaction.type),
          transaction.amount.toString(),
          accountNames[transaction.accountId] ??
              'Account ${transaction.accountId}',
          transaction.destinationAccountId == null
              ? ''
              : accountNames[transaction.destinationAccountId] ??
                    'Account ${transaction.destinationAccountId}',
          transaction.categoryId == null
              ? ''
              : categoryNames[transaction.categoryId] ??
                    'Category ${transaction.categoryId}',
          transaction.note ?? '',
        ],
    ];
    return rows.map((row) => row.map(_escape).join(',')).join('\r\n');
  }

  static Future<File> write({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final file = File('${directory.path}/flow-transactions-$timestamp.csv');
    return file.writeAsString(
      build(
        transactions: transactions,
        accounts: accounts,
        categories: categories,
      ),
    );
  }

  static String _escape(String value) {
    if (!value.contains(RegExp(r'[",\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
}

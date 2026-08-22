import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';

void main() {
  test('builds a monthly PDF with summary and transaction rows', () {
    final timestamp = DateTime.utc(2026, 8, 9, 12);
    final bytes = FlowReportExporter.buildMonthlyPdf(
      month: DateTime(2026, 8),
      currency: 'IDR',
      accounts: [
        Account(
          id: 1,
          name: 'Cash',
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
          note: 'Lunch',
          occurredAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    );
    final pdf = latin1.decode(bytes);

    expect(pdf, startsWith('%PDF-1.4'));
    expect(pdf, contains('Flow Monthly Report'));
    expect(pdf, contains('Lunch'));
    expect(pdf, contains('xref'));
    expect(pdf, contains('%%EOF'));
  });

  test('builds a readable empty monthly PDF', () {
    final bytes = FlowReportExporter.buildMonthlyPdf(
      month: DateTime(2026, 8),
      currency: 'IDR',
      accounts: const [],
      categories: const [],
      transactions: const [],
    );
    final pdf = latin1.decode(bytes);

    expect(pdf, contains('No transactions for this period.'));
    expect(pdf, contains('Page 1 of 1'));
  });
}

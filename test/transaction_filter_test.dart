import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';

void main() {
  final date = DateTime.utc(2026, 8, 9);

  Transaction transaction({
    required TransactionType type,
    required int accountId,
    int? destinationAccountId,
    int? categoryId,
    String? note,
    DateTime? occurredAt,
  }) => Transaction(
    type: type,
    amount: 100,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    categoryId: categoryId,
    note: note,
    occurredAt: occurredAt ?? date,
    createdAt: date,
    updatedAt: date,
  );

  final transactions = [
    transaction(
      type: TransactionType.expense,
      accountId: 1,
      categoryId: 10,
      note: 'Lunch',
    ),
    transaction(type: TransactionType.income, accountId: 1, note: 'Salary'),
    transaction(
      type: TransactionType.transfer,
      accountId: 1,
      destinationAccountId: 2,
    ),
  ];

  test('matches category text, type, account, and date range together', () {
    final filter = FlowTransactionFilter(
      query: 'food',
      type: TransactionType.expense,
      accountId: 1,
      categoryId: 10,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31, 23, 59, 59),
    );

    expect(
      filter.apply(
        transactions,
        categoryNames: const {10: 'Food'},
      ),
      hasLength(1),
    );
  });

  test('an account filter includes both sides of a transfer', () {
    final matches = const FlowTransactionFilter(accountId: 2).apply(
      transactions,
    );

    expect(matches.single.type, TransactionType.transfer);
  });
}

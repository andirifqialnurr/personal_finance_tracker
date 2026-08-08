import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/statistics_page.dart';

void main() {
  final month = DateTime(2026, 8);

  Transaction transaction({
    required TransactionType type,
    required int amount,
    int? categoryId,
    DateTime? date,
  }) => Transaction(
    type: type,
    amount: amount,
    accountId: 1,
    categoryId: categoryId,
    occurredAt: date ?? DateTime(2026, 8, 3),
    createdAt: month,
    updatedAt: month,
  );

  test('aggregates income and expense for the selected month', () {
    final data = StatisticsData.fromTransactions([
      transaction(type: TransactionType.income, amount: 500000),
      transaction(type: TransactionType.expense, amount: 100000, categoryId: 1),
      transaction(type: TransactionType.expense, amount: 50000, categoryId: 1),
      transaction(type: TransactionType.transfer, amount: 900000),
      transaction(
        type: TransactionType.expense,
        amount: 700000,
        categoryId: 2,
        date: DateTime(2026, 7, 31),
      ),
    ], month);

    expect(data.income, 500000);
    expect(data.expense, 150000);
    expect(data.categories.first.id, 1);
    expect(data.categories.first.amount, 150000);
    expect(data.weeks.first.amount, 150000);
  });

  test('returns an empty-safe result when there are no transactions', () {
    final data = StatisticsData.fromTransactions(const [], month);

    expect(data.hasData, isFalse);
    expect(data.categories, isEmpty);
    expect(data.weeks, hasLength(5));
    expect(data.weeks.every((week) => week.amount == 0), isTrue);
  });
}

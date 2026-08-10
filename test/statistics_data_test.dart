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
    expect(data.trend, hasLength(31));
    expect(data.trend[2].label, '3');
    expect(data.trend[2].amount, 150000);
  });

  test('returns an empty-safe result when there are no transactions', () {
    final data = StatisticsData.fromTransactions(const [], month);

    expect(data.hasData, isFalse);
    expect(data.categories, isEmpty);
    expect(data.trend, hasLength(31));
    expect(data.trend.every((point) => point.amount == 0), isTrue);
  });

  test('yearly trend aggregates expenses by month', () {
    final data = StatisticsData.fromTransactions(
      [
        transaction(
          type: TransactionType.expense,
          amount: 700000,
          date: DateTime(2026, 7, 31),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 150000,
          date: DateTime(2026, 8, 3),
        ),
      ],
      month,
      period: StatisticsPeriod.yearly,
    );

    expect(data.trend, hasLength(12));
    expect(data.trend[6].label, 'Jul');
    expect(data.trend[6].amount, 700000);
    expect(data.trend[7].amount, 150000);
  });

  test('date trend focuses on the selected calendar date', () {
    final data = StatisticsData.fromTransactions(
      [
        transaction(
          type: TransactionType.expense,
          amount: 150000,
          date: DateTime(2026, 8, 3),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 700000,
          date: DateTime(2026, 8, 4),
        ),
      ],
      DateTime(2026, 8, 3),
      period: StatisticsPeriod.date,
    );

    expect(data.trend, hasLength(1));
    expect(data.trend.single.label, '03/08');
    expect(data.trend.single.amount, 150000);
  });

  test('monthly trend supports leap-year February', () {
    final data = StatisticsData.fromTransactions(
      const [],
      DateTime(2028, 2, 15),
      period: StatisticsPeriod.monthly,
    );

    expect(data.trend, hasLength(29));
    expect(data.trend.first.label, '1');
    expect(data.trend.last.label, '29');
  });
}

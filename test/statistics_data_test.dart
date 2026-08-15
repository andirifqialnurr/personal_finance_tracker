import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/statistics_page.dart';

void main() {
  final anchor = DateTime(2026, 8, 13, 12);

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
    occurredAt: date ?? DateTime(2026, 8, 13, 10),
    createdAt: anchor,
    updatedAt: anchor,
  );

  test('default weekly trend aggregates expenses for the last seven days', () {
    final data = StatisticsData.fromTransactions([
      transaction(type: TransactionType.income, amount: 500000),
      transaction(type: TransactionType.expense, amount: 100000, categoryId: 1),
      transaction(type: TransactionType.expense, amount: 50000, categoryId: 1),
      transaction(type: TransactionType.transfer, amount: 900000),
      transaction(
        type: TransactionType.expense,
        amount: 700000,
        categoryId: 2,
        date: DateTime(2026, 8, 6, 23, 59),
      ),
    ], anchor);

    expect(data.income, 500000);
    expect(data.expense, 150000);
    expect(data.categories.first.id, 1);
    expect(data.categories.first.amount, 150000);
    expect(data.trend, hasLength(7));
    expect(data.trend.first.label, '07/08');
    expect(data.trend.last.label, '13/08');
    expect(data.trend.last.amount, 150000);
  });

  test('returns an empty-safe weekly result when there are no transactions', () {
    final data = StatisticsData.fromTransactions(const [], anchor);

    expect(data.hasData, isFalse);
    expect(data.categories, isEmpty);
    expect(data.trend, hasLength(7));
    expect(data.trend.every((point) => point.amount == 0), isTrue);
  });

  test('daily trend buckets selected date expenses by four-hour windows', () {
    final data = StatisticsData.fromTransactions(
      [
        transaction(
          type: TransactionType.expense,
          amount: 25000,
          date: DateTime(2026, 8, 13, 1, 30),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 40000,
          date: DateTime(2026, 8, 13, 10),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 700000,
          date: DateTime(2026, 8, 14),
        ),
      ],
      anchor,
      period: StatisticsPeriod.daily,
    );

    expect(data.expense, 65000);
    expect(data.trend, hasLength(6));
    expect(data.trend[0].label, '00:00');
    expect(data.trend[0].amount, 25000);
    expect(data.trend[2].label, '08:00');
    expect(data.trend[2].amount, 40000);
  });

  test('weekly trend supports a seven-day range across month boundaries', () {
    final data = StatisticsData.fromTransactions(
      [
        transaction(
          type: TransactionType.expense,
          amount: 700000,
          date: DateTime(2026, 7, 31, 23),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 150000,
          date: DateTime(2026, 8, 1, 9),
        ),
      ],
      DateTime(2026, 8, 3),
      period: StatisticsPeriod.weekly,
    );

    expect(data.trend.first.label, '28/07');
    expect(data.trend[3].label, '31/07');
    expect(data.trend[3].amount, 700000);
    expect(data.trend[4].label, '01/08');
    expect(data.trend[4].amount, 150000);
  });

  test('monthly trend aggregates the last twelve months', () {
    final data = StatisticsData.fromTransactions(
      [
        transaction(
          type: TransactionType.expense,
          amount: 700000,
          date: DateTime(2025, 9, 30),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 150000,
          date: DateTime(2026, 8, 3),
        ),
      ],
      anchor,
      period: StatisticsPeriod.monthly,
    );

    expect(data.trend, hasLength(12));
    expect(data.trend.first.label, 'Sep');
    expect(data.trend.first.amount, 700000);
    expect(data.trend.last.label, 'Aug');
    expect(data.trend.last.amount, 150000);
  });

  test('compact Rupiah formatter keeps axis labels short', () {
    expect(formatCompactCurrency(1200, 'IDR'), 'Rp 1 rb');
    expect(formatCompactCurrency(1200000, 'IDR'), 'Rp 1,2 jt');
    expect(formatCompactCurrency(1250000000, 'IDR'), 'Rp 1,3 M');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/cash_flow_data.dart';
import 'package:personal_finance_tracker/data/models/models.dart';

void main() {
  Transaction transaction({
    required TransactionType type,
    required int amount,
    required DateTime date,
  }) => Transaction(
    type: type,
    amount: amount,
    accountId: 1,
    occurredAt: date,
    createdAt: date,
    updatedAt: date,
  );

  test('cash flow aggregates twelve months into three four-month pages', () {
    final data = CashFlowYearData.fromTransactions(
      year: 2026,
      transactions: [
        transaction(
          type: TransactionType.income,
          amount: 100000,
          date: DateTime(2026, 1, 2),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 40000,
          date: DateTime(2026, 1, 3),
        ),
        transaction(
          type: TransactionType.transfer,
          amount: 900000,
          date: DateTime(2026, 1, 4),
        ),
        transaction(
          type: TransactionType.income,
          amount: 1200000,
          date: DateTime(2026, 8, 1),
        ),
        transaction(
          type: TransactionType.expense,
          amount: 300000,
          date: DateTime(2025, 8, 1),
        ),
      ],
    );

    expect(data.months, hasLength(12));
    expect(data.page(0).map((item) => item.label), [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
    ]);
    expect(data.page(1).map((item) => item.label), [
      'May',
      'Jun',
      'Jul',
      'Aug',
    ]);
    expect(data.page(2).map((item) => item.label), [
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ]);
    expect(data.months.first.income, 100000);
    expect(data.months.first.expense, 40000);
    expect(data.months[7].income, 1200000);
    expect(data.months[7].expense, 0);
  });

  test('cash flow axis produces five adaptive, evenly spaced ticks', () {
    final scale = CashFlowAxisScale.fromValues([100000, 760000, 1250000]);

    expect(scale.ticks, hasLength(5));
    expect(scale.ticks.first, 0);
    expect(scale.ticks.last, scale.maximum);
    expect(scale.maximum, greaterThanOrEqualTo(1250000));
    expect(scale.ticks, [
      0,
      scale.interval,
      scale.interval * 2,
      scale.interval * 3,
      scale.interval * 4,
    ]);
  });

  test('empty cash flow uses a readable five-tick baseline', () {
    final scale = CashFlowAxisScale.fromValues([0, 0]);

    expect(scale.ticks, [0, 25000, 50000, 75000, 100000]);
  });

  test('cash flow axis abbreviates values without a currency prefix', () {
    expect(formatCashFlowAxisValue(100000), '100k');
    expect(formatCashFlowAxisValue(1000000), '1M');
    expect(formatCashFlowAxisValue(1500000), '1.5M');
    expect(formatCashFlowAxisValue(1000000000), '1B');
  });
}

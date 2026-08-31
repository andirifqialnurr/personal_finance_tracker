import 'dart:math' as math;

import 'models/models.dart';

class CashFlowMonthTotal {
  const CashFlowMonthTotal({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;

  String get label => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month.month - 1];
}

class CashFlowYearData {
  const CashFlowYearData({required this.year, required this.months});

  static const pageSize = 4;
  static const pageCount = 3;

  final int year;
  final List<CashFlowMonthTotal> months;

  factory CashFlowYearData.fromTransactions({
    required int year,
    required Iterable<Transaction> transactions,
  }) {
    final income = List<int>.filled(12, 0);
    final expense = List<int>.filled(12, 0);
    for (final transaction in transactions) {
      if (transaction.occurredAt.year != year) continue;
      final index = transaction.occurredAt.month - 1;
      switch (transaction.type) {
        case TransactionType.income:
          income[index] += transaction.amount;
        case TransactionType.expense:
          expense[index] += transaction.amount;
        case TransactionType.transfer:
          break;
      }
    }

    return CashFlowYearData(
      year: year,
      months: List.unmodifiable([
        for (var index = 0; index < 12; index += 1)
          CashFlowMonthTotal(
            month: DateTime(year, index + 1),
            income: income[index],
            expense: expense[index],
          ),
      ]),
    );
  }

  List<CashFlowMonthTotal> page(int pageIndex) {
    final safeIndex = pageIndex.clamp(0, pageCount - 1);
    final start = safeIndex * pageSize;
    return months.sublist(start, start + pageSize);
  }
}

class CashFlowAxisScale {
  const CashFlowAxisScale({required this.maximum, required this.interval});

  static const tickCount = 5;

  final int maximum;
  final int interval;

  List<int> get ticks =>
      List.generate(tickCount, (index) => interval * index, growable: false);

  factory CashFlowAxisScale.fromValues(Iterable<int> values) {
    final highest = values.fold<int>(0, math.max);
    if (highest <= 0) {
      return const CashFlowAxisScale(maximum: 100000, interval: 25000);
    }

    final rawInterval = highest / (tickCount - 1);
    final magnitude = math
        .pow(10, (math.log(rawInterval) / math.ln10).floor())
        .toDouble();
    final normalized = rawInterval / magnitude;
    final niceNormalized = switch (normalized) {
      <= 1 => 1.0,
      <= 2 => 2.0,
      <= 2.5 => 2.5,
      <= 5 => 5.0,
      _ => 10.0,
    };
    final interval = math.max(1, (niceNormalized * magnitude).ceil());
    return CashFlowAxisScale(
      maximum: interval * (tickCount - 1),
      interval: interval,
    );
  }
}

String formatCashFlowAxisValue(int amount) {
  final absolute = amount.abs();
  if (absolute >= 1000000000) {
    return _abbreviate(amount, 1000000000, 'B');
  }
  if (absolute >= 1000000) return _abbreviate(amount, 1000000, 'M');
  if (absolute >= 1000) return _abbreviate(amount, 1000, 'k');
  return '$amount';
}

String _abbreviate(int amount, int divisor, String suffix) {
  final value = amount / divisor;
  final text = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  return '$text$suffix';
}

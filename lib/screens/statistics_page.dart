import 'package:flutter/material.dart';

import '../components/flow_card.dart';
import '../components/flow_empty_state.dart';
import '../components/flow_segmented_control.dart';
import '../data/models/models.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    required this.transactions,
    this.categories = const [],
    this.currency = 'IDR',
  });

  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _selectedDate = DateTime.now();
  StatisticsPeriod _period = StatisticsPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final data = StatisticsData.fromTransactions(
      widget.transactions,
      _selectedDate,
      period: _period,
      categoryNames: {
        for (final category in widget.categories)
          if (category.id != null) category.id!: category.name,
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.md,
        FlowSpacing.sm,
        FlowSpacing.md,
        FlowSpacing.xxl,
      ),
      children: [
        _PeriodSelector(
          period: _period,
          date: _selectedDate,
          onPeriodChanged: (period) => setState(() => _period = period),
          onPrevious: () => _changePeriodDate(-1),
          onNext: () => _changePeriodDate(1),
          onPickDate: _pickDate,
        ),
        const SizedBox(height: FlowSpacing.md),
        if (data.hasData) ...[
          _SummaryCard(data: data, currency: widget.currency),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Spending by category'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.chart,
            child: _CategoryChart(
              categories: data.categories,
              currency: widget.currency,
            ),
          ),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Spending trend'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.chart,
            child: _SpendingTrendChart(points: data.trend),
          ),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Top categories'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.summary,
            child: _TopCategories(
              categories: data.categories,
              currency: widget.currency,
            ),
          ),
        ] else
          const FlowEmptyState(
            icon: Icons.insights_outlined,
            title: 'No statistics yet',
            message:
                'Add income or expense transactions to see your monthly insights.',
          ),
      ],
    );
  }

  void _changePeriodDate(int offset) {
    setState(() {
      _selectedDate = switch (_period) {
        StatisticsPeriod.yearly => DateTime(_selectedDate.year + offset, 1),
        StatisticsPeriod.monthly => DateTime(
          _selectedDate.year,
          _selectedDate.month + offset,
          1,
        ),
        StatisticsPeriod.date => DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day + offset,
        ),
      };
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );
    if (selected != null && mounted) setState(() => _selectedDate = selected);
  }
}

enum StatisticsPeriod { yearly, monthly, date }

class StatisticsData {
  const StatisticsData({
    required this.income,
    required this.expense,
    required this.categories,
    required this.trend,
    this.categoryNames = const {},
  });

  final int income;
  final int expense;
  final List<CategoryStat> categories;
  final List<TrendPoint> trend;
  final Map<int, String> categoryNames;

  bool get hasData => income > 0 || expense > 0;

  factory StatisticsData.fromTransactions(
    List<Transaction> transactions,
    DateTime anchor, {
    StatisticsPeriod period = StatisticsPeriod.monthly,
    Map<int, String> categoryNames = const {},
  }) {
    var income = 0;
    var expense = 0;
    final categoryTotals = <int?, int>{};
    final trendTotals = <DateTime, int>{};
    final periodStart = _periodStart(period, anchor);
    final periodEnd = _periodEnd(period, periodStart);
    for (final transaction in transactions) {
      if (transaction.occurredAt.isBefore(periodStart) ||
          !transaction.occurredAt.isBefore(periodEnd)) {
        continue;
      }
      switch (transaction.type) {
        case TransactionType.income:
          income += transaction.amount;
        case TransactionType.expense:
          expense += transaction.amount;
          categoryTotals.update(
            transaction.categoryId,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
          final bucket = _trendBucket(period, transaction.occurredAt);
          trendTotals.update(
            bucket,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
        case TransactionType.transfer:
          break;
      }
    }
    final categories =
        categoryTotals.entries
            .map(
              (entry) => CategoryStat(
                id: entry.key,
                amount: entry.value,
                name: entry.key == null ? null : categoryNames[entry.key],
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    return StatisticsData(
      income: income,
      expense: expense,
      categories: categories,
      trend: _buildTrend(period, periodStart, trendTotals),
      categoryNames: categoryNames,
    );
  }

  static DateTime _periodStart(StatisticsPeriod period, DateTime anchor) =>
      switch (period) {
        StatisticsPeriod.yearly => DateTime(anchor.year, 1),
        StatisticsPeriod.monthly => DateTime(anchor.year, anchor.month),
        StatisticsPeriod.date => DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
        ),
      };

  static DateTime _periodEnd(StatisticsPeriod period, DateTime start) =>
      switch (period) {
        StatisticsPeriod.yearly => DateTime(start.year + 1, 1),
        StatisticsPeriod.monthly => DateTime(start.year, start.month + 1),
        StatisticsPeriod.date => DateTime(
          start.year,
          start.month,
          start.day + 1,
        ),
      };

  static DateTime _trendBucket(StatisticsPeriod period, DateTime date) =>
      switch (period) {
        StatisticsPeriod.yearly => DateTime(date.year, date.month),
        StatisticsPeriod.monthly => DateTime(date.year, date.month, date.day),
        StatisticsPeriod.date => DateTime(date.year, date.month, date.day),
      };

  static List<TrendPoint> _buildTrend(
    StatisticsPeriod period,
    DateTime start,
    Map<DateTime, int> totals,
  ) {
    final count = switch (period) {
      StatisticsPeriod.yearly => 12,
      StatisticsPeriod.monthly => DateTime(start.year, start.month + 1, 0).day,
      StatisticsPeriod.date => 1,
    };
    final points = <TrendPoint>[];
    for (var index = 0; index < count; index++) {
      final bucket = switch (period) {
        StatisticsPeriod.yearly => DateTime(start.year, index + 1),
        StatisticsPeriod.monthly => DateTime(
          start.year,
          start.month,
          index + 1,
        ),
        StatisticsPeriod.date => start,
      };
      points.add(
        TrendPoint(
          date: bucket,
          label: _trendLabel(period, bucket),
          amount: totals[bucket] ?? 0,
        ),
      );
    }
    return points;
  }

  static String _trendLabel(
    StatisticsPeriod period,
    DateTime date,
  ) => switch (period) {
    StatisticsPeriod.yearly => _monthName(date.month).substring(0, 3),
    StatisticsPeriod.monthly => '${date.day}',
    StatisticsPeriod.date =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
  };

  static String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class CategoryStat {
  const CategoryStat({required this.id, required this.amount, this.name});

  final int? id;
  final int amount;
  final String? name;

  String get label => name ?? (id == null ? 'Uncategorized' : 'Category $id');
}

class TrendPoint {
  const TrendPoint({
    required this.date,
    required this.label,
    required this.amount,
  });

  final DateTime date;
  final String label;
  final int amount;
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.categories, required this.currency});

  final List<CategoryStat> categories;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, item) => sum + item.amount);
    return Column(
      children: [
        SizedBox(
          height: 176,
          child: Row(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _DonutPainter(categories: categories, total: total),
                  child: Center(
                    child: Text(
                      formatCurrency(total, currency),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FlowSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < categories.length; index++)
                      _LegendRow(
                        label: categories[index].label,
                        amount: categories[index].amount,
                        color: _chartColor(index, context),
                        total: total,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          'Each segment shows its category share of expense.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  static Color _chartColor(int index, BuildContext context) {
    final colors = [
      FlowColors.expense,
      Theme.of(context).colorScheme.primary,
      FlowColors.chartAmber,
      FlowColors.chartBlue,
      FlowColors.chartPurple,
    ];
    return colors[index % colors.length];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.total,
  });

  final String label;
  final int amount;
  final Color color;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (amount * 100 / total).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlowSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: FlowSpacing.xs),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text('$percent%', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SpendingTrendChart extends StatelessWidget {
  const _SpendingTrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 180,
        child: CustomPaint(
          painter: _BarChartPainter(
            points: points,
            color: Theme.of(context).colorScheme.primary,
            mutedColor: Theme.of(context).colorScheme.outline,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final point in _visibleTrendLabels(points))
            Text(point.label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      const SizedBox(height: FlowSpacing.xs),
      Text(
        'Bars show expense totals for the selected period.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  static List<TrendPoint> _visibleTrendLabels(List<TrendPoint> points) {
    if (points.length <= 12) return points;
    final step = (points.length / 6).ceil();
    final visible = <TrendPoint>[];
    for (var index = 0; index < points.length; index += step) {
      visible.add(points[index]);
    }
    if (visible.last != points.last) visible.add(points.last);
    return visible;
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.categories, required this.currency});

  final List<CategoryStat> categories;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, item) => sum + item.amount);
    if (categories.isEmpty) {
      return Text(
        'No categorized expenses this month.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: [
        for (var index = 0; index < categories.length && index < 5; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == categories.length - 1 || index == 4
                  ? 0
                  : FlowSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    categories[index].label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  formatCurrency(categories[index].amount, currency),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: FlowSpacing.sm),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(categories[index].amount * 100 / total).round()}%',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.categories, required this.total});

  final List<CategoryStat> categories;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    final stroke = radius * 0.32;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -3.14159 / 2;
    for (var index = 0; index < categories.length; index++) {
      final sweep = total == 0
          ? 0.0
          : categories[index].amount / total * 6.28318;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = _colors[index % _colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  static const _colors = [
    FlowColors.expense,
    FlowColors.accent,
    FlowColors.chartAmber,
    FlowColors.chartBlue,
    FlowColors.chartPurple,
  ];

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories || oldDelegate.total != total;
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.points,
    required this.color,
    required this.mutedColor,
  });

  final List<TrendPoint> points;
  final Color color;
  final Color mutedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxAmount = points.fold<int>(
      0,
      (max, point) => point.amount > max ? point.amount : max,
    );
    final baseline = size.height - 8;
    final chartHeight = size.height - 24;
    final width = size.width / points.length;
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()..color = mutedColor,
    );
    for (var index = 0; index < points.length; index++) {
      final height = maxAmount == 0
          ? 0.0
          : chartHeight * points[index].amount / maxAmount;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * index + width * .25,
          baseline - height,
          width * .5,
          height,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(bar, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.period,
    required this.date,
    required this.onPeriodChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final StatisticsPeriod period;
  final DateTime date;
  final ValueChanged<StatisticsPeriod> onPeriodChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FlowSegmentedControl(
        labels: const ['Tahunan', 'Bulanan', 'Tanggal'],
        selectedIndex: period.index,
        onChanged: (index) => onPeriodChanged(StatisticsPeriod.values[index]),
      ),
      const SizedBox(height: FlowSpacing.sm),
      FlowCard(
        variant: FlowCardVariant.action,
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Previous period',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: period == StatisticsPeriod.date
                  ? TextButton.icon(
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(_periodTitle(period, date)),
                    )
                  : Text(
                      _periodTitle(period, date),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: 'Next period',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ],
  );

  static String _periodTitle(
    StatisticsPeriod period,
    DateTime date,
  ) => switch (period) {
    StatisticsPeriod.yearly => '${date.year}',
    StatisticsPeriod.monthly => '${_monthName(date.month)} ${date.year}',
    StatisticsPeriod.date =>
      '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}',
  };

  static String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.currency});

  final StatisticsData data;
  final String currency;

  @override
  Widget build(BuildContext context) => FlowCard(
    variant: FlowCardVariant.summary,
    child: Row(
      children: [
        Expanded(
          child: _SummaryValue(
            label: 'Income',
            value: data.income,
            color: FlowColors.income,
            currency: currency,
          ),
        ),
        const SizedBox(width: FlowSpacing.md),
        Expanded(
          child: _SummaryValue(
            label: 'Expense',
            value: data.expense,
            color: FlowColors.expense,
            currency: currency,
          ),
        ),
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
    required this.currency,
  });

  final String label;
  final int value;
  final Color color;
  final String currency;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: FlowSpacing.xs),
      Text(
        formatCurrency(value, currency),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

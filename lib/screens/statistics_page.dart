import 'package:flutter/material.dart';

import '../components/flow_card.dart';
import '../components/flow_empty_state.dart';
import '../data/models/models.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final data = StatisticsData.fromTransactions(
      widget.transactions,
      _selectedMonth,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.md,
        FlowSpacing.sm,
        FlowSpacing.md,
        FlowSpacing.xxl,
      ),
      children: [
        _MonthSelector(
          month: _selectedMonth,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: FlowSpacing.md),
        if (data.hasData) ...[
          _SummaryCard(data: data),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Spending by category'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.chart,
            child: _CategoryChart(categories: data.categories),
          ),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Weekly spending trend'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.chart,
            child: _WeeklyTrendChart(weeks: data.weeks),
          ),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Top categories'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.summary,
            child: _TopCategories(categories: data.categories),
          ),
        ] else
          const FlowEmptyState(
            icon: Icons.insights_outlined,
            title: 'No statistics yet',
            message: 'Add income or expense transactions to see your monthly insights.',
          ),
      ],
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
  }
}

class StatisticsData {
  const StatisticsData({
    required this.income,
    required this.expense,
    required this.categories,
    required this.weeks,
  });

  final int income;
  final int expense;
  final List<CategoryStat> categories;
  final List<WeekStat> weeks;

  bool get hasData => income > 0 || expense > 0;

  factory StatisticsData.fromTransactions(
    List<Transaction> transactions,
    DateTime month,
  ) {
    var income = 0;
    var expense = 0;
    final categoryTotals = <int?, int>{};
    final weekTotals = List<int>.filled(5, 0);
    for (final transaction in transactions) {
      if (transaction.occurredAt.year != month.year ||
          transaction.occurredAt.month != month.month) {
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
          final week = ((transaction.occurredAt.day - 1) ~/ 7).clamp(0, 4);
          weekTotals[week] += transaction.amount;
        case TransactionType.transfer:
          break;
      }
    }
    final categories = categoryTotals.entries
        .map((entry) => CategoryStat(id: entry.key, amount: entry.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return StatisticsData(
      income: income,
      expense: expense,
      categories: categories,
      weeks: [
        for (var index = 0; index < weekTotals.length; index++)
          WeekStat(label: 'W${index + 1}', amount: weekTotals[index]),
      ],
    );
  }
}

class CategoryStat {
  const CategoryStat({required this.id, required this.amount});

  final int? id;
  final int amount;

  String get label => id == null ? 'Uncategorized' : 'Category $id';
}

class WeekStat {
  const WeekStat({required this.label, required this.amount});

  final String label;
  final int amount;
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.categories});

  final List<CategoryStat> categories;

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
                  painter: _DonutPainter(
                    categories: categories,
                    total: total,
                  ),
                  child: Center(
                    child: Text(
                      'Rp ${_formatAmount(total)}',
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
      const Color(0xFFE0A458),
      const Color(0xFF6D8FC7),
      const Color(0xFF9B7EBD),
    ];
    return colors[index % colors.length];
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.amount, required this.color, required this.total});

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
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: FlowSpacing.xs),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
          Text('$percent%', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  const _WeeklyTrendChart({required this.weeks});

  final List<WeekStat> weeks;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 180,
        child: CustomPaint(
          painter: _BarChartPainter(
            weeks: weeks,
            color: Theme.of(context).colorScheme.primary,
            mutedColor: Theme.of(context).colorScheme.outline,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [for (final week in weeks) Text(week.label, style: Theme.of(context).textTheme.labelSmall)],
      ),
      const SizedBox(height: FlowSpacing.xs),
      Text(
        'Bars show expense totals for each week of the month.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.categories});

  final List<CategoryStat> categories;

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
                  'Rp ${_formatAmount(categories[index].amount)}',
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
      final sweep = total == 0 ? 0.0 : categories[index].amount / total * 6.28318;
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

  static const _colors = [FlowColors.expense, FlowColors.accent, Color(0xFFE0A458), Color(0xFF6D8FC7), Color(0xFF9B7EBD)];

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.categories != categories || oldDelegate.total != total;
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({required this.weeks, required this.color, required this.mutedColor});

  final List<WeekStat> weeks;
  final Color color;
  final Color mutedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxAmount = weeks.fold<int>(0, (max, week) => week.amount > max ? week.amount : max);
    final baseline = size.height - 8;
    final chartHeight = size.height - 24;
    final width = size.width / weeks.length;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), Paint()..color = mutedColor);
    for (var index = 0; index < weeks.length; index++) {
      final height = maxAmount == 0 ? 0.0 : chartHeight * weeks[index].amount / maxAmount;
      final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(width * index + width * .25, baseline - height, width * .5, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(bar, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.weeks != weeks;
}

String _formatAmount(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'(?=(\d{3})+(?!\d))'),
  (match) => '.',
);

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => FlowCard(
    variant: FlowCardVariant.action,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${_monthName(month.month)} ${month.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

  static String _monthName(int month) => const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ][month - 1];
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) => FlowCard(
    variant: FlowCardVariant.summary,
    child: Row(
      children: [
        Expanded(child: _SummaryValue(label: 'Income', value: data.income, color: FlowColors.income)),
        const SizedBox(width: FlowSpacing.md),
        Expanded(child: _SummaryValue(label: 'Expense', value: data.expense, color: FlowColors.expense)),
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: FlowSpacing.xs),
      Text(
        'Rp ${_formatAmount(value)}',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
      ),
    ],
  );

  static String _formatAmount(int amount) => amount.toString().replaceAllMapped(
    RegExp(r'(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium,
  );
}

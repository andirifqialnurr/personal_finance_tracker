import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/flow_apex_chart.dart';
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
  StatisticsPeriod _period = StatisticsPeriod.weekly;

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
        FlowSpacing.md,
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
            density: FlowCardDensity.featured,
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
            density: FlowCardDensity.featured,
            child: _SpendingTrendChart(
              points: data.trend,
              currency: widget.currency,
            ),
          ),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Top categories'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.summary,
            density: FlowCardDensity.standard,
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
                'Add income or expense transactions to see insights for the selected period.',
          ),
      ],
    );
  }

  void _changePeriodDate(int offset) {
    setState(() {
      _selectedDate = switch (_period) {
        StatisticsPeriod.daily => DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day + offset,
        ),
        StatisticsPeriod.weekly => DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day + (offset * 7),
        ),
        StatisticsPeriod.monthly => DateTime(
          _selectedDate.year,
          _selectedDate.month + offset,
          1,
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

enum StatisticsPeriod { daily, weekly, monthly }

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
    StatisticsPeriod period = StatisticsPeriod.weekly,
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
        StatisticsPeriod.daily => DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
        ),
        StatisticsPeriod.weekly => DateTime(
          anchor.year,
          anchor.month,
          anchor.day - 6,
        ),
        StatisticsPeriod.monthly => DateTime(anchor.year, anchor.month - 11),
      };

  static DateTime _periodEnd(
    StatisticsPeriod period,
    DateTime start,
  ) => switch (period) {
    StatisticsPeriod.daily => DateTime(start.year, start.month, start.day + 1),
    StatisticsPeriod.weekly => DateTime(start.year, start.month, start.day + 7),
    StatisticsPeriod.monthly => DateTime(start.year, start.month + 12),
  };

  static DateTime _trendBucket(StatisticsPeriod period, DateTime date) =>
      switch (period) {
        StatisticsPeriod.daily => DateTime(
          date.year,
          date.month,
          date.day,
          (date.hour ~/ 4) * 4,
        ),
        StatisticsPeriod.weekly => DateTime(date.year, date.month, date.day),
        StatisticsPeriod.monthly => DateTime(date.year, date.month),
      };

  static List<TrendPoint> _buildTrend(
    StatisticsPeriod period,
    DateTime start,
    Map<DateTime, int> totals,
  ) {
    final count = switch (period) {
      StatisticsPeriod.daily => 6,
      StatisticsPeriod.weekly => 7,
      StatisticsPeriod.monthly => 12,
    };
    final points = <TrendPoint>[];
    for (var index = 0; index < count; index++) {
      final bucket = switch (period) {
        StatisticsPeriod.daily => DateTime(
          start.year,
          start.month,
          start.day,
          index * 4,
        ),
        StatisticsPeriod.weekly => DateTime(
          start.year,
          start.month,
          start.day + index,
        ),
        StatisticsPeriod.monthly => DateTime(start.year, start.month + index),
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
    StatisticsPeriod.daily => '${date.hour.toString().padLeft(2, '0')}:00',
    StatisticsPeriod.weekly =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
    StatisticsPeriod.monthly => _monthName(date.month).substring(0, 3),
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

  String axisLabel(String currency) => formatCompactCurrency(amount, currency);

  String tooltipLabel(String currency) => formatCurrency(amount, currency);
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.categories, required this.currency});

  final List<CategoryStat> categories;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, item) => sum + item.amount);
    if (categories.isEmpty || total == 0) {
      return Text(
        'No categorized expenses for the selected period.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 340;
            final chart = FlowApexChart(
              height: stacked ? 148 : 176,
              options: _donutOptions(context, total),
            );
            final legend = Column(
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
            );
            if (stacked) {
              return Column(
                children: [
                  chart,
                  const SizedBox(height: FlowSpacing.gapGroup),
                  legend,
                ],
              );
            }
            return SizedBox(
              height: 176,
              child: Row(
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: FlowSpacing.md),
                  Expanded(child: legend),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _donutOptions(BuildContext context, int total) {
    final colors = [
      for (var index = 0; index < categories.length; index++)
        flowChartColorHex(_chartColor(index, context)),
    ];
    return {
      'chart': {
        'type': 'donut',
        'fontFamily': 'Montserrat',
        'animations': {'enabled': true, 'speed': 420},
      },
      'series': [for (final category in categories) category.amount],
      'labels': [for (final category in categories) category.label],
      'colors': colors,
      'legend': {'show': false},
      'dataLabels': {'enabled': false},
      'plotOptions': {
        'pie': {
          'donut': {'size': '62%'},
        },
      },
      'tooltip': {
        'y': {'prefix': '${currencySymbol(currency)} ', 'decimals': 0},
      },
    };
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: FlowSpacing.xs),
          Text('$percent%', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SpendingTrendChart extends StatefulWidget {
  const _SpendingTrendChart({required this.points, required this.currency});

  final List<TrendPoint> points;
  final String currency;

  @override
  State<_SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends State<_SpendingTrendChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _SpendingTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) _selectedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        _selectedIndex != null && _selectedIndex! < widget.points.length
        ? _selectedIndex
        : null;
    final selectedPoint = selectedIndex == null
        ? null
        : widget.points[selectedIndex];

    return Column(
      children: [
        SizedBox(
          key: const Key('statistics-line-chart'),
          height: 196,
          child: LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.points.isEmpty
                  ? null
                  : (details) => _selectPoint(
                      details.localPosition.dx,
                      constraints.maxWidth,
                    ),
              child: CustomPaint(
                painter: _SpendingTrendPainter(
                  points: widget.points,
                  currency: widget.currency,
                  lineColor: Theme.of(context).colorScheme.primary,
                  gridColor: Theme.of(context).colorScheme.outline,
                  labelColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        if (selectedPoint != null) ...[
          const SizedBox(height: FlowSpacing.xs),
          Text(
            '${selectedPoint.label}: ${selectedPoint.tooltipLabel(widget.currency)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ],
    );
  }

  void _selectPoint(double x, double width) {
    if (widget.points.isEmpty) return;
    final plotWidth = width - (_chartHorizontalPadding * 2);
    if (plotWidth <= 0) return;
    final normalizedX = ((x - _chartHorizontalPadding) / plotWidth).clamp(
      0.0,
      1.0,
    );
    final index = widget.points.length == 1
        ? 0
        : (normalizedX * (widget.points.length - 1)).round();
    setState(() => _selectedIndex = index);
  }
}

class _SpendingTrendPainter extends CustomPainter {
  const _SpendingTrendPainter({
    required this.points,
    required this.currency,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<TrendPoint> points;
  final String currency;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxAmount = math.max(
      1,
      points.fold<int>(0, (value, point) => math.max(value, point.amount)),
    );
    final axisUnit = _compactAxisUnit(maxAmount);
    final scaledMax = math.max<num>(
      1,
      _scaledChartValue(maxAmount, axisUnit.suffix),
    );
    final left = 46.0;
    final right = 8.0;
    final top = 10.0;
    final bottom = 28.0;
    final chartRect = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.42)
      ..strokeWidth = 1;

    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = chartRect.bottom - chartRect.height * ratio;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        _axisLabel((scaledMax * ratio), axisUnit),
        Offset(0, y - 6),
        maxWidth: left - 6,
        color: labelColor,
        align: TextAlign.right,
      );
    }

    final offsets = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final scaled = _scaledChartValue(points[index].amount, axisUnit.suffix);
      final x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * (index / (points.length - 1));
      final y = chartRect.bottom - chartRect.height * (scaled / scaledMax);
      offsets.add(Offset(x, y));
    }

    if (offsets.length == 1) {
      canvas.drawCircle(offsets.single, 4, Paint()..color = lineColor);
    } else {
      final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final offset in offsets.skip(1)) {
        linePath.lineTo(offset.dx, offset.dy);
      }
      final fillPath = Path.from(linePath)
        ..lineTo(offsets.last.dx, chartRect.bottom)
        ..lineTo(offsets.first.dx, chartRect.bottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = lineColor.withValues(alpha: 0.16),
      );
      canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      for (final offset in offsets) {
        canvas.drawCircle(offset, 3.5, Paint()..color = lineColor);
      }
    }

    for (final index in _visibleTrendIndexes(points.length)) {
      final x = points.length == 1
          ? chartRect.center.dx
          : chartRect.left + chartRect.width * (index / (points.length - 1));
      _drawText(
        canvas,
        points[index].label,
        Offset(x - 24, chartRect.bottom + 10),
        maxWidth: 48,
        color: labelColor,
        align: TextAlign.center,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required Color color,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Montserrat',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '',
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  String _axisLabel(num scaledValue, ({String suffix, int decimals}) unit) {
    final value = unit.decimals == 0
        ? scaledValue.round().toString()
        : _formatCompactDecimal(scaledValue);
    return '${currencySymbol(currency)} $value${unit.suffix}';
  }

  @override
  bool shouldRepaint(covariant _SpendingTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.currency != currency ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
  }
}

List<int> _visibleTrendIndexes(int length) {
  if (length <= 7) return [for (var index = 0; index < length; index++) index];
  final step = (length / 6).ceil();
  final visible = <int>[];
  for (var index = 0; index < length; index += step) {
    visible.add(index);
  }
  if (visible.last != length - 1) visible.add(length - 1);
  return visible;
}

const _chartHorizontalPadding = 12.0;

({String suffix, int decimals}) _compactAxisUnit(int maxAmount) {
  if (maxAmount >= 1000000000) return (suffix: ' M', decimals: 1);
  if (maxAmount >= 1000000) return (suffix: ' jt', decimals: 1);
  if (maxAmount >= 1000) return (suffix: ' rb', decimals: 0);
  return (suffix: '', decimals: 0);
}

num _scaledChartValue(int amount, String suffix) => switch (suffix.trim()) {
  'M' => amount / 1000000000,
  'jt' => amount / 1000000,
  'rb' => amount / 1000,
  _ => amount,
};

String formatCompactCurrency(int amount, String currency) {
  final symbol = currencySymbol(currency);
  if (amount >= 1000000000) {
    return '$symbol ${_formatCompactDecimal(amount / 1000000000)} M';
  }
  if (amount >= 1000000) {
    return '$symbol ${_formatCompactDecimal(amount / 1000000)} jt';
  }
  if (amount >= 1000) {
    return '$symbol ${(amount / 1000).round()} rb';
  }
  return formatCurrency(amount, currency);
}

String _formatCompactDecimal(num value) {
  final fixed = value.toStringAsFixed(1);
  final trimmed = fixed.endsWith('.0')
      ? fixed.substring(0, fixed.length - 2)
      : fixed;
  return trimmed.replaceAll('.', ',');
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
        'No categorized expenses for the selected period.',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categories[index].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
                const SizedBox(height: FlowSpacing.gapTight),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _ResponsiveCurrencyText(
                    amount: categories[index].amount,
                    currency: currency,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
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
        labels: const ['Harian', 'Pekanan', 'Bulanan'],
        selectedIndex: period.index,
        onChanged: (index) => onPeriodChanged(StatisticsPeriod.values[index]),
      ),
      const SizedBox(height: FlowSpacing.sm),
      FlowCard(
        variant: FlowCardVariant.action,
        density: FlowCardDensity.compact,
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: 'Previous period',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: period == StatisticsPeriod.daily
                  ? TextButton.icon(
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(_periodTitle(period, date)),
                    )
                  : Text(
                      _periodTitle(period, date),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    StatisticsPeriod.daily =>
      '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}',
    StatisticsPeriod.weekly =>
      '${_shortDate(DateTime(date.year, date.month, date.day - 6))} - ${_shortDate(date)} ${date.year}',
    StatisticsPeriod.monthly =>
      '${_monthName(DateTime(date.year, date.month - 11).month).substring(0, 3)} ${DateTime(date.year, date.month - 11).year} - ${_monthName(date.month).substring(0, 3)} ${date.year}',
  };

  static String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

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
    density: FlowCardDensity.compact,
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
      _ResponsiveCurrencyText(
        amount: value,
        currency: currency,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: color, fontSize: 16),
      ),
    ],
  );
}

class _ResponsiveCurrencyText extends StatelessWidget {
  const _ResponsiveCurrencyText({
    required this.amount,
    required this.currency,
    this.style,
  });

  final int amount;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        formatCurrency(amount, currency),
        maxLines: 1,
        softWrap: false,
        style: effectiveStyle,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

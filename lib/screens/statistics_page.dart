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
            child: Text(
              'Category chart will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: FlowSpacing.md),
          const _SectionHeading(title: 'Weekly spending trend'),
          const SizedBox(height: FlowSpacing.sm),
          FlowCard(
            variant: FlowCardVariant.chart,
            child: Text(
              'Weekly trend will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
  const StatisticsData({required this.income, required this.expense});

  final int income;
  final int expense;

  bool get hasData => income > 0 || expense > 0;

  factory StatisticsData.fromTransactions(
    List<Transaction> transactions,
    DateTime month,
  ) {
    var income = 0;
    var expense = 0;
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
        case TransactionType.transfer:
          break;
      }
    }
    return StatisticsData(income: income, expense: expense);
  }
}

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

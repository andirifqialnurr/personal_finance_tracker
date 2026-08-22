import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.accounts,
    this.transactions = const [],
    this.categories = const [],
    this.recurringTemplates = const [],
    this.monthlyBudgets = const [],
    this.savingsGoals = const [],
    this.currency = 'IDR',
    this.hideBalance = false,
    this.onHideBalanceChanged,
    required this.onAddTransaction,
    required this.onOpenRecurringTemplates,
    required this.onOpenMonthlyBudgets,
    required this.onOpenSavingsGoals,
    required this.onOpenReports,
  });
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<RecurringTemplate> recurringTemplates;
  final List<MonthlyBudget> monthlyBudgets;
  final List<SavingsGoal> savingsGoals;
  final String currency;
  final bool hideBalance;
  final ValueChanged<bool>? onHideBalanceChanged;
  final VoidCallback onAddTransaction;
  final VoidCallback onOpenRecurringTemplates;
  final VoidCallback onOpenMonthlyBudgets;
  final VoidCallback onOpenSavingsGoals;
  final VoidCallback onOpenReports;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };
    final activeAccounts = widget.accounts.where(
      (account) => !account.isArchived,
    );
    final totalBalance = activeAccounts.fold<int>(
      0,
      (sum, account) => sum + _balanceFor(account),
    );
    final monthTransactions = widget.transactions.where(
      (transaction) =>
          transaction.occurredAt.year == now.year &&
          transaction.occurredAt.month == now.month,
    );
    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: FlowSpacing.xxs),
                  Text(
                    'Your Flow',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: FlowSpacing.sm),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_monthName(now.month)} ${now.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: FlowSpacing.gapSection),
        FlowCard(
          variant: FlowCardVariant.balance,
          density: FlowCardDensity.featured,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total balance',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  IconButton(
                    onPressed: () {
                      final next = !widget.hideBalance;
                      widget.onHideBalanceChanged?.call(next);
                    },
                    tooltip: widget.hideBalance
                        ? 'Show balance'
                        : 'Hide balance',
                    icon: Icon(
                      widget.hideBalance
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FlowSpacing.gapGroup),
              FlowAmountText(
                amount: widget.hideBalance
                    ? formatMaskedCurrency(totalBalance, widget.currency)
                    : formatCurrency(totalBalance, widget.currency),
              ),
              const SizedBox(height: FlowSpacing.gapTight),
              Text(
                'Across ${activeAccounts.length} active account${activeAccounts.length == 1 ? '' : 's'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: FlowSpacing.gapSection),

        _QuickMenuGrid(
          items: [
            _QuickMenuItem(
              title: 'Recurring',
              icon: Icons.event_repeat_outlined,
              onTap: widget.onOpenRecurringTemplates,
            ),
            _QuickMenuItem(
              title: 'Budgets',
              icon: Icons.pie_chart_outline,
              onTap: widget.onOpenMonthlyBudgets,
            ),
            _QuickMenuItem(
              title: 'Goals',
              icon: Icons.savings_outlined,
              onTap: widget.onOpenSavingsGoals,
            ),
            _QuickMenuItem(
              title: 'Reports',
              icon: Icons.summarize_outlined,
              onTap: widget.onOpenReports,
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.gapSection),
        _CashFlowCard(
          transactions: monthTransactions.toList(growable: false),
          currency: widget.currency,
        ),
        if (widget.monthlyBudgets.isNotEmpty) ...[
          const SizedBox(height: FlowSpacing.gapSection),
          _HomeBudgetCard(
            budgets: widget.monthlyBudgets,
            transactions: widget.transactions,
            categories: widget.categories,
            currency: widget.currency,
          ),
        ],
        if (widget.recurringTemplates
            .where((template) => !template.isArchived)
            .isNotEmpty) ...[
          const SizedBox(height: FlowSpacing.gapSection),
          _RecurringReminderCard(templates: widget.recurringTemplates),
        ],
        const SizedBox(height: FlowSpacing.gapSection),
        _RecentTransactionsCard(
          transactions: widget.transactions,
          accounts: widget.accounts,
          categories: widget.categories,
          currency: widget.currency,
          onAddTransaction: widget.onAddTransaction,
        ),
      ],
    );
  }

  static String _monthName(int month) => const [
    '',
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
  ][month];
  int _balanceFor(Account account) {
    return account.openingBalance +
        widget.transactions.fold<int>(0, (sum, transaction) {
          if (transaction.type == TransactionType.transfer &&
              transaction.destinationAccountId == account.id) {
            return sum + transaction.amount;
          }
          if (transaction.accountId != account.id) {
            return sum;
          }
          return switch (transaction.type) {
            TransactionType.income => sum + transaction.amount,
            TransactionType.expense => sum - transaction.amount,
            TransactionType.transfer => sum - transaction.amount,
          };
        });
  }
}

class _HomeBudgetCard extends StatelessWidget {
  const _HomeBudgetCard({
    required this.budgets,
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  final List<MonthlyBudget> budgets;
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentBudgets = budgets
        .where(
          (budget) => budget.month.year == now.year && budget.month.month == now.month,
        )
        .toList();
    if (currentBudgets.isEmpty) return const SizedBox.shrink();
    final budget = currentBudgets.first;
    final spent = transactions.where((transaction) {
      return transaction.type == TransactionType.expense &&
          transaction.categoryId == budget.categoryId &&
          transaction.occurredAt.year == now.year &&
          transaction.occurredAt.month == now.month;
    }).fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final matchingCategory = categories.where(
      (category) => category.id == budget.categoryId,
    );
    final categoryName = matchingCategory.isEmpty
        ? 'Budget'
        : matchingCategory.first.name;
    return FlowCard(
      density: FlowCardDensity.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget progress', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.gapGroup),
          Text(categoryName, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FlowSpacing.gapGroup),
          FlowProgressBar(
            value: budget.amount == 0 ? 0 : spent / budget.amount,
            color: FlowColors.income,
          ),
          const SizedBox(height: FlowSpacing.gapGroup),
          Text(
            '${formatCurrency(spent, currency)} of ${formatCurrency(budget.amount, currency)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecurringReminderCard extends StatelessWidget {
  const _RecurringReminderCard({required this.templates});

  final List<RecurringTemplate> templates;

  @override
  Widget build(BuildContext context) {
    final active = templates.where((template) => !template.isArchived).length;
    return FlowCard(
      density: FlowCardDensity.compact,
      child: Row(
        children: [
          const FlowIconContainer(icon: Icons.event_repeat_outlined),
          const SizedBox(width: FlowSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recurring reminders', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: FlowSpacing.xxs),
                Text(
                  '$active template${active == 1 ? '' : 's'} ready to review.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMenuGrid extends StatelessWidget {
  const _QuickMenuGrid({required this.items});

  final List<_QuickMenuItem> items;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 4,
    childAspectRatio: 1,
    crossAxisSpacing: FlowSpacing.lg,
    mainAxisSpacing: FlowSpacing.lg,
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    children: [
      for (final item in items) _QuickMenuCard(item: item),
    ],
  );
}

class _QuickMenuItem {
  const _QuickMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickMenuCard extends StatelessWidget {
  const _QuickMenuCard({required this.item});

  final _QuickMenuItem item;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: item.onTap,
    borderRadius: BorderRadius.circular(FlowRadii.input),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(FlowRadii.input),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(FlowSpacing.xxs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 2),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.transactions, required this.currency});

  final List<Transaction> transactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final incomeByWeek = List<int>.filled(5, 0);
    final expenseByWeek = List<int>.filled(5, 0);
    for (final transaction in transactions) {
      final week = ((transaction.occurredAt.day - 1) ~/ 7).clamp(0, 4);
      switch (transaction.type) {
        case TransactionType.income:
          incomeByWeek[week] += transaction.amount;
        case TransactionType.expense:
          expenseByWeek[week] += transaction.amount;
        case TransactionType.transfer:
          break;
      }
    }
    return FlowCard(
      variant: FlowCardVariant.chart,
      density: FlowCardDensity.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cash flow', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.gapGroup),
          Text(
            'Income and expense by week',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: FlowSpacing.gapBlock),
          _CashFlowMiniChart(
            incomeByWeek: incomeByWeek,
            expenseByWeek: expenseByWeek,
            currency: currency,
          ),
        ],
      ),
    );
  }
}

class _CashFlowMiniChart extends StatelessWidget {
  const _CashFlowMiniChart({
    required this.incomeByWeek,
    required this.expenseByWeek,
    required this.currency,
  });

  final List<int> incomeByWeek;
  final List<int> expenseByWeek;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        SizedBox(
          height: 132,
          width: double.infinity,
          child: CustomPaint(
            painter: _CashFlowChartPainter(
              incomeByWeek: incomeByWeek,
              expenseByWeek: expenseByWeek,
              currency: currency,
              incomeColor: FlowColors.income,
              expenseColor: FlowColors.expense,
              labelColor: labelColor,
              gridColor: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: FlowSpacing.gapGroup),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CashFlowLegendItem(
              label: 'Income',
              color: FlowColors.income,
              textColor: labelColor,
            ),
            const SizedBox(width: FlowSpacing.md),
            _CashFlowLegendItem(
              label: 'Expense',
              color: FlowColors.expense,
              textColor: labelColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _CashFlowLegendItem extends StatelessWidget {
  const _CashFlowLegendItem({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: FlowSpacing.xs),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    ],
  );
}

class _CashFlowChartPainter extends CustomPainter {
  const _CashFlowChartPainter({
    required this.incomeByWeek,
    required this.expenseByWeek,
    required this.currency,
    required this.incomeColor,
    required this.expenseColor,
    required this.labelColor,
    required this.gridColor,
  });

  final List<int> incomeByWeek;
  final List<int> expenseByWeek;
  final String currency;
  final Color incomeColor;
  final Color expenseColor;
  final Color labelColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(
      1,
      [
        ...incomeByWeek,
        ...expenseByWeek,
      ].fold<int>(0, (current, value) => math.max(current, value)),
    );
    final left = 44.0;
    final right = 4.0;
    final top = 8.0;
    final bottom = 22.0;
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
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
      _drawText(
        canvas,
        _axisLabel((maxValue * ratio).round()),
        Offset(0, y - 6),
        maxWidth: left - 6,
        color: labelColor,
        align: TextAlign.right,
      );
    }

    final groupWidth = chartRect.width / 5;
    final barWidth = math.min(12.0, groupWidth * 0.22);
    for (var index = 0; index < 5; index++) {
      final centerX = chartRect.left + groupWidth * (index + 0.5);
      _drawBar(
        canvas,
        centerX - barWidth - 2,
        chartRect,
        barWidth,
        incomeByWeek[index],
        maxValue,
        incomeColor,
      );
      _drawBar(
        canvas,
        centerX + 2,
        chartRect,
        barWidth,
        expenseByWeek[index],
        maxValue,
        expenseColor,
      );
      _drawText(
        canvas,
        'W${index + 1}',
        Offset(centerX - groupWidth / 2, chartRect.bottom + 6),
        maxWidth: groupWidth,
        color: labelColor,
        align: TextAlign.center,
      );
    }
  }

  void _drawBar(
    Canvas canvas,
    double x,
    Rect chartRect,
    double width,
    int value,
    int maxValue,
    Color color,
  ) {
    final height = value == 0
        ? 2.0
        : math.max(3.0, chartRect.height * (value / maxValue));
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, chartRect.bottom - height, width, height),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = color);
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

  String _axisLabel(int amount) {
    final symbol = currencySymbol(currency);
    if (amount >= 1000000) {
      return '$symbol ${(amount / 1000000).toStringAsFixed(1)} jt';
    }
    if (amount >= 1000) return '$symbol ${(amount / 1000).round()} rb';
    return '$symbol $amount';
  }

  @override
  bool shouldRepaint(covariant _CashFlowChartPainter oldDelegate) {
    return oldDelegate.incomeByWeek != incomeByWeek ||
        oldDelegate.expenseByWeek != expenseByWeek ||
        oldDelegate.currency != currency ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.transactions,
    required this.accounts,
    required this.categories,
    required this.currency,
    required this.onAddTransaction,
  });
  final List<Transaction> transactions;
  final List<Account> accounts;
  final List<Category> categories;
  final String currency;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };
    final recent = transactions.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final visible = recent.take(5).toList(growable: false);
    return FlowCard(
      variant: FlowCardVariant.transaction,
      density: FlowCardDensity.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent transactions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (recent.isNotEmpty)
                Text(
                  '${visible.length} of 5',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: FlowSpacing.gapGroup),
          if (visible.isEmpty)
            FlowEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Add your first income or expense to see it here.',
              action: FlowButton(
                label: 'Add transaction',
                onPressed: onAddTransaction,
              ),
            )
          else
            for (final transaction in visible)
              FlowTransactionTile(
                title: _title(transaction.type),
                subtitle: [
                  accountNames[transaction.accountId] ??
                      'Account ${transaction.accountId}',
                  if (transaction.categoryId != null)
                    categoryNames[transaction.categoryId] ??
                        'Category ${transaction.categoryId}',
                  if (transaction.note?.isNotEmpty == true) transaction.note!,
                ].join(' · '),
                amount:
                    '${transaction.type == TransactionType.expense ? '-' : '+'} ${formatCurrency(transaction.amount, currency)}',
                icon: _icon(transaction.type),
                amountVariant: _amountVariant(transaction.type),
              ),
        ],
      ),
    );
  }

  static String _title(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
  static IconData _icon(TransactionType type) => switch (type) {
    TransactionType.income => Icons.arrow_downward,
    TransactionType.expense => Icons.arrow_upward,
    TransactionType.transfer => Icons.swap_horiz,
  };
  static FlowAmountVariant _amountVariant(TransactionType type) =>
      switch (type) {
        TransactionType.income => FlowAmountVariant.income,
        TransactionType.expense => FlowAmountVariant.expense,
        TransactionType.transfer => FlowAmountVariant.transfer,
      };
}

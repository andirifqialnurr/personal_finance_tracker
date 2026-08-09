import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.accounts,
    this.transactions = const [],
    this.categories = const [],
    this.currency = 'IDR',
    this.hideBalance = false,
    this.onHideBalanceChanged,
    required this.onAddTransaction,
  });
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;
  final bool hideBalance;
  final ValueChanged<bool>? onHideBalanceChanged;
  final VoidCallback onAddTransaction;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late bool _hideBalance = widget.hideBalance;

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
    final income = monthTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expense = monthTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.lg),
      children: [
        Text(greeting, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: FlowSpacing.xxs),
        Text('Your Flow', style: Theme.of(context).textTheme.headlineSmall),
        Text(
          '${_monthName(now.month)} ${now.year}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: FlowSpacing.lg),
        FlowCard(
          variant: FlowCardVariant.balance,
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
                      final next = !_hideBalance;
                      setState(() => _hideBalance = next);
                      widget.onHideBalanceChanged?.call(next);
                    },
                    tooltip: _hideBalance ? 'Show balance' : 'Hide balance',
                    icon: Icon(
                      _hideBalance
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ],
              ),
              FlowAmountText(
                amount: _hideBalance
                    ? '••••••'
                    : formatCurrency(totalBalance, widget.currency),
              ),
            ],
          ),
        ),
        const SizedBox(height: FlowSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                amount: formatCurrency(income, widget.currency),
                variant: FlowAmountVariant.income,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: FlowSpacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Expense',
                amount: formatCurrency(expense, widget.currency),
                variant: FlowAmountVariant.expense,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.md),
        FlowButton(
          label: 'Add transaction',
          icon: Icons.add,
          onPressed: widget.onAddTransaction,
        ),
        const SizedBox(height: FlowSpacing.lg),
        _CashFlowCard(
          transactions: monthTransactions.toList(growable: false),
          currency: widget.currency,
        ),
        const SizedBox(height: FlowSpacing.md),
        _SpendingByCategoryCard(
          transactions: monthTransactions.toList(growable: false),
          categories: widget.categories,
          currency: widget.currency,
        ),
        const SizedBox(height: FlowSpacing.lg),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.variant,
    required this.icon,
  });
  final String label;
  final String amount;
  final FlowAmountVariant variant;
  final IconData icon;

  @override
  Widget build(BuildContext context) => FlowCard(
    variant: FlowCardVariant.summary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowIconContainer(
          icon: icon,
          variant: variant == FlowAmountVariant.income
              ? FlowIconContainerVariant.income
              : FlowIconContainerVariant.expense,
        ),
        const SizedBox(height: FlowSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: FlowSpacing.xxs),
        FlowAmountText(
          amount: amount,
          variant: variant,
          style: const TextStyle(fontSize: 16),
        ),
      ],
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
    final maxAmount = List<int>.generate(
      incomeByWeek.length,
      (index) => incomeByWeek[index] + expenseByWeek[index],
    ).fold<int>(0, (max, value) => value > max ? value : max);
    final income = incomeByWeek.fold<int>(0, (sum, value) => sum + value);
    final expense = expenseByWeek.fold<int>(0, (sum, value) => sum + value);
    return FlowCard(
      variant: FlowCardVariant.chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cash flow', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.xs),
          Text(
            'Income and expense by week',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: FlowSpacing.md),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 5; index++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: maxAmount == 0
                              ? 8
                              : 72 *
                                  ((incomeByWeek[index] + expenseByWeek[index]) /
                                      maxAmount),
                          width: 28,
                          decoration: BoxDecoration(
                            color: incomeByWeek[index] >= expenseByWeek[index]
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(FlowRadii.pill),
                          ),
                        ),
                        const SizedBox(height: FlowSpacing.xs),
                        Text(
                          'W${index + 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: FlowSpacing.xs),
          Wrap(
            spacing: FlowSpacing.md,
            runSpacing: FlowSpacing.xs,
            children: [
              Text(
                'Income ${formatCurrency(income, currency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Expense ${formatCurrency(expense, currency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendingByCategoryCard extends StatelessWidget {
  const _SpendingByCategoryCard({
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };
    final totals = <int?, int>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) continue;
      totals.update(
        transaction.categoryId,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, entry) => sum + entry.value);
    final visible = sorted.take(4).toList();
    final others = sorted.skip(4).fold<int>(0, (sum, entry) => sum + entry.value);
    if (others > 0) visible.add(const MapEntry(null, 0));
    if (others > 0) visible[visible.length - 1] = MapEntry(null, others);

    return FlowCard(
      variant: FlowCardVariant.chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FlowSpacing.xs),
          Text(
            'Top 4 categories plus Others',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: FlowSpacing.md),
          if (visible.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: FlowIconSize.pageEmptyState,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: FlowSpacing.md),
                Expanded(
                  child: Text(
                    'No spending data yet. Add an expense to see category insights.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          else
            for (final entry in visible) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key == null
                          ? (entry.value == others ? 'Others' : 'Uncategorized')
                          : categoryNames[entry.key] ?? 'Category ${entry.key}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: FlowSpacing.sm),
                  Text(
                    formatCurrency(entry.value, currency),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: FlowSpacing.xs),
              LinearProgressIndicator(
                value: total == 0 ? 0 : entry.value / total,
                minHeight: 6,
                borderRadius: BorderRadius.circular(FlowRadii.pill),
              ),
              if (entry != visible.last)
                const SizedBox(height: FlowSpacing.sm),
            ],
        ],
      ),
    );
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
          const SizedBox(height: FlowSpacing.xs),
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

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
        const SizedBox(height: FlowSpacing.gapSection),
        _CashFlowCard(
          transactions: monthTransactions.toList(growable: false),
          currency: widget.currency,
        ),
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
        Row(
          children: [
            FlowIconContainer(
              icon: icon,
              variant: variant == FlowAmountVariant.income
                  ? FlowIconContainerVariant.income
                  : FlowIconContainerVariant.expense,
            ),
            const SizedBox(width: FlowSpacing.xs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.gapGroup),
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
          FlowApexChart(
            height: 132,
            options: _cashFlowOptions(context, incomeByWeek, expenseByWeek),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _cashFlowOptions(
    BuildContext context,
    List<int> incomeByWeek,
    List<int> expenseByWeek,
  ) {
    final symbol = currencySymbol(currency);
    return {
      'chart': {
        'type': 'bar',
        'fontFamily': 'Montserrat',
        'toolbar': {'show': false},
        'animations': {'enabled': true, 'speed': 360},
      },
      'series': [
        {'name': 'Income', 'data': incomeByWeek},
        {'name': 'Expense', 'data': expenseByWeek},
      ],
      'colors': [
        flowChartColorHex(Theme.of(context).colorScheme.primary),
        flowChartColorHex(Theme.of(context).colorScheme.error),
      ],
      'xaxis': {
        'categories': const ['W1', 'W2', 'W3', 'W4', 'W5'],
        'tickAmount': 5,
      },
      'yaxis': {
        'labels': {'prefix': '$symbol ', 'decimals': 0},
      },
      'plotOptions': {
        'bar': {'columnWidth': '52%', 'borderRadius': 8},
      },
      'dataLabels': {'enabled': false},
      'legend': {'show': true, 'position': 'bottom'},
      'tooltip': {
        'y': {'prefix': '$symbol ', 'decimals': 0},
      },
    };
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

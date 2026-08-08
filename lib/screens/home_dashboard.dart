import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key, required this.accounts});
  final List<Account> accounts;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };
    final totalBalance = widget.accounts
        .where((account) => !account.isArchived)
        .fold<int>(0, (sum, account) => sum + account.openingBalance);
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
                    onPressed: () =>
                        setState(() => _hideBalance = !_hideBalance),
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
                amount: _hideBalance ? '••••••' : 'Rp ${_format(totalBalance)}',
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
                amount: 'Rp 0',
                variant: FlowAmountVariant.income,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: FlowSpacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Expense',
                amount: 'Rp 0',
                variant: FlowAmountVariant.expense,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
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
  static String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'(?<!^)(?=(\d{3})+$)'),
    (_) => '.',
  );
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

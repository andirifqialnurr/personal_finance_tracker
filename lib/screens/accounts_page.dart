import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    required this.accounts,
    required this.onAdd,
    required this.onEdit,
  });

  final List<Account> accounts;
  final VoidCallback onAdd;
  final ValueChanged<Account> onEdit;

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold<int>(
      0,
      (sum, account) => sum + account.openingBalance,
    );
    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.lg),
      children: [
        FlowCard(
          variant: FlowCardVariant.balance,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total balance',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: FlowSpacing.xs),
              FlowAmountText(amount: 'Rp ${_format(total)}'),
            ],
          ),
        ),
        const SizedBox(height: FlowSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              onPressed: onAdd,
              tooltip: 'Add account',
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.xs),
        for (final account in accounts) ...[
          FlowCard(
            variant: FlowCardVariant.action,
            child: InkWell(
              onTap: () => onEdit(account),
              borderRadius: BorderRadius.circular(FlowRadii.card),
              child: Row(
                children: [
                  FlowIconContainer(
                    icon: _iconFor(account.type),
                    variant: FlowIconContainerVariant.account,
                  ),
                  const SizedBox(width: FlowSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _typeLabel(account.type),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FlowAmountText(
                    amount: 'Rp ${_format(account.openingBalance)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FlowSpacing.sm),
        ],
      ],
    );
  }

  static String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'(?<!^)(?=(\d{3})+$)'),
    (_) => '.',
  );
  static String _typeLabel(AccountType type) => switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.eWallet => 'E-wallet',
    AccountType.other => 'Other',
  };
  static IconData _iconFor(AccountType type) => switch (type) {
    AccountType.cash => Icons.wallet_outlined,
    AccountType.bank => Icons.account_balance_outlined,
    AccountType.eWallet => Icons.phone_android_outlined,
    AccountType.other => Icons.savings_outlined,
  };
}

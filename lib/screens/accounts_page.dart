import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({
    super.key,
    required this.accounts,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.transactions,
    required this.onOpenDetail,
    this.currency = 'IDR',
    this.filterType,
    this.onClearFilter,
  });

  final List<Account> accounts;
  final VoidCallback onAdd;
  final ValueChanged<Account> onEdit;
  final ValueChanged<Account> onArchive;
  final ValueChanged<Account> onRestore;
  final List<Transaction> transactions;
  final ValueChanged<Account> onOpenDetail;
  final String currency;
  final AccountType? filterType;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    final allActiveAccounts = accounts
        .where((account) => !account.isArchived)
        .toList(growable: false);
    final activeAccounts = allActiveAccounts
        .where(_matchesFilter)
        .toList(growable: false);
    final archivedAccounts = accounts
        .where((account) => account.isArchived)
        .where(_matchesFilter)
        .toList(growable: false);
    final totalBalance = activeAccounts.fold<int>(
      0,
      (sum, account) => sum + _balanceFor(account),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.md,
        FlowSpacing.sm,
        FlowSpacing.md,
        FlowSpacing.md,
      ),
      children: [
        if (filterType != null) ...[
          _AccountFilterSummary(
            label: _typeLabel(filterType!),
            onClear: onClearFilter ?? () {},
          ),
          const SizedBox(height: FlowSpacing.sm),
        ],
        if (allActiveAccounts.isEmpty)
          FlowEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No accounts yet',
            message: 'Create an account to start tracking your balance.',
            action: FlowButton(label: 'Create account', onPressed: onAdd),
          )
        else if (activeAccounts.isEmpty)
          const _InlineAccountEmpty(
            message: 'No active accounts match this filter.',
          )
        else ...[
          FlowCard(
            variant: FlowCardVariant.balance,
            density: FlowCardDensity.standard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total balance',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: FlowSpacing.gapGroup),
                FlowAmountText(
                  amount: formatCurrency(totalBalance, currency),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: FlowSpacing.gapTight),
                Text(
                  '${activeAccounts.length} active account${activeAccounts.length == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: FlowSpacing.sm),
          for (final account in activeAccounts) ...[
            _AccountCard(
              account: account,
              balance: _balanceFor(account),
              currency: currency,
              onTap: () => onOpenDetail(account),
              trailing: IconButton(
                onPressed: () => _confirmArchive(context, account),
                tooltip: 'Archive account',
                icon: const Icon(Icons.archive_outlined),
              ),
            ),
            const SizedBox(height: FlowSpacing.sm),
          ],
        ],
        if (archivedAccounts.isNotEmpty) ...[
          const SizedBox(height: FlowSpacing.gapSection),
          Text('Archived accounts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.xs),
          for (final account in archivedAccounts) ...[
            _AccountCard(
              account: account,
              balance: _balanceFor(account),
              currency: currency,
              onTap: () => onOpenDetail(account),
              trailing: TextButton.icon(
                onPressed: () => onRestore(account),
                icon: const Icon(Icons.unarchive_outlined),
                label: const Text('Restore'),
              ),
            ),
            const SizedBox(height: FlowSpacing.sm),
          ],
        ],
      ],
    );
  }

  static Future<void> showTypeFilter({
    required BuildContext context,
    required AccountType? selectedType,
    required ValueChanged<AccountType?> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AccountTypeFilterSheet(
        selectedType: selectedType,
        onSelected: onSelected,
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context, Account account) async {
    final confirmed = await FlowConfirmationSheet.show(
      context: context,
      title: 'Archive ${account.name}?',
      message:
          'The account and its transaction history will stay safe but be hidden from active accounts.',
      confirmLabel: 'Archive account',
    );
    if (confirmed == true) onArchive(account);
  }

  bool _matchesFilter(Account account) =>
      filterType == null || account.type == filterType;

  int _balanceFor(Account account) =>
      account.openingBalance +
      transactions.fold<int>(0, (sum, transaction) {
        if (transaction.type == TransactionType.transfer &&
            transaction.destinationAccountId == account.id) {
          return sum + transaction.amount;
        }
        if (transaction.accountId != account.id) return sum;
        return switch (transaction.type) {
          TransactionType.income => sum + transaction.amount,
          TransactionType.expense => sum - transaction.amount,
          TransactionType.transfer => sum - transaction.amount,
        };
      });
  static String _typeLabel(AccountType type) => switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.eWallet => 'E-wallet',
    AccountType.savings => 'Savings',
    AccountType.other => 'Other',
  };
  static IconData _iconFor(AccountType type) => switch (type) {
    AccountType.cash => Icons.wallet_outlined,
    AccountType.bank => Icons.account_balance_outlined,
    AccountType.eWallet => Icons.phone_android_outlined,
    AccountType.savings => Icons.savings_outlined,
    AccountType.other => Icons.savings_outlined,
  };
}

class _AccountFilterSummary extends StatelessWidget {
  const _AccountFilterSummary({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Filter: $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      TextButton.icon(
        onPressed: onClear,
        icon: const Icon(Icons.close),
        label: const Text('Clear'),
      ),
    ],
  );
}

class _InlineAccountEmpty extends StatelessWidget {
  const _InlineAccountEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

class _AccountTypeFilterSheet extends StatelessWidget {
  const _AccountTypeFilterSheet({
    required this.selectedType,
    required this.onSelected,
  });

  final AccountType? selectedType;
  final ValueChanged<AccountType?> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(FlowSpacing.md),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Filter accounts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FlowSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.select_all),
            title: const Text('All accounts'),
            trailing: selectedType == null ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.of(context).pop();
              onSelected(null);
            },
          ),
          for (final type in AccountType.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(AccountsPage._iconFor(type)),
              title: Text(AccountsPage._typeLabel(type)),
              trailing: selectedType == type ? const Icon(Icons.check) : null,
              onTap: () {
                Navigator.of(context).pop();
                onSelected(type);
              },
            ),
        ],
      ),
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balance,
    required this.currency,
    required this.onTap,
    required this.trailing,
  });

  final Account account;
  final int balance;
  final String currency;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return FlowCard(
      variant: FlowCardVariant.action,
      density: FlowCardDensity.standard,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FlowRadii.card),
        child: Column(
          children: [
            Row(
              children: [
                FlowIconContainer(
                  icon: AccountsPage._iconFor(account.type),
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
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: FlowSpacing.xxs),
                      Text(
                        AccountsPage._typeLabel(account.type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
            const SizedBox(height: FlowSpacing.gapGroup),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current balance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: FlowSpacing.sm),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FlowAmountText(
                      amount: formatCurrency(balance, currency),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

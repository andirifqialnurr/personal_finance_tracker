import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_colors.dart';
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
    this.hideBalance = false,
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
  final bool hideBalance;
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
        FlowSpacing.xxs,
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
                  amount: hideBalance
                      ? formatMaskedCurrency(totalBalance, currency)
                      : formatCurrency(totalBalance, currency),
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
          SizedBox(
            height: 188,
            child: ListView.separated(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: activeAccounts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: FlowSpacing.sm),
              itemBuilder: (context, index) {
                final account = activeAccounts[index];
                return SizedBox(
                  width: _accountCardWidth(context),
                  child: _AccountCard(
                    account: account,
                    balance: _balanceFor(account),
                    currency: currency,
                    hideBalance: hideBalance,
                    onTap: () => onOpenDetail(account),
                    trailing: IconButton(
                      onPressed: () => _confirmArchive(context, account),
                      tooltip: 'Archive account',
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .16),
                      ),
                      icon: const Icon(Icons.archive_outlined),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: FlowSpacing.sm),
        ],
        if (archivedAccounts.isNotEmpty) ...[
          const SizedBox(height: FlowSpacing.gapSection),
          Text(
            'Archived accounts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FlowSpacing.xs),
          for (final account in archivedAccounts) ...[
            _AccountCard(
              account: account,
              balance: _balanceFor(account),
              currency: currency,
              hideBalance: hideBalance,
              onTap: () => onOpenDetail(account),
              trailing: IconButton(
                onPressed: () => onRestore(account),
                tooltip: 'Restore account',
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .16),
                ),
                icon: const Icon(Icons.unarchive_outlined),
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

  double _accountCardWidth(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    return (viewportWidth - FlowSpacing.lg).clamp(280.0, 340.0).toDouble();
  }

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
    required this.hideBalance,
    required this.onTap,
    required this.trailing,
  });

  final Account account;
  final int balance;
  final String currency;
  final bool hideBalance;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(account.type);
    return Card(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(FlowRadii.card),
          boxShadow: FlowShadows.card,
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 176,
            child: Stack(
              children: [
                const Positioned(
                  right: -40,
                  top: -46,
                  child: _CardOrnament(size: 128, alpha: .13),
                ),
                const Positioned(
                  right: 34,
                  bottom: -54,
                  child: _CardOrnament(size: 116, alpha: .08),
                ),
                Padding(
                  padding: const EdgeInsets.all(FlowSpacing.cardStandard),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: FlowSpacing.xs),
                          trailing,
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6C36A).withValues(
                                alpha: .9,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: FlowSpacing.sm),
                          Icon(
                            AccountsPage._iconFor(account.type),
                            color: Colors.white.withValues(alpha: .88),
                            size: 22,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Current balance',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: .72,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: FlowSpacing.xxs),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    hideBalance
                                        ? formatMaskedCurrency(balance, currency)
                                        : formatCurrency(balance, currency),
                                    maxLines: 1,
                                    softWrap: false,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: FlowSpacing.sm),
                          Text(
                            AccountsPage._typeLabel(account.type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: .78),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _gradientFor(AccountType type) => switch (type) {
    AccountType.cash => const [FlowColors.accent, Color(0xFF0B4F45)],
    AccountType.bank => const [FlowColors.chartBlue, Color(0xFF2F456F)],
    AccountType.eWallet => const [FlowColors.chartPurple, Color(0xFF58406F)],
    AccountType.savings => const [Color(0xFF2E9F75), Color(0xFF1E5C48)],
    AccountType.other => const [Color(0xFF6F7B78), Color(0xFF303B38)],
  };
}

class _CardOrnament extends StatelessWidget {
  const _CardOrnament({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: alpha)),
    ),
  );
}

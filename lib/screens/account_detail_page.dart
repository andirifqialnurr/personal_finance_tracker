import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../utils/flow_format.dart';
import '../theme/flow_tokens.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    super.key,
    required this.account,
    required this.transactions,
    required this.onEdit,
    required this.onOpenTransaction,
    this.currency = 'IDR',
  });

  final Account account;
  final List<Transaction> transactions;
  final VoidCallback onEdit;
  final ValueChanged<Transaction> onOpenTransaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final accountTransactions = transactions
        .where(
          (transaction) =>
              transaction.accountId == account.id ||
              transaction.destinationAccountId == account.id,
        )
        .toList(growable: false);
    final balance = _balance(accountTransactions);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit account',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        children: [
          FlowCard(
            variant: FlowCardVariant.balance,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current balance', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: FlowSpacing.xs),
                FlowAmountText(amount: formatCurrency(balance, currency)),
                const SizedBox(height: FlowSpacing.sm),
                Text(
                  '${accountTransactions.length} transaction${accountTransactions.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: FlowSpacing.lg),
          Text('Account transactions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: FlowSpacing.sm),
          if (accountTransactions.isEmpty)
            const FlowEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Transactions recorded for this account will appear here.',
            )
          else
            for (final transaction in accountTransactions) ...[
              FlowCard(
                variant: FlowCardVariant.transaction,
                child: InkWell(
                  onTap: () => onOpenTransaction(transaction),
                  borderRadius: BorderRadius.circular(FlowRadii.card),
                  child: Row(
                    children: [
                      FlowIconContainer(
                        icon: _icon(transaction.type),
                        variant: _iconVariant(transaction.type),
                      ),
                      const SizedBox(width: FlowSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_label(transaction), style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${transaction.occurredAt.day}/${transaction.occurredAt.month}/${transaction.occurredAt.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      FlowAmountText(
                        amount:
                            '${_isIncoming(transaction, account.id) ? '+' : '-'} ${formatCurrency(transaction.amount, currency)}',
                        variant: _amountVariant(transaction, account.id),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: FlowSpacing.sm),
            ],
        ],
      ),
    );
  }

  int _balance(List<Transaction> items) => account.openingBalance + items.fold<int>(
    0,
    (sum, transaction) => sum + _signedAmount(transaction, account.id),
  );

  static int _signedAmount(Transaction transaction, int? accountId) {
    if (transaction.type == TransactionType.transfer) {
      return transaction.destinationAccountId == accountId
          ? transaction.amount
          : -transaction.amount;
    }
    return transaction.type == TransactionType.income
        ? transaction.amount
        : -transaction.amount;
  }

  static bool _isIncoming(Transaction transaction, int? accountId) =>
      transaction.type == TransactionType.income ||
      (transaction.type == TransactionType.transfer && transaction.destinationAccountId == accountId);

  static String _label(Transaction transaction) => transaction.note?.isNotEmpty == true
      ? transaction.note!
      : switch (transaction.type) {
          TransactionType.income => 'Income',
          TransactionType.expense => 'Expense',
          TransactionType.transfer => 'Transfer',
        };

  static IconData _icon(TransactionType type) => switch (type) {
    TransactionType.income => Icons.arrow_downward,
    TransactionType.expense => Icons.arrow_upward,
    TransactionType.transfer => Icons.swap_horiz,
  };

  static FlowIconContainerVariant _iconVariant(TransactionType type) => switch (type) {
    TransactionType.income => FlowIconContainerVariant.income,
    TransactionType.expense => FlowIconContainerVariant.expense,
    TransactionType.transfer => FlowIconContainerVariant.transfer,
  };

  static FlowAmountVariant _amountVariant(Transaction transaction, int? accountId) =>
      _isIncoming(transaction, accountId)
          ? FlowAmountVariant.income
          : transaction.type == TransactionType.transfer
              ? FlowAmountVariant.transfer
              : FlowAmountVariant.expense;

}

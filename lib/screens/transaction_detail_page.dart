import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.accountName,
    required this.onEdit,
    required this.onDelete,
    this.destinationAccountName,
    this.categoryName,
    this.currency = 'IDR',
  });
  final Transaction transaction;
  final String accountName;
  final String? destinationAccountName;
  final String? categoryName;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = switch (transaction.type) {
      TransactionType.income => 'Income',
      TransactionType.expense => 'Expense',
      TransactionType.transfer => 'Transfer',
    };
    final variant = switch (transaction.type) {
      TransactionType.income => FlowAmountVariant.income,
      TransactionType.expense => FlowAmountVariant.expense,
      TransactionType.transfer => FlowAmountVariant.transfer,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction detail')),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        children: [
          FlowCard(
            variant: FlowCardVariant.balance,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: FlowSpacing.xs),
                FlowAmountText(
                  amount: formatCurrency(transaction.amount, currency),
                  variant: variant,
                ),
              ],
            ),
          ),
          const SizedBox(height: FlowSpacing.md),
          FlowSelector(
            label: 'Account',
            value: accountName,
            icon: Icons.wallet_outlined,
          ),
          if (destinationAccountName != null) ...[
            const SizedBox(height: FlowSpacing.md),
            FlowSelector(
              label: 'To account',
              value: destinationAccountName!,
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
          const SizedBox(height: FlowSpacing.md),
          FlowSelector(
            label: 'Date',
            value:
                '${transaction.occurredAt.day}/${transaction.occurredAt.month}/${transaction.occurredAt.year}',
            icon: Icons.calendar_today_outlined,
          ),
          if (transaction.categoryId != null) ...[
            const SizedBox(height: FlowSpacing.md),
            FlowSelector(
              label: 'Category',
              value: categoryName ?? 'Category ${transaction.categoryId}',
              icon: Icons.category_outlined,
            ),
          ],
          if (transaction.note?.isNotEmpty == true) ...[
            const SizedBox(height: FlowSpacing.md),
            Text('Note', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: FlowSpacing.xs),
            Text(
              transaction.note!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: FlowSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FlowButton(
                  label: 'Edit',
                  variant: FlowButtonVariant.secondary,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: FlowSpacing.sm),
              Expanded(
                child: FlowButton(
                  label: 'Delete',
                  variant: FlowButtonVariant.destructive,
                  onPressed: () => _confirmDelete(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await FlowConfirmationSheet.show(
      context: context,
      title: 'Delete transaction?',
      message: 'This transaction will be removed from your records.',
      confirmLabel: 'Delete transaction',
    );
    if (confirmed == true) onDelete();
  }
}

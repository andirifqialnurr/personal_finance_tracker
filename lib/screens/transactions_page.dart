import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.transactions,
    required this.accounts,
  });
  final List<Transaction> transactions;
  final List<Account> accounts;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountNames = {
      for (final account in widget.accounts) account.id: account.name,
    };
    final filtered =
        widget.transactions
            .where((transaction) => _matchesQuery(transaction))
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final grouped = <DateTime, List<Transaction>>{};
    for (final transaction in filtered) {
      final day = DateTime(
        transaction.occurredAt.year,
        transaction.occurredAt.month,
        transaction.occurredAt.day,
      );
      (grouped[day] ??= []).add(transaction);
    }
    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.lg),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search note or category',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
        const SizedBox(height: FlowSpacing.md),
        if (widget.transactions.isEmpty)
          const FlowEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            message: 'Your income and expenses will appear here.',
          )
        else if (filtered.isEmpty)
          const FlowEmptyState(
            icon: Icons.search_off_outlined,
            title: 'No matching transactions',
            message: 'Try another note or category search.',
          )
        else
          for (final entry in grouped.entries) ...[
            Text(
              _dateLabel(entry.key),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: FlowSpacing.xs),
            FlowCard(
              variant: FlowCardVariant.transaction,
              child: Column(
                children: [
                  for (final transaction in entry.value)
                    FlowTransactionTile(
                      title: _typeLabel(transaction.type),
                      subtitle: _subtitle(transaction, accountNames),
                      amount:
                          '${transaction.type == TransactionType.expense ? '-' : '+'} Rp ${_format(transaction.amount)}',
                      icon: _icon(transaction.type),
                      amountVariant: _amountVariant(transaction.type),
                    ),
                ],
              ),
            ),
            const SizedBox(height: FlowSpacing.md),
          ],
      ],
    );
  }

  bool _matchesQuery(Transaction transaction) {
    if (_query.isEmpty) return true;
    final category = transaction.categoryId == null
        ? ''
        : 'category ${transaction.categoryId}';
    return (transaction.note ?? '').toLowerCase().contains(_query) ||
        category.contains(_query);
  }

  static String _subtitle(
    Transaction transaction,
    Map<int?, String> accountNames,
  ) {
    final account =
        accountNames[transaction.accountId] ??
        'Account ${transaction.accountId}';
    final category = transaction.categoryId == null
        ? 'No category'
        : 'Category ${transaction.categoryId}';
    return [
      account,
      category,
      if (transaction.note?.isNotEmpty == true) transaction.note!,
    ].join(' • ');
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  static String _typeLabel(TransactionType type) => switch (type) {
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
  static String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'(?<!^)(?=(\d{3})+$)'),
    (_) => '.',
  );
}

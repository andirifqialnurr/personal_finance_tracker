import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../data/transaction_filter.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.transactions,
    required this.accounts,
    required this.onOpenDetail,
    this.categories = const [],
    this.currency = 'IDR',
  });
  final List<Transaction> transactions;
  final List<Account> accounts;
  final ValueChanged<Transaction> onOpenDetail;
  final List<Category> categories;
  final String currency;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  String _query = '';
  TransactionType? _typeFilter;
  int? _accountFilter;
  int? _categoryFilter;
  DateTimeRange? _dateRange;

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
    final categoryNames = {
      for (final category in widget.categories)
        if (category.id != null) category.id!: category.name,
    };
    final filtered = FlowTransactionFilter(
        query: _query,
        type: _typeFilter,
        accountId: _accountFilter,
        categoryId: _categoryFilter,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end.add(const Duration(days: 1)),
      )
        .apply(widget.transactions, categoryNames: categoryNames)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final incomeTotal = filtered
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expenseTotal = filtered
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
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
        Wrap(
          spacing: FlowSpacing.xs,
          runSpacing: FlowSpacing.xs,
          children: [
            FilterChip(
              label: Text(
                _typeFilter == null
                    ? 'Type: All'
                    : 'Type: ${_typeLabel(_typeFilter!)}',
              ),
              selected: _typeFilter != null,
              onSelected: (_) => _selectType(),
            ),
            FilterChip(
              label: Text(
                _accountFilter == null
                    ? 'Account: All'
                    : 'Account: ${_accountName(_accountFilter!, accountNames)}',
              ),
              selected: _accountFilter != null,
              onSelected: (_) => _selectAccount(accountNames),
            ),
            FilterChip(
              label: Text(
                _categoryFilter == null
                    ? 'Category: All'
                    : 'Category: $_categoryFilter',
              ),
              selected: _categoryFilter != null,
              onSelected: (_) => _selectCategory(),
            ),
            FilterChip(
              label: Text(
                _dateRange == null
                    ? 'Date: All'
                    : '${_dateLabel(_dateRange!.start)} - ${_dateLabel(_dateRange!.end)}',
              ),
              selected: _dateRange != null,
              onSelected: (_) => _selectDateRange(),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TotalCard(
                label: 'Income',
                amount: incomeTotal,
                variant: FlowAmountVariant.income,
                currency: widget.currency,
              ),
            ),
            const SizedBox(width: FlowSpacing.sm),
            Expanded(
              child: _TotalCard(
                label: 'Expense',
                amount: expenseTotal,
                variant: FlowAmountVariant.expense,
                currency: widget.currency,
              ),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.lg),
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
                      subtitle: _subtitle(
                        transaction,
                        accountNames,
                        categoryNames,
                      ),
                      amount:
                          '${transaction.type == TransactionType.expense ? '-' : '+'} ${formatCurrency(transaction.amount, widget.currency)}',
                      icon: _icon(transaction.type),
                      amountVariant: _amountVariant(transaction.type),
                      onTap: () => widget.onOpenDetail(transaction),
                    ),
                ],
              ),
            ),
            const SizedBox(height: FlowSpacing.md),
          ],
      ],
    );
  }

  Future<void> _selectType() async {
    final selected = await _showFilterSheet<String>('Filter type', [
      'All types',
      'Income',
      'Expense',
      'Transfer',
    ]);
    if (selected != null) {
      setState(
        () => _typeFilter = selected == 'All types'
            ? null
            : TransactionType.values.byName(selected.toLowerCase()),
      );
    }
  }

  Future<void> _selectAccount(Map<int?, String> names) async {
    final options = <int>[
      0,
      ...widget.accounts.map((account) => account.id ?? 0),
    ];
    final selected = await _showFilterSheet<int>(
      'Filter account',
      options,
      labelOf: (id) => id == 0 ? 'All accounts' : _accountName(id, names),
    );
    if (selected != null) {
      setState(() => _accountFilter = selected == 0 ? null : selected);
    }
  }

  Future<void> _selectCategory() async {
    final options = <int>[
      0,
      ...widget.transactions
          .map((transaction) => transaction.categoryId)
          .whereType<int>()
          .toSet(),
    ];
    final categoryNames = {
      for (final category in widget.categories)
        if (category.id != null) category.id!: category.name,
    };
    final selected = await _showFilterSheet<int>(
      'Filter category',
      options,
      labelOf: (id) => id == 0
          ? 'All categories'
          : categoryNames[id] ?? 'Category $id',
    );
    if (selected != null) {
      setState(() => _categoryFilter = selected == 0 ? null : selected);
    }
  }

  Future<void> _selectDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (selected != null) setState(() => _dateRange = selected);
  }

  Future<T?> _showFilterSheet<T>(
    String title,
    List<T> options, {
    String Function(T value)? labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(FlowSpacing.md),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf?.call(option) ?? '$option'),
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }

  static String _subtitle(
    Transaction transaction,
    Map<int?, String> accountNames,
    Map<int, String> categoryNames,
  ) {
    final account =
        accountNames[transaction.accountId] ??
        'Account ${transaction.accountId}';
    final category = transaction.categoryId == null
        ? 'No category'
        : categoryNames[transaction.categoryId] ??
              'Category ${transaction.categoryId}';
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
  static String _accountName(int id, Map<int?, String> names) =>
      names[id] ?? 'Account $id';
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.variant,
    required this.currency,
  });
  final String label;
  final int amount;
  final FlowAmountVariant variant;
  final String currency;

  @override
  Widget build(BuildContext context) => FlowCard(
    variant: FlowCardVariant.summary,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: FlowSpacing.xs),
        FlowAmountText(
          amount: formatCurrency(amount, currency),
          variant: variant,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    ),
  );
}

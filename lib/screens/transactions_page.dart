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
    final filtered =
        FlowTransactionFilter(
            query: _query,
            type: _typeFilter,
            accountId: _accountFilter,
            categoryId: _categoryFilter,
            startDate: _dateRange?.start,
            endDate: _dateRange?.end.add(const Duration(days: 1)),
          ).apply(widget.transactions, categoryNames: categoryNames)
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
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.md,
        FlowSpacing.xxs,
        FlowSpacing.md,
        FlowSpacing.md,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
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
            ),
            const SizedBox(width: FlowSpacing.xs),
            SizedBox(
              width: FlowControlSize.minTouchTarget,
              height: FlowControlSize.minTouchTarget,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    key: const Key('transaction-filter-button'),
                    onPressed: _openFilterModal,
                    tooltip: _activeFilterCount == 0
                        ? 'Open filters'
                        : 'Open filters ($_activeFilterCount active)',
                    icon: const Icon(Icons.tune_outlined),
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      key: const Key('transaction-filter-active-count'),
                      top: -2,
                      right: -2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(FlowSpacing.xxs),
                          child: Text(
                            '$_activeFilterCount',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_activeFilterCount > 0) ...[
          const SizedBox(height: FlowSpacing.xs),
          Text(
            '$_activeFilterCount filters active',
            key: const Key('transaction-filter-active-label'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: FlowSpacing.gapSection),
        Row(
          children: [
            Expanded(
              child: _TotalCard(
                label: 'Income',
                amount: incomeTotal,
                variant: FlowAmountVariant.income,
                icon: Icons.arrow_downward,
                currency: widget.currency,
              ),
            ),
            const SizedBox(width: FlowSpacing.sm),
            Expanded(
              child: _TotalCard(
                label: 'Expense',
                amount: expenseTotal,
                variant: FlowAmountVariant.expense,
                icon: Icons.arrow_upward,
                currency: widget.currency,
              ),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.gapSection),
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
              density: FlowCardDensity.standard,
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

  int get _activeFilterCount => [
    _typeFilter != null,
    _accountFilter != null,
    _categoryFilter != null,
    _dateRange != null,
  ].where((active) => active).length;

  Future<void> _openFilterModal() async {
    final selected = await showModalBottomSheet<_TransactionFilterValues>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _TransactionFilterSheet(
        accounts: widget.accounts,
        categories: widget.categories,
        transactions: widget.transactions,
        initialType: _typeFilter,
        initialAccountId: _accountFilter,
        initialCategoryId: _categoryFilter,
        initialDateRange: _dateRange,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _typeFilter = selected.type;
      _accountFilter = selected.accountId;
      _categoryFilter = selected.categoryId;
      _dateRange = selected.dateRange;
    });
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
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class _TransactionFilterValues {
  const _TransactionFilterValues({
    this.type,
    this.accountId,
    this.categoryId,
    this.dateRange,
  });

  final TransactionType? type;
  final int? accountId;
  final int? categoryId;
  final DateTimeRange? dateRange;
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.initialType,
    required this.initialAccountId,
    required this.initialCategoryId,
    required this.initialDateRange,
  });

  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final TransactionType? initialType;
  final int? initialAccountId;
  final int? initialCategoryId;
  final DateTimeRange? initialDateRange;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  late TransactionType? _type = widget.initialType;
  late int? _accountId = widget.initialAccountId;
  late int? _categoryId = widget.initialCategoryId;
  late DateTimeRange? _dateRange = widget.initialDateRange;

  @override
  Widget build(BuildContext context) {
    final categoryNames = {
      for (final category in widget.categories)
        if (category.id != null) category.id!: category.name,
    };
    final categoryIds =
        widget.transactions
            .map((transaction) => transaction.categoryId)
            .whereType<int>()
            .toSet()
          ..addAll(categoryNames.keys);
    final modalHeight = (MediaQuery.sizeOf(context).height * .82).clamp(
      320.0,
      620.0,
    );

    return SizedBox(
      height: modalHeight.toDouble(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FlowSpacing.md,
            FlowSpacing.xs,
            FlowSpacing.md,
            FlowSpacing.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter transactions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: FlowSpacing.xs),
              Expanded(
                child: ListView(
                  children: [
                    DropdownButtonFormField<TransactionType?>(
                      isExpanded: true,
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [
                        const DropdownMenuItem<TransactionType?>(
                          child: Text('All types'),
                        ),
                        for (final type in TransactionType.values)
                          DropdownMenuItem<TransactionType?>(
                            value: type,
                            child: Text(_typeLabel(type)),
                          ),
                      ],
                      onChanged: (value) => setState(() => _type = value),
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: _accountId,
                      decoration: const InputDecoration(labelText: 'Account'),
                      items: [
                        const DropdownMenuItem<int?>(
                          child: Text('All accounts'),
                        ),
                        for (final account in widget.accounts)
                          if (account.id != null)
                            DropdownMenuItem<int?>(
                              value: account.id,
                              child: Text(
                                account.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                      ],
                      onChanged: (value) => setState(() => _accountId = value),
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    DropdownButtonFormField<int?>(
                      isExpanded: true,
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem<int?>(
                          child: Text('All categories'),
                        ),
                        for (final id in categoryIds.toList()..sort())
                          DropdownMenuItem<int?>(
                            value: id,
                            child: Text(
                              categoryNames[id] ?? 'Category $id',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _categoryId = value),
                    ),
                    const SizedBox(height: FlowSpacing.md),
                    InkWell(
                      borderRadius: BorderRadius.circular(FlowRadii.input),
                      onTap: _pickDateRange,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _dateRange == null
                              ? 'All dates'
                              : '${_dateLabel(_dateRange!.start)} - ${_dateLabel(_dateRange!.end)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FlowSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _clearAll,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          FlowControlSize.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlowSpacing.sm,
                        ),
                      ),
                      child: const Text('Clear all'),
                    ),
                  ),
                  const SizedBox(width: FlowSpacing.xs),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(
                          0,
                          FlowControlSize.minTouchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlowSpacing.sm,
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (selected != null && mounted) setState(() => _dateRange = selected);
  }

  void _clearAll() {
    setState(() {
      _type = null;
      _accountId = null;
      _categoryId = null;
      _dateRange = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _TransactionFilterValues(
        type: _type,
        accountId: _accountId,
        categoryId: _categoryId,
        dateRange: _dateRange,
      ),
    );
  }

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.variant,
    required this.icon,
    required this.currency,
  });
  final String label;
  final int amount;
  final FlowAmountVariant variant;
  final IconData icon;
  final String currency;

  @override
  Widget build(BuildContext context) => FlowCard(
    variant: FlowCardVariant.summary,
    density: FlowCardDensity.compact,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: variant == FlowAmountVariant.income
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
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
          amount: formatCurrency(amount, currency),
          variant: variant,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, this.accounts = const []});

  final List<Account> accounts;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  int _selectedType = 0;
  final _amountController = TextEditingController();
  Account? _selectedAccount;
  Category? _selectedCategory;

  static const _categories = <Category>[
    Category(
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
    ),
    Category(
      name: 'Transport',
      transactionType: TransactionType.expense,
      icon: 'directions_car',
      color: '#C96B6B',
    ),
    Category(
      name: 'Salary',
      transactionType: TransactionType.income,
      icon: 'payments',
      color: '#168C78',
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add transaction'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        children: [
          FlowSegmentedControl(
            labels: const ['Expense', 'Income', 'Transfer'],
            selectedIndex: _selectedType,
            onChanged: (index) => setState(() => _selectedType = index),
          ),
          const SizedBox(height: FlowSpacing.lg),
          Text('Amount', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: FlowSpacing.xs),
          TextField(
            autofocus: true,
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.displaySmall,
            decoration: const InputDecoration(hintText: '0', prefixText: 'Rp '),
          ),
          const SizedBox(height: FlowSpacing.md),
          FlowSelector(
            label: 'Account',
            value: _selectedAccount?.name ?? 'Select account',
            icon: Icons.wallet_outlined,
            onTap: _selectAccount,
          ),
          if (_selectedType == 2) ...[
            const SizedBox(height: FlowSpacing.md),
            const FlowSelector(
              label: 'To account',
              value: 'Select destination',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ] else ...[
            const SizedBox(height: FlowSpacing.md),
            FlowSelector(
              label: 'Category',
              value: _selectedCategory?.name ?? 'Select category',
              icon: Icons.category_outlined,
              onTap: _selectCategory,
            ),
          ],
          const SizedBox(height: FlowSpacing.md),
          const TextField(
            decoration: InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: FlowSpacing.lg),
          FlowButton(label: 'Save transaction', onPressed: () {}),
        ],
      ),
    );
  }

  Future<void> _selectAccount() async {
    final selected = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SelectionSheet<Account>(
        title: 'Select account',
        items: widget.accounts,
        titleOf: (account) => account.name,
        subtitleOf: (account) => _accountTypeLabel(account.type),
        iconOf: (_) => Icons.account_balance_wallet_outlined,
      ),
    );
    if (selected != null) setState(() => _selectedAccount = selected);
  }

  Future<void> _selectCategory() async {
    final type = _selectedType == 1
        ? TransactionType.income
        : TransactionType.expense;
    final selected = await showModalBottomSheet<Category>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SelectionSheet<Category>(
        title: 'Select category',
        items: _categories
            .where((category) => category.transactionType == type)
            .toList(),
        titleOf: (category) => category.name,
        subtitleOf: (_) =>
            type == TransactionType.income ? 'Income' : 'Expense',
        iconOf: (_) => Icons.category_outlined,
      ),
    );
    if (selected != null) setState(() => _selectedCategory = selected);
  }

  static String _accountTypeLabel(AccountType type) => switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.eWallet => 'E-wallet',
    AccountType.other => 'Other',
  };
}

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.titleOf,
    required this.subtitleOf,
    required this.iconOf,
  });
  final String title;
  final List<T> items;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;
  final IconData Function(T item) iconOf;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.lg,
        FlowSpacing.sm,
        FlowSpacing.lg,
        FlowSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: FlowSpacing.sm),
          if (items.isEmpty)
            Text(
              'No options available yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: FlowIconContainer(icon: iconOf(item)),
                title: Text(titleOf(item)),
                subtitle: Text(subtitleOf(item)),
                onTap: () => Navigator.of(context).pop(item),
              ),
        ],
      ),
    ),
  );
}

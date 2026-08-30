import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/default_category_seeder.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_currency_input_formatter.dart';
import '../utils/flow_format.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    this.accounts = const [],
    this.categories = const [],
    this.currency = 'IDR',
    this.onSaved,
    this.initialTransaction,
  });

  final List<Account> accounts;
  final List<Category> categories;
  final String currency;
  final ValueChanged<Transaction>? onSaved;
  final Transaction? initialTransaction;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  int _selectedType = 0;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Account? _selectedAccount;
  Account? _destinationAccount;
  Category? _selectedCategory;
  DateTime _occurredAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    if (transaction == null) return;
    _selectedType = switch (transaction.type) {
      TransactionType.expense => 0,
      TransactionType.income => 1,
      TransactionType.transfer => 2,
    };
    _amountController.text = formatCurrencyInput(transaction.amount.toString());
    _selectedAccount = _findAccount(transaction.accountId);
    _destinationAccount = transaction.destinationAccountId == null
        ? null
        : _findAccount(transaction.destinationAccountId!);
    _selectedCategory = transaction.categoryId == null
        ? null
        : _findCategory(transaction.categoryId!);
    _noteController.text = transaction.note ?? '';
    _occurredAt = transaction.occurredAt;
  }

  Account? _findAccount(int id) {
    for (final account in widget.accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Category? _findCategory(int id) {
    for (final category in _availableCategories) {
      if (category.id == id) return category;
    }
    return null;
  }

  List<Category> get _availableCategories => widget.categories.isNotEmpty
      ? widget.categories
      : [
          for (
            var index = 0;
            index < DefaultCategorySeeder.defaults.length;
            index++
          )
            Category(
              id: index + 1,
              name: DefaultCategorySeeder.defaults[index].name,
              transactionType:
                  DefaultCategorySeeder.defaults[index].transactionType,
              icon: DefaultCategorySeeder.defaults[index].icon,
              color: DefaultCategorySeeder.defaults[index].color,
              isDefault: true,
            ),
        ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
            onChanged: (index) => setState(() {
              _selectedType = index;
              _selectedCategory = null;
              _destinationAccount = null;
            }),
          ),
          const SizedBox(height: FlowSpacing.lg),
          Text('Amount', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: FlowSpacing.xs),
          TextField(
            autofocus: true,
            controller: _amountController,
            inputFormatters: const [FlowCurrencyInputFormatter()],
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.displaySmall,
            decoration: InputDecoration(
              hintText: '0',
              prefixText: '${currencySymbol(widget.currency)} ',
            ),
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
            FlowSelector(
              label: 'To account',
              value: _destinationAccount?.name ?? 'Select destination',
              icon: Icons.account_balance_wallet_outlined,
              onTap: _selectDestinationAccount,
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
          FlowSelector(
            label: 'Date',
            value: _dateLabel(_occurredAt),
            icon: Icons.calendar_today_outlined,
            onTap: _selectDate,
          ),
          const SizedBox(height: FlowSpacing.md),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: FlowSpacing.lg),
          FlowButton(
            label: 'Save transaction',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectAccount() async {
    final selected = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
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
      isScrollControlled: true,
      builder: (context) => _SelectionSheet<Category>(
        title: 'Select category',
        items: _availableCategories
            .where(
              (category) =>
                  category.transactionType == type && !category.isArchived,
            )
            .toList(),
        titleOf: (category) => category.name,
        subtitleOf: (_) =>
            type == TransactionType.income ? 'Income' : 'Expense',
        iconOf: (_) => Icons.category_outlined,
      ),
    );
    if (selected != null) setState(() => _selectedCategory = selected);
  }

  Future<void> _selectDestinationAccount() async {
    final selected = await _showAccountSheet(title: 'Select destination');
    if (selected != null) setState(() => _destinationAccount = selected);
  }

  Future<Account?> _showAccountSheet({required String title}) {
    return showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _SelectionSheet<Account>(
        title: title,
        items: widget.accounts,
        titleOf: (account) => account.name,
        subtitleOf: (account) => _accountTypeLabel(account.type),
        iconOf: (_) => Icons.account_balance_wallet_outlined,
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _occurredAt,
    );
    if (selected != null) setState(() => _occurredAt = selected);
  }

  bool get _canSave {
    final amount = parseCurrencyInput(_amountController.text) ?? 0;
    final hasAccount = _selectedAccount != null;
    final hasTypeSpecificField = _selectedType == 2
        ? _destinationAccount != null && _destinationAccount != _selectedAccount
        : _selectedCategory != null;
    return amount > 0 && hasAccount && hasTypeSpecificField;
  }

  void _save() {
    final amount = parseCurrencyInput(_amountController.text)!;
    final now = DateTime.now().toUtc();
    widget.onSaved?.call(
      Transaction(
        id: widget.initialTransaction?.id,
        type: _selectedType == 0
            ? TransactionType.expense
            : _selectedType == 1
            ? TransactionType.income
            : TransactionType.transfer,
        amount: amount.abs(),
        accountId: _selectedAccount!.id!,
        destinationAccountId: _destinationAccount?.id,
        categoryId: _selectedCategory?.id,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        occurredAt: _occurredAt,
        createdAt: now,
        updatedAt: now,
      ),
    );
    Navigator.of(context).pop();
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  static String _accountTypeLabel(AccountType type) => switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.eWallet => 'E-wallet',
    AccountType.savings => 'Savings',
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
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: FlowSpacing.sm),
            if (items.isEmpty)
              Text(
                'No options available yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Flexible(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: FlowIconContainer(icon: iconOf(item)),
                        title: Text(
                          titleOf(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          subtitleOf(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

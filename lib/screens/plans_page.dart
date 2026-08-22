import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_currency_input_formatter.dart';
import '../utils/flow_format.dart';

enum PlansPageSection { all, recurringTemplates, monthlyBudgets, savingsGoals }

class PlansPage extends StatelessWidget {
  const PlansPage({
    super.key,
    this.section = PlansPageSection.all,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.recurringTemplates,
    required this.monthlyBudgets,
    required this.savingsGoals,
    required this.currency,
    required this.onSaveRecurringTemplate,
    required this.onDeleteRecurringTemplate,
    required this.onUseRecurringTemplate,
    required this.onSaveMonthlyBudget,
    required this.onDeleteMonthlyBudget,
    required this.onSaveSavingsGoal,
    required this.onDeleteSavingsGoal,
  });

  final PlansPageSection section;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<RecurringTemplate> recurringTemplates;
  final List<MonthlyBudget> monthlyBudgets;
  final List<SavingsGoal> savingsGoals;
  final String currency;
  final ValueChanged<RecurringTemplate> onSaveRecurringTemplate;
  final ValueChanged<int> onDeleteRecurringTemplate;
  final ValueChanged<RecurringTemplate> onUseRecurringTemplate;
  final ValueChanged<MonthlyBudget> onSaveMonthlyBudget;
  final ValueChanged<int> onDeleteMonthlyBudget;
  final ValueChanged<SavingsGoal> onSaveSavingsGoal;
  final ValueChanged<int> onDeleteSavingsGoal;

  @override
  Widget build(BuildContext context) {
    final showRecurring =
        section == PlansPageSection.all ||
        section == PlansPageSection.recurringTemplates;
    final showBudgets =
        section == PlansPageSection.all ||
        section == PlansPageSection.monthlyBudgets;
    final showGoals =
        section == PlansPageSection.all || section == PlansPageSection.savingsGoals;
    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.md),
      children: [
        const SizedBox(height: FlowSpacing.gapSection),
        if (showRecurring) ...[
          _SectionHeader(
            title: 'Recurring templates',
            icon: Icons.event_repeat_outlined,
            onAdd: () => _openRecurringForm(context),
          ),
          const SizedBox(height: FlowSpacing.sm),
          if (recurringTemplates.where((item) => !item.isArchived).isEmpty)
            const _InlineEmpty(
              message:
                  'No recurring templates yet. Create one for salary, bills, subscriptions, or routine transfers.',
            )
          else
            for (final template
                in recurringTemplates.where((item) => !item.isArchived)) ...[
              _RecurringCard(
                template: template,
                accountName: _accountName(template.accountId),
                categoryName: template.categoryId == null
                    ? null
                    : _categoryName(template.categoryId!),
                currency: currency,
                onOpenDetails: () => _openRecurringDetails(context, template),
                onUse: () => onUseRecurringTemplate(template),
                onDelete: template.id == null
                    ? null
                    : () => onDeleteRecurringTemplate(template.id!),
              ),
              const SizedBox(height: FlowSpacing.sm),
            ],
        ],
        if (showBudgets) ...[
          if (showRecurring) const SizedBox(height: FlowSpacing.gapSection),
          _SectionHeader(
            title: 'Monthly budgets',
            icon: Icons.pie_chart_outline,
            onAdd: () => _openBudgetForm(context),
          ),
          const SizedBox(height: FlowSpacing.sm),
          if (monthlyBudgets.isEmpty)
            const _InlineEmpty(
              message:
                  'No monthly budgets yet. Set optional limits for expense categories without changing balances.',
            )
          else
            for (final budget in monthlyBudgets) ...[
              _BudgetCard(
                budget: budget,
                categoryName: budget.categoryId == null
                    ? 'Uncategorized'
                    : _categoryName(budget.categoryId!),
                spent: _spentForBudget(budget),
                currency: currency,
                onOpenDetails: () => _openBudgetDetails(context, budget),
                onDelete: budget.id == null
                    ? null
                    : () => onDeleteMonthlyBudget(budget.id!),
              ),
              const SizedBox(height: FlowSpacing.sm),
            ],
        ],
        if (showGoals) ...[
          if (showRecurring || showBudgets)
            const SizedBox(height: FlowSpacing.gapSection),
          _SectionHeader(
            title: 'Savings goals',
            icon: Icons.savings_outlined,
            onAdd: () => _openGoalForm(context),
          ),
          const SizedBox(height: FlowSpacing.sm),
          if (savingsGoals.where((item) => !item.isArchived).isEmpty)
            const _InlineEmpty(
              message:
                  'No savings goals yet. Track a target manually or link it to an existing account.',
            )
          else
            for (final goal
                in savingsGoals.where((item) => !item.isArchived)) ...[
              _SavingsGoalCard(
                goal: goal,
                accountName: goal.accountId == null
                    ? null
                    : _accountName(goal.accountId!),
                linkedBalance: _linkedGoalBalance(goal),
                currentAmount: _currentGoalAmount(goal),
                currency: currency,
                onOpenDetails: () => _openGoalDetails(context, goal),
                onAddContribution: () => _openContributionForm(context, goal),
                onDelete: goal.id == null
                    ? null
                    : () => onDeleteSavingsGoal(goal.id!),
              ),
              const SizedBox(height: FlowSpacing.sm),
            ],
        ],
      ],
    );
  }
  String _accountName(int id) {
    return accounts
        .firstWhere(
          (account) => account.id == id,
          orElse: () => Account(
            id: id,
            name: 'Account $id',
            type: AccountType.other,
            openingBalance: 0,
            icon: 'account',
            color: '#168C78',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .name;
  }

  String _categoryName(int id) {
    return categories
        .firstWhere(
          (category) => category.id == id,
          orElse: () => Category(
            id: id,
            name: 'Category $id',
            transactionType: TransactionType.expense,
            icon: 'category',
            color: '#C96B6B',
          ),
        )
        .name;
  }

  int _spentForBudget(MonthlyBudget budget) {
    return _transactionsForBudget(budget).fold<int>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  List<Transaction> _transactionsForBudget(MonthlyBudget budget) {
    return transactions.where((transaction) {
      return transaction.type == TransactionType.expense &&
          transaction.categoryId == budget.categoryId &&
          transaction.occurredAt.year == budget.month.year &&
          transaction.occurredAt.month == budget.month.month;
    }).toList(growable: false);
  }

  int _currentGoalAmount(SavingsGoal goal) {
    return _linkedGoalBalance(goal) + goal.manualContribution;
  }

  int _linkedGoalBalance(SavingsGoal goal) {
    if (goal.accountId == null) return 0;
    return accounts
        .where((account) => account.id == goal.accountId)
        .fold<int>(0, (sum, account) => sum + _balanceFor(account));
  }

  int _balanceFor(Account account) {
    return account.openingBalance +
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
  }

  Future<void> _openRecurringForm(BuildContext context) async {
    final template = await showModalBottomSheet<RecurringTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecurringTemplateSheet(
        accounts: accounts.where((account) => !account.isArchived).toList(),
        categories: categories.where((category) => !category.isArchived).toList(),
      ),
    );
    if (template != null) onSaveRecurringTemplate(template);
  }

  Future<void> _openRecurringDetails(
    BuildContext context,
    RecurringTemplate template,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecurringDetailsSheet(
        template: template,
        accountName: _accountName(template.accountId),
        categoryName: template.categoryId == null
            ? null
            : _categoryName(template.categoryId!),
        currency: currency,
        onUse: () {
          Navigator.of(context).pop();
          onUseRecurringTemplate(template);
        },
      ),
    );
  }


  Future<void> _openBudgetForm(BuildContext context) async {
    final budget = await showModalBottomSheet<MonthlyBudget>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetSheet(
        categories: categories
            .where(
              (category) =>
                  !category.isArchived &&
                  category.transactionType == TransactionType.expense,
            )
            .toList(),
      ),
    );
    if (budget != null) onSaveMonthlyBudget(budget);
  }

  Future<void> _openBudgetDetails(
    BuildContext context,
    MonthlyBudget budget,
  ) async {
    final categoryName = budget.categoryId == null
        ? 'Uncategorized'
        : _categoryName(budget.categoryId!);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BudgetDetailsSheet(
        budget: budget,
        categoryName: categoryName,
        transactions: _transactionsForBudget(budget),
        currency: currency,
      ),
    );
  }

  Future<void> _openGoalForm(BuildContext context) async {
    final goal = await showModalBottomSheet<SavingsGoal>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SavingsGoalSheet(
        accounts: accounts.where((account) => !account.isArchived).toList(),
      ),
    );
    if (goal != null) onSaveSavingsGoal(goal);
  }

  Future<void> _openGoalDetails(BuildContext context, SavingsGoal goal) async {
    final accountName = goal.accountId == null ? null : _accountName(goal.accountId!);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GoalDetailsSheet(
        goal: goal,
        accountName: accountName,
        linkedBalance: _linkedGoalBalance(goal),
        currentAmount: _currentGoalAmount(goal),
        currency: currency,
        onAddContribution: () {
          Navigator.of(context).pop();
          _openContributionForm(context, goal);
        },
      ),
    );
  }

  Future<void> _openContributionForm(
    BuildContext context,
    SavingsGoal goal,
  ) async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ContributionSheet(),
    );
    if (amount == null || amount <= 0) return;
    final now = DateTime.now().toUtc();
    onSaveSavingsGoal(
      goal.copyWith(
        manualContribution: goal.manualContribution + amount,
        updatedAt: now,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onAdd,
  });

  final String title;
  final IconData icon;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: FlowSpacing.xs),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      IconButton(onPressed: onAdd, tooltip: 'Add', icon: const Icon(Icons.add)),
    ],
  );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 136,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ),
  );
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.template,
    required this.accountName,
    required this.categoryName,
    required this.currency,
    required this.onOpenDetails,
    required this.onUse,
    required this.onDelete,
  });

  final RecurringTemplate template;
  final String accountName;
  final String? categoryName;
  final String currency;
  final VoidCallback onOpenDetails;
  final VoidCallback onUse;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpenDetails,
    borderRadius: BorderRadius.circular(FlowRadii.card),
    child: FlowCard(
    density: FlowCardDensity.standard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                template.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            TextButton(onPressed: onUse, child: const Text('Review')),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete template',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        Text(
          [
            _typeLabel(template.type),
            _frequencyLabel(template),
            accountName,
            ?categoryName,
          ].join(' - '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: FlowSpacing.gapGroup),
        FlowAmountText(
          amount: formatCurrency(template.amount, currency),
          style: const TextStyle(fontSize: 15),
        ),
      ],
    ),
    ),
  );

  static String _typeLabel(TransactionType type) => switch (type) {
    TransactionType.income => 'Income',
    TransactionType.expense => 'Expense',
    TransactionType.transfer => 'Transfer',
  };

  static String _frequencyLabel(RecurringTemplate template) =>
      template.frequency == RecurringFrequency.weekly
      ? 'Weekly day ${template.weekday ?? 1}'
      : 'Monthly day ${template.dayOfMonth ?? 1}';
}

class _RecurringDetailsSheet extends StatelessWidget {
  const _RecurringDetailsSheet({
    required this.template,
    required this.accountName,
    required this.categoryName,
    required this.currency,
    required this.onUse,
  });

  final RecurringTemplate template;
  final String accountName;
  final String? categoryName;
  final String currency;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: template.name,
    children: [
      _DetailRow(label: 'Type', value: _RecurringCard._typeLabel(template.type)),
      const SizedBox(height: FlowSpacing.gapGroup),
      _DetailRow(
        label: 'Frequency',
        value: _RecurringCard._frequencyLabel(template),
      ),
      const SizedBox(height: FlowSpacing.gapGroup),
      _DetailRow(label: 'Account', value: accountName),
      if (categoryName != null) ...[
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(label: 'Category', value: categoryName!),
      ],
      if (template.destinationAccountId != null) ...[
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(
          label: 'Destination',
          value: 'Account ${template.destinationAccountId}',
        ),
      ],
      const SizedBox(height: FlowSpacing.gapGroup),
      _DetailRow(
        label: 'Amount',
        value: formatCurrency(template.amount, currency),
      ),
      if (template.note?.isNotEmpty == true) ...[
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(label: 'Note', value: template.note!),
      ],
      const SizedBox(height: FlowSpacing.gapBlock),
      Text(
        'This is a reusable transaction template. It does not change balances until you review and save the generated transaction.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: FlowSpacing.gapGroup),
      Text(
        'History is not inferred yet. A future migration should add a transaction template relation before listing generated transactions here.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: FlowSpacing.lg),
      FlowButton(
        label: 'Review transaction',
        icon: Icons.open_in_new,
        onPressed: onUse,
      ),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      const SizedBox(width: FlowSpacing.sm),
      Expanded(
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.categoryName,
    required this.spent,
    required this.currency,
    required this.onOpenDetails,
    required this.onDelete,
  });

  final MonthlyBudget budget;
  final String categoryName;
  final int spent;
  final String currency;
  final VoidCallback onOpenDetails;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ratio = budget.amount == 0 ? 0.0 : spent / budget.amount;
    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(FlowRadii.card),
      child: FlowCard(
      density: FlowCardDensity.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete budget',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          FlowProgressBar(value: ratio, color: FlowColors.income),
          const SizedBox(height: FlowSpacing.gapGroup),
          Text(
            '${formatCurrency(spent, currency)} of ${formatCurrency(budget.amount, currency)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      ),
    );
  }
}

class _BudgetDetailsSheet extends StatelessWidget {
  const _BudgetDetailsSheet({
    required this.budget,
    required this.categoryName,
    required this.transactions,
    required this.currency,
  });

  final MonthlyBudget budget;
  final String categoryName;
  final List<Transaction> transactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final spent = transactions.fold<int>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
    final remaining = budget.amount - spent;
    final ratio = budget.amount == 0 ? 0.0 : spent / budget.amount;
    final sorted = transactions.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return _SheetScaffold(
      title: categoryName,
      children: [
        _DetailRow(
          label: 'Month',
          value:
              '${budget.month.year}-${budget.month.month.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(label: 'Budget', value: formatCurrency(budget.amount, currency)),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(label: 'Spent', value: formatCurrency(spent, currency)),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(
          label: remaining >= 0 ? 'Remaining' : 'Over',
          value: formatCurrency(remaining.abs(), currency),
        ),
        const SizedBox(height: FlowSpacing.gapBlock),
        FlowProgressBar(value: ratio, color: FlowColors.income),
        const SizedBox(height: FlowSpacing.gapSection),
        Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: FlowSpacing.gapGroup),
        if (sorted.isEmpty)
          const _InlineEmpty(
            message:
                'No transactions yet. Expense transactions for this category and month appear here.',
          )
        else
          for (final transaction in sorted) ...[
            FlowTransactionTile(
              title: transaction.note?.isNotEmpty == true
                  ? transaction.note!
                  : 'Expense',
              subtitle:
                  '${transaction.occurredAt.year}-${transaction.occurredAt.month.toString().padLeft(2, '0')}-${transaction.occurredAt.day.toString().padLeft(2, '0')}',
              amount: '- ${formatCurrency(transaction.amount, currency)}',
              icon: Icons.arrow_upward,
              amountVariant: FlowAmountVariant.expense,
            ),
            const SizedBox(height: FlowSpacing.gapGroup),
          ],
      ],
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({
    required this.goal,
    required this.accountName,
    required this.linkedBalance,
    required this.currentAmount,
    required this.currency,
    required this.onOpenDetails,
    required this.onAddContribution,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final String? accountName;
  final int linkedBalance;
  final int currentAmount;
  final String currency;
  final VoidCallback onOpenDetails;
  final VoidCallback onAddContribution;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ratio = (currentAmount / goal.targetAmount).clamp(0, 1).toDouble();
    final sourceLabel = accountName == null
        ? 'Manual contributions'
        : '$accountName + manual contributions';
    return InkWell(
      onTap: onOpenDetails,
      borderRadius: BorderRadius.circular(FlowRadii.card),
      child: FlowCard(
      density: FlowCardDensity.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete goal',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Text(sourceLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: FlowSpacing.gapGroup),
          FlowProgressBar(value: ratio, color: FlowColors.income),
          const SizedBox(height: FlowSpacing.gapGroup),
          Text(
            '${formatCurrency(currentAmount, currency)} of ${formatCurrency(goal.targetAmount, currency)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (accountName != null) ...[
            const SizedBox(height: FlowSpacing.gapGroup),
            Text(
              'Linked balance ${formatCurrency(linkedBalance, currency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: FlowSpacing.gapGroup),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAddContribution,
              icon: const Icon(Icons.add),
              label: const Text('Add contribution'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _GoalDetailsSheet extends StatelessWidget {
  const _GoalDetailsSheet({
    required this.goal,
    required this.accountName,
    required this.linkedBalance,
    required this.currentAmount,
    required this.currency,
    required this.onAddContribution,
  });

  final SavingsGoal goal;
  final String? accountName;
  final int linkedBalance;
  final int currentAmount;
  final String currency;
  final VoidCallback onAddContribution;

  @override
  Widget build(BuildContext context) {
    final remaining = goal.targetAmount - currentAmount;
    final complete = currentAmount >= goal.targetAmount;
    final ratio = (currentAmount / goal.targetAmount).clamp(0, 1).toDouble();
    return _SheetScaffold(
      title: goal.name,
      children: [
        _DetailRow(label: 'Status', value: complete ? 'Completed' : 'In progress'),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(label: 'Target', value: formatCurrency(goal.targetAmount, currency)),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(label: 'Current', value: formatCurrency(currentAmount, currency)),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(
          label: complete ? 'Surplus' : 'Remaining',
          value: formatCurrency(remaining.abs(), currency),
        ),
        const SizedBox(height: FlowSpacing.gapBlock),
        FlowProgressBar(value: ratio, color: FlowColors.income),
        const SizedBox(height: FlowSpacing.gapSection),
        Text('Activity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: FlowSpacing.gapGroup),
        _DetailRow(
          label: 'Manual',
          value: formatCurrency(goal.manualContribution, currency),
        ),
        if (accountName != null) ...[
          const SizedBox(height: FlowSpacing.gapGroup),
          _DetailRow(
            label: 'Account',
            value: '$accountName (${formatCurrency(linkedBalance, currency)})',
          ),
        ],
        const SizedBox(height: FlowSpacing.gapBlock),
        Text(
          'Per-contribution history needs a dedicated contribution table. Until then, this goal tracks the current manual contribution total.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: FlowSpacing.lg),
        FlowButton(
          label: 'Add contribution',
          icon: Icons.add,
          onPressed: onAddContribution,
        ),
      ],
    );
  }
}

class _RecurringTemplateSheet extends StatefulWidget {
  const _RecurringTemplateSheet({required this.accounts, required this.categories});

  final List<Account> accounts;
  final List<Category> categories;

  @override
  State<_RecurringTemplateSheet> createState() => _RecurringTemplateSheetState();
}

class _RecurringTemplateSheetState extends State<_RecurringTemplateSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  Account? _account;
  Account? _destinationAccount;
  Category? _category;
  int _dayOfMonth = DateTime.now().day.clamp(1, 28);
  int _weekday = DateTime.now().weekday;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Recurring template',
    children: [
      TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Name'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.md),
      FlowSegmentedControl(
        labels: const ['Expense', 'Income', 'Transfer'],
        selectedIndex: _typeIndex(_type),
        onChanged: (index) => setState(() {
          _type = _typeFromIndex(index);
          _category = null;
          _destinationAccount = null;
        }),
      ),
      const SizedBox(height: FlowSpacing.md),
      TextField(
        controller: _amountController,
        inputFormatters: const [FlowCurrencyInputFormatter()],
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Amount'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.md),
      FlowSelector(
        label: 'Account',
        value: _account?.name ?? 'Select account',
        onTap: () async {
          final selected = await _selectAccount(context, widget.accounts);
          if (selected != null) setState(() => _account = selected);
        },
      ),
      if (_type == TransactionType.transfer) ...[
        const SizedBox(height: FlowSpacing.md),
        FlowSelector(
          label: 'To account',
          value: _destinationAccount?.name ?? 'Select destination',
          onTap: () async {
            final selected = await _selectAccount(context, widget.accounts);
            if (selected != null) setState(() => _destinationAccount = selected);
          },
        ),
      ] else ...[
        const SizedBox(height: FlowSpacing.md),
        FlowSelector(
          label: 'Category',
          value: _category?.name ?? 'Select category',
          onTap: () async {
            final selected = await _selectCategory(context);
            if (selected != null) setState(() => _category = selected);
          },
        ),
      ],
      const SizedBox(height: FlowSpacing.md),
      FlowSegmentedControl(
        labels: const ['Weekly', 'Monthly'],
        selectedIndex: _frequency.index,
        onChanged: (index) => setState(() => _frequency = RecurringFrequency.values[index]),
      ),
      const SizedBox(height: FlowSpacing.md),
      TextField(
        decoration: InputDecoration(
          labelText: _frequency == RecurringFrequency.weekly
              ? 'Weekday 1-7'
              : 'Day of month 1-28',
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          final parsed = int.tryParse(value);
          if (parsed == null) return;
          setState(() {
            if (_frequency == RecurringFrequency.weekly) {
              _weekday = parsed.clamp(1, 7);
            } else {
              _dayOfMonth = parsed.clamp(1, 28);
            }
          });
        },
      ),
      const SizedBox(height: FlowSpacing.md),
      TextField(
        controller: _noteController,
        decoration: const InputDecoration(labelText: 'Note (optional)'),
      ),
      const SizedBox(height: FlowSpacing.lg),
      FlowButton(label: 'Save template', onPressed: _canSave ? _save : null),
    ],
  );

  bool get _canSave {
    final amount = parseCurrencyInput(_amountController.text) ?? 0;
    final hasTarget = _type == TransactionType.transfer
        ? _destinationAccount != null && _destinationAccount != _account
        : _category != null;
    return _nameController.text.trim().isNotEmpty &&
        amount > 0 &&
        _account != null &&
        hasTarget;
  }

  void _save() {
    final now = DateTime.now().toUtc();
    Navigator.of(context).pop(
      RecurringTemplate(
        name: _nameController.text.trim(),
        type: _type,
        amount: parseCurrencyInput(_amountController.text)!,
        accountId: _account!.id!,
        destinationAccountId: _destinationAccount?.id,
        categoryId: _category?.id,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        frequency: _frequency,
        dayOfMonth: _frequency == RecurringFrequency.monthly ? _dayOfMonth : null,
        weekday: _frequency == RecurringFrequency.weekly ? _weekday : null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  int _typeIndex(TransactionType type) => switch (type) {
    TransactionType.expense => 0,
    TransactionType.income => 1,
    TransactionType.transfer => 2,
  };

  TransactionType _typeFromIndex(int index) => switch (index) {
    1 => TransactionType.income,
    2 => TransactionType.transfer,
    _ => TransactionType.expense,
  };

  Future<Category?> _selectCategory(BuildContext context) {
    return showModalBottomSheet<Category>(
      context: context,
      builder: (_) => _OptionSheet<Category>(
        title: 'Select category',
        items: widget.categories
            .where((category) => category.transactionType == _type)
            .toList(),
        labelOf: (category) => category.name,
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.categories});
  final List<Category> categories;

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  final _amountController = TextEditingController();
  Category? _category;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Monthly budget',
    children: [
      FlowSelector(
        label: 'Category',
        value: _category?.name ?? 'Select category',
        onTap: () async {
          final selected = await showModalBottomSheet<Category>(
            context: context,
            builder: (_) => _OptionSheet<Category>(
              title: 'Select category',
              items: widget.categories,
              labelOf: (category) => category.name,
            ),
          );
          if (selected != null) setState(() => _category = selected);
        },
      ),
      const SizedBox(height: FlowSpacing.md),
      TextField(
        controller: _amountController,
        inputFormatters: const [FlowCurrencyInputFormatter()],
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Budget amount'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.lg),
      FlowButton(label: 'Save budget', onPressed: _canSave ? _save : null),
    ],
  );

  bool get _canSave =>
      _category != null && (parseCurrencyInput(_amountController.text) ?? 0) > 0;

  void _save() {
    final now = DateTime.now().toUtc();
    final month = DateTime(now.year, now.month);
    Navigator.of(context).pop(
      MonthlyBudget(
        categoryId: _category!.id,
        month: month,
        amount: parseCurrencyInput(_amountController.text)!,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _SavingsGoalSheet extends StatefulWidget {
  const _SavingsGoalSheet({required this.accounts});
  final List<Account> accounts;

  @override
  State<_SavingsGoalSheet> createState() => _SavingsGoalSheetState();
}

class _SavingsGoalSheetState extends State<_SavingsGoalSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _contributionController = TextEditingController();
  Account? _account;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Savings goal',
    children: [
      TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Goal name'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.md),
      TextField(
        controller: _targetController,
        inputFormatters: const [FlowCurrencyInputFormatter()],
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Target amount'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.md),
      FlowSelector(
        label: 'Linked account',
        value: _account?.name ?? 'Manual only',
        onTap: () async {
          final selected = await _selectAccount(context, widget.accounts);
          if (selected != null) setState(() => _account = selected);
        },
      ),
      const SizedBox(height: FlowSpacing.md),
      TextField(
        controller: _contributionController,
        inputFormatters: const [FlowCurrencyInputFormatter()],
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Manual contribution'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.lg),
      FlowButton(label: 'Save goal', onPressed: _canSave ? _save : null),
    ],
  );

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      (parseCurrencyInput(_targetController.text) ?? 0) > 0;

  void _save() {
    final now = DateTime.now().toUtc();
    Navigator.of(context).pop(
      SavingsGoal(
        name: _nameController.text.trim(),
        targetAmount: parseCurrencyInput(_targetController.text)!,
        accountId: _account?.id,
        manualContribution: parseCurrencyInput(_contributionController.text) ?? 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class _ContributionSheet extends StatefulWidget {
  const _ContributionSheet();

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetScaffold(
    title: 'Add contribution',
    children: [
      TextField(
        controller: _amountController,
        inputFormatters: const [FlowCurrencyInputFormatter()],
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Contribution amount'),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: FlowSpacing.lg),
      FlowButton(
        label: 'Add contribution',
        onPressed: _canSave ? _save : null,
      ),
    ],
  );

  bool get _canSave => (parseCurrencyInput(_amountController.text) ?? 0) > 0;

  void _save() {
    Navigator.of(context).pop(parseCurrencyInput(_amountController.text));
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(FlowSpacing.md),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.md),
          ...children,
        ],
      ),
    ),
  );
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.items,
    required this.labelOf,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelOf;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(FlowSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.sm),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labelOf(item)),
              onTap: () => Navigator.of(context).pop(item),
            ),
        ],
      ),
    ),
  );
}

Future<Account?> _selectAccount(BuildContext context, List<Account> accounts) {
  return showModalBottomSheet<Account>(
    context: context,
    builder: (_) => _OptionSheet<Account>(
      title: 'Select account',
      items: accounts,
      labelOf: (account) => account.name,
    ),
  );
}

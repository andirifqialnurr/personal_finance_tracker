import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/flow_store.dart';
import 'data/models/models.dart';
import 'screens/account_form_page.dart';
import 'screens/account_detail_page.dart';
import 'screens/accounts_page.dart';
import 'screens/add_transaction_page.dart';
import 'screens/settings_page.dart';
import 'screens/plans_page.dart';
import 'screens/reports_page.dart';
import 'screens/statistics_page.dart';
import 'screens/transactions_page.dart';
import 'screens/transaction_detail_page.dart';
import 'screens/welcome_page.dart';
import 'screens/home_dashboard.dart';
import 'state/state.dart';
import 'theme/flow_theme.dart';
import 'theme/flow_tokens.dart';

class FlowApp extends StatelessWidget {
  const FlowApp({super.key, this.store});

  final FlowStore? store;

  @override
  Widget build(BuildContext context) {
    final overrideStore = store;
    return ProviderScope(
      overrides: [
        if (overrideStore != null)
          flowStoreProvider.overrideWithValue(overrideStore),
      ],
      child: const _FlowAppView(),
    );
  }
}

class _FlowAppView extends ConsumerStatefulWidget {
  const _FlowAppView();

  @override
  ConsumerState<_FlowAppView> createState() => _FlowAppViewState();
}

class _FlowAppViewState extends ConsumerState<_FlowAppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(flowControllerProvider);
    final themeMode = flow.value?.themeMode ?? ThemeMode.light;
    return MaterialApp(
      title: 'Flow',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: FlowTheme.light(),
      darkTheme: FlowTheme.dark(),
      themeMode: themeMode,
      home: flow.when(
        loading: () => const _FlowLoadingPage(),
        error: (error, stackTrace) => _FlowErrorPage(
          onRetry: () => ref.read(flowControllerProvider.notifier).restore(),
        ),
        data: _buildHome,
      ),
    );
  }

  Widget _buildHome(FlowState state) {
    final controller = ref.read(flowControllerProvider.notifier);
    if (!state.hasCompletedWelcome) {
      return FlowWelcomePage(
        currency: state.currency,
        onCurrencyChanged: (currency) =>
            unawaited(controller.changeCurrency(currency)),
        onCreateFirstAccount: () => _openAccountForm(context),
      );
    }
    return FlowShell(
      onAddAccount: () => _openAccountForm(context),
      onEditAccount: (account) => _openAccountForm(context, account),
      onOpenAccountDetail: (account) => _openAccountDetail(context, account),
      onAddTransaction: () => _openAddTransaction(context),
      onOpenPrefilledTransaction: (transaction) =>
          _openAddTransaction(context, transaction),
      onOpenTransactionDetail: (transaction) =>
          _openTransactionDetail(context, transaction),
    );
  }

  Future<void> _openAddTransaction(
    BuildContext context, [
    Transaction? initialTransaction,
  ]) async {
    final state = _currentFlowState();
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddTransactionPage(
          accounts: state.accounts,
          categories: state.categories,
          currency: state.currency,
          initialTransaction: initialTransaction,
          onSaved: (transaction) => unawaited(
            ref
                .read(flowControllerProvider.notifier)
                .saveTransaction(transaction, editing: initialTransaction),
          ),
        ),
      ),
    );
  }

  Future<void> _openTransactionDetail(
    BuildContext context,
    Transaction transaction,
  ) async {
    final state = _currentFlowState();
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransactionDetailPage(
          transaction: transaction,
          accountName: state.accounts
              .firstWhere((account) => account.id == transaction.accountId)
              .name,
          destinationAccountName: transaction.destinationAccountId == null
              ? null
              : state.accounts
                    .firstWhere(
                      (account) =>
                          account.id == transaction.destinationAccountId,
                    )
                    .name,
          categoryName: transaction.categoryId == null
              ? null
              : state.categories
                    .firstWhere(
                      (category) => category.id == transaction.categoryId,
                      orElse: () => Category(
                        id: transaction.categoryId,
                        name: 'Category ${transaction.categoryId}',
                        transactionType: transaction.type,
                        icon: 'category',
                        color: '#C96B6B',
                      ),
                    )
                    .name,
          currency: state.currency,
          onEdit: () {
            _navigatorKey.currentState!.pop();
            unawaited(_openAddTransaction(context, transaction));
          },
          onDelete: () {
            unawaited(
              ref
                  .read(flowControllerProvider.notifier)
                  .deleteTransaction(transaction.id!),
            );
            _navigatorKey.currentState!.pop();
          },
        ),
      ),
    );
  }

  Future<void> _openAccountDetail(BuildContext context, Account account) async {
    final state = _currentFlowState();
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountDetailPage(
          account: account,
          transactions: state.transactions,
          currency: state.currency,
          onEdit: () {
            _navigatorKey.currentState!.pop();
            unawaited(_openAccountForm(context, account));
          },
          onOpenTransaction: (transaction) =>
              _openTransactionDetail(context, transaction),
        ),
      ),
    );
  }

  Future<void> _openAccountForm(
    BuildContext context, [
    Account? account,
  ]) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountFormPage(
          account: account,
          onSaved: (savedAccount) {
            unawaited(
              ref
                  .read(flowControllerProvider.notifier)
                  .saveAccount(savedAccount),
            );
          },
        ),
      ),
    );
  }

  FlowState _currentFlowState() =>
      ref.read(flowControllerProvider).value ?? FlowState.initial();
}

class _FlowLoadingPage extends StatelessWidget {
  const _FlowLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _FlowErrorPage extends StatelessWidget {
  const _FlowErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(FlowSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load Flow data',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FlowSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

ThemeMode legacyThemeModeFromSetting(ThemeModeSetting mode) => switch (mode) {
  ThemeModeSetting.light => ThemeMode.light,
  ThemeModeSetting.dark => ThemeMode.dark,
  ThemeModeSetting.system => ThemeMode.light,
};

ThemeModeSetting legacyThemeModeSetting(ThemeMode mode) => switch (mode) {
  ThemeMode.light => ThemeModeSetting.light,
  ThemeMode.dark => ThemeModeSetting.dark,
  ThemeMode.system => ThemeModeSetting.light,
};

class FlowShell extends ConsumerStatefulWidget {
  const FlowShell({
    super.key,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onOpenAccountDetail,
    required this.onAddTransaction,
    required this.onOpenPrefilledTransaction,
    required this.onOpenTransactionDetail,
  });

  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final ValueChanged<Account> onOpenAccountDetail;
  final VoidCallback onAddTransaction;
  final ValueChanged<Transaction> onOpenPrefilledTransaction;
  final ValueChanged<Transaction> onOpenTransactionDetail;

  @override
  ConsumerState<FlowShell> createState() => _FlowShellState();
}

class _FlowShellState extends ConsumerState<FlowShell> {
  int _selectedIndex = 0;
  AccountType? _accountsFilterType;

  static const _pages = <_FlowPageData>[
    _FlowPageData('Home', Icons.home_outlined),
    _FlowPageData('Transactions', Icons.receipt_long_outlined),
    _FlowPageData('Statistics', Icons.show_chart_outlined),
    _FlowPageData('Accounts', Icons.account_balance_wallet_outlined),
    _FlowPageData('Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final currency = ref.watch(currencyProvider);
    final hideBalance = ref.watch(hideBalanceProvider);
    final themeMode = ref.watch(themeModeProvider);
    final recurringTemplates = ref.watch(recurringTemplatesProvider);
    final monthlyBudgets = ref.watch(monthlyBudgetsProvider);
    final savingsGoals = ref.watch(savingsGoalsProvider);
    final controller = ref.read(flowControllerProvider.notifier);
    final floatingDecoration = _floatingSurfaceDecoration(context);
    final theme = Theme.of(context);
    final selectedNavColor = theme.colorScheme.primary;
    final selectedNavBackground = selectedNavColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.24 : 0.30,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeDashboard(
              accounts: accounts,
              transactions: transactions,
              categories: categories,
              recurringTemplates: recurringTemplates,
              monthlyBudgets: monthlyBudgets,
              savingsGoals: savingsGoals,
              currency: currency,
              hideBalance: hideBalance,
              onHideBalanceChanged: (value) =>
                  unawaited(controller.changeHideBalance(value)),
              onAddTransaction: widget.onAddTransaction,
              onOpenRecurringTemplates: () => _openPlansSection(
                title: 'Recurring templates',
                section: PlansPageSection.recurringTemplates,
              ),
              onOpenMonthlyBudgets: () => _openPlansSection(
                title: 'Monthly budgets',
                section: PlansPageSection.monthlyBudgets,
              ),
              onOpenSavingsGoals: () => _openPlansSection(
                title: 'Savings goals',
                section: PlansPageSection.savingsGoals,
              ),
              onOpenReports: _openReports,
            ),
            _FlowTabPage(
              title: 'Transactions',
              child: TransactionsPage(
                transactions: transactions,
                accounts: accounts,
                categories: categories,
                currency: currency,
                onOpenDetail: widget.onOpenTransactionDetail,
              ),
            ),
            _FlowTabPage(
              title: 'Statistics',
              child: StatisticsPage(
                transactions: transactions,
                categories: categories,
                currency: currency,
              ),
            ),
            _FlowTabPage(
              title: 'Accounts',
              actions: [
                IconButton(
                  onPressed: () => _openAccountsFilter(context),
                  tooltip: 'Filter accounts',
                  icon: Icon(
                    _accountsFilterType == null
                        ? Icons.filter_list
                        : Icons.filter_list_alt,
                  ),
                ),
                IconButton(
                  onPressed: widget.onAddAccount,
                  tooltip: 'Add account',
                  icon: const Icon(Icons.add),
                ),
              ],
              child: AccountsPage(
                accounts: accounts,
                onAdd: widget.onAddAccount,
                onEdit: widget.onEditAccount,
                onArchive: (account) =>
                    unawaited(controller.archiveAccount(account)),
                onRestore: (account) =>
                    unawaited(controller.restoreAccount(account)),
                transactions: transactions,
                currency: currency,
                onOpenDetail: widget.onOpenAccountDetail,
                filterType: _accountsFilterType,
                onClearFilter: () => setState(() => _accountsFilterType = null),
              ),
            ),
            _FlowTabPage(
              title: 'Settings',
              child: FlowSettingsPage(
                initialThemeMode: themeMode,
                onThemeModeChanged: (mode) =>
                    unawaited(controller.changeThemeMode(mode)),
                currency: currency,
                onCurrencyChanged: (value) =>
                    unawaited(controller.changeCurrency(value)),
                categories: categories,
                onCategoriesChanged: (value) =>
                    unawaited(controller.saveCategories(value)),
                onDeleteAll: () => unawaited(controller.deleteAllData()),
                showAppBar: false,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 2 || _selectedIndex == 4
          ? null
          : FloatingActionButton(
              onPressed: widget.onAddTransaction,
              tooltip: 'Add transaction',
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FlowSpacing.md,
            FlowSpacing.xs,
            FlowSpacing.md,
            FlowSpacing.sm,
          ),
          child: DecoratedBox(
            key: const Key('flow-floating-navigation'),
            decoration: floatingDecoration,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FlowRadii.card),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: [
                  for (final item in _pages)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: SizedBox.square(
                        key: Key(
                          'flow-nav-selected-${item.title.toLowerCase()}',
                        ),
                        dimension: FlowControlSize.iconContainer,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selectedNavBackground,
                            borderRadius: BorderRadius.circular(
                              FlowRadii.input,
                            ),
                          ),
                          child: Icon(item.icon, color: selectedNavColor),
                        ),
                      ),
                      label: item.title,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPlansSection({
    required String title,
    required PlansPageSection section,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _StandaloneFlowPage(
          title: title,
          actions: [_PlansSectionAddAction(section: section)],
          child: _PlansSectionContent(
            section: section,
            onUseRecurringTemplate: (template) =>
                widget.onOpenPrefilledTransaction(_fromTemplate(template)),
          ),
        ),
      ),
    );
  }

  void _openReports() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _StandaloneFlowPage(
          title: 'Reports',
          child: const _ReportsContent(),
        ),
      ),
    );
  }

  Future<void> _openAccountsFilter(BuildContext context) {
    return AccountsPage.showTypeFilter(
      context: context,
      selectedType: _accountsFilterType,
      onSelected: (type) {
        if (!mounted) return;
        setState(() => _accountsFilterType = type);
      },
    );
  }
}

Transaction _fromTemplate(RecurringTemplate template) {
  final now = DateTime.now();
  final utcNow = now.toUtc();
  return Transaction(
    type: template.type,
    amount: template.amount,
    accountId: template.accountId,
    destinationAccountId: template.destinationAccountId,
    categoryId: template.categoryId,
    note: template.note,
    occurredAt: now,
    createdAt: utcNow,
    updatedAt: utcNow,
  );
}

BoxDecoration _floatingSurfaceDecoration(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(FlowRadii.card),
    border: Border.all(
      color: theme.colorScheme.outline.withValues(alpha: 0.72),
    ),
    boxShadow:
        theme.extension<FlowThemeExtension>()?.shadows ?? FlowShadows.card,
  );
}

class _FlowPageData {
  const _FlowPageData(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _PlansSectionContent extends ConsumerWidget {
  const _PlansSectionContent({
    required this.section,
    required this.onUseRecurringTemplate,
  });

  final PlansPageSection section;
  final ValueChanged<RecurringTemplate> onUseRecurringTemplate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(flowControllerProvider.notifier);
    return PlansPage(
      section: section,
      accounts: ref.watch(accountsProvider),
      categories: ref.watch(categoriesProvider),
      transactions: ref.watch(transactionsProvider),
      recurringTemplates: ref.watch(recurringTemplatesProvider),
      monthlyBudgets: ref.watch(monthlyBudgetsProvider),
      savingsGoals: ref.watch(savingsGoalsProvider),
      currency: ref.watch(currencyProvider),
      onSaveRecurringTemplate: (template) =>
          unawaited(controller.saveRecurringTemplate(template)),
      onDeleteRecurringTemplate: (id) =>
          unawaited(controller.deleteRecurringTemplate(id)),
      onUseRecurringTemplate: onUseRecurringTemplate,
      onSaveMonthlyBudget: (budget) =>
          unawaited(controller.saveMonthlyBudget(budget)),
      onDeleteMonthlyBudget: (id) =>
          unawaited(controller.deleteMonthlyBudget(id)),
      onSaveSavingsGoal: (goal) => unawaited(controller.saveSavingsGoal(goal)),
      onDeleteSavingsGoal: (id) => unawaited(controller.deleteSavingsGoal(id)),
    );
  }
}

class _ReportsContent extends ConsumerWidget {
  const _ReportsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(flowControllerProvider.notifier);
    return ReportsPage(
      transactions: ref.watch(transactionsProvider),
      categories: ref.watch(categoriesProvider),
      currency: ref.watch(currencyProvider),
      onExportMonthlyCsv: controller.exportMonthlyCsv,
      onExportMonthlyPdf: controller.exportMonthlyPdf,
      onExportBackup: controller.exportBackup,
    );
  }
}

class _FlowTabPage extends StatelessWidget {
  const _FlowTabPage({required this.title, required this.child, this.actions});

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _FlowPageTitle(title: title, actions: actions),
      Expanded(child: child),
    ],
  );
}

class _StandaloneFlowPage extends StatelessWidget {
  const _StandaloneFlowPage({
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
      ),
      actions: actions,
    ),
    body: SafeArea(top: false, child: child),
  );
}

class _PlansSectionAddAction extends ConsumerWidget {
  const _PlansSectionAddAction({required this.section});

  final PlansPageSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: _tooltip,
    onPressed: () => unawaited(_openForm(context, ref)),
    icon: const Icon(Icons.add),
  );

  String get _tooltip => switch (section) {
    PlansPageSection.recurringTemplates => 'Add recurring template',
    PlansPageSection.monthlyBudgets => 'Add monthly budget',
    PlansPageSection.savingsGoals => 'Add savings goal',
    PlansPageSection.all => 'Add',
  };

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(flowControllerProvider.notifier);
    switch (section) {
      case PlansPageSection.recurringTemplates:
        final template = await PlansPage.showRecurringTemplateForm(
          context,
          accounts: ref
              .read(accountsProvider)
              .where((account) => !account.isArchived)
              .toList(),
          categories: ref
              .read(categoriesProvider)
              .where((category) => !category.isArchived)
              .toList(),
        );
        if (template != null) {
          await controller.saveRecurringTemplate(template);
        }
      case PlansPageSection.monthlyBudgets:
        final budget = await PlansPage.showMonthlyBudgetForm(
          context,
          categories: ref
              .read(categoriesProvider)
              .where(
                (category) =>
                    !category.isArchived &&
                    category.transactionType == TransactionType.expense,
              )
              .toList(),
        );
        if (budget != null) {
          await controller.saveMonthlyBudget(budget);
        }
      case PlansPageSection.savingsGoals:
        final goal = await PlansPage.showSavingsGoalForm(
          context,
          accounts: ref
              .read(accountsProvider)
              .where(
                (account) =>
                    !account.isArchived && account.type == AccountType.savings,
              )
              .toList(),
        );
        if (goal != null) {
          await controller.saveSavingsGoal(goal);
        }
      case PlansPageSection.all:
        break;
    }
  }
}

class _FlowPageTitle extends StatelessWidget {
  const _FlowPageTitle({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      FlowSpacing.md,
      FlowSpacing.sm,
      FlowSpacing.md,
      FlowSpacing.xs,
    ),
    child: SizedBox(
      height: kToolbarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
              ),
            ),
          ),
          if (actions?.isNotEmpty == true)
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ),
        ],
      ),
    ),
  );
}

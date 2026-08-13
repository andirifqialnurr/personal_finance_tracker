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
    if (overrideStore == null) return const _FlowAppView();
    return ProviderScope(
      overrides: [flowStoreProvider.overrideWithValue(overrideStore)],
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
      accounts: state.accounts,
      transactions: state.transactions,
      categories: state.categories,
      currency: state.currency,
      hideBalance: state.hideBalance,
      onHideBalanceChanged: (value) =>
          unawaited(controller.changeHideBalance(value)),
      themeMode: state.themeMode,
      onThemeModeChanged: (mode) => unawaited(controller.changeThemeMode(mode)),
      onCurrencyChanged: (currency) =>
          unawaited(controller.changeCurrency(currency)),
      onCategoriesChanged: (categories) =>
          unawaited(controller.saveCategories(categories)),
      onExportCsv: controller.exportCsv,
      onDeleteAll: () => unawaited(controller.deleteAllData()),
      onAddAccount: () => _openAccountForm(context),
      onEditAccount: (account) => _openAccountForm(context, account),
      onArchiveAccount: (account) =>
          unawaited(controller.archiveAccount(account)),
      onOpenAccountDetail: (account) => _openAccountDetail(context, account),
      onAddTransaction: () => _openAddTransaction(context),
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

class FlowShell extends StatefulWidget {
  const FlowShell({
    super.key,
    required this.accounts,
    required this.transactions,
    this.categories = const [],
    this.currency = 'IDR',
    this.hideBalance = false,
    this.onHideBalanceChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onCurrencyChanged,
    required this.onCategoriesChanged,
    required this.onExportCsv,
    required this.onDeleteAll,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onArchiveAccount,
    required this.onOpenAccountDetail,
    required this.onAddTransaction,
    required this.onOpenTransactionDetail,
  });

  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;
  final bool hideBalance;
  final ValueChanged<bool>? onHideBalanceChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<List<Category>> onCategoriesChanged;
  final Future<String> Function() onExportCsv;
  final VoidCallback onDeleteAll;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final ValueChanged<Account> onArchiveAccount;
  final ValueChanged<Account> onOpenAccountDetail;
  final VoidCallback onAddTransaction;
  final ValueChanged<Transaction> onOpenTransactionDetail;

  @override
  State<FlowShell> createState() => _FlowShellState();
}

class _FlowShellState extends State<FlowShell> {
  int _selectedIndex = 0;

  static const _pages = <_FlowPageData>[
    _FlowPageData('Home', Icons.home_outlined),
    _FlowPageData('Transactions', Icons.receipt_long_outlined),
    _FlowPageData('Statistics', Icons.show_chart_outlined),
    _FlowPageData('Accounts', Icons.account_balance_wallet_outlined),
    _FlowPageData('Settings', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
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
              accounts: widget.accounts,
              transactions: widget.transactions,
              categories: widget.categories,
              currency: widget.currency,
              hideBalance: widget.hideBalance,
              onHideBalanceChanged: widget.onHideBalanceChanged,
              onAddTransaction: widget.onAddTransaction,
            ),
            TransactionsPage(
              transactions: widget.transactions,
              accounts: widget.accounts,
              categories: widget.categories,
              currency: widget.currency,
              onOpenDetail: widget.onOpenTransactionDetail,
            ),
            StatisticsPage(
              transactions: widget.transactions,
              categories: widget.categories,
              currency: widget.currency,
            ),
            AccountsPage(
              accounts: widget.accounts,
              onAdd: widget.onAddAccount,
              onEdit: widget.onEditAccount,
              onArchive: widget.onArchiveAccount,
              transactions: widget.transactions,
              currency: widget.currency,
              onOpenDetail: widget.onOpenAccountDetail,
            ),
            FlowSettingsPage(
              initialThemeMode: widget.themeMode,
              onThemeModeChanged: widget.onThemeModeChanged,
              currency: widget.currency,
              onCurrencyChanged: widget.onCurrencyChanged,
              categories: widget.categories,
              onCategoriesChanged: widget.onCategoriesChanged,
              onExportCsv: widget.onExportCsv,
              onDeleteAll: widget.onDeleteAll,
              showAppBar: false,
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

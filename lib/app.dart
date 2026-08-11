import 'dart:async';

import 'package:flutter/material.dart';

import 'data/flow_store.dart';
import 'data/flow_csv_exporter.dart';
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
import 'theme/flow_theme.dart';
import 'theme/flow_tokens.dart';

class FlowApp extends StatefulWidget {
  const FlowApp({super.key, this.store});

  final FlowStore? store;

  @override
  State<FlowApp> createState() => _FlowAppState();
}

class _FlowAppState extends State<FlowApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final FlowStore _store = widget.store ?? MemoryFlowStore();
  ThemeMode _themeMode = ThemeMode.light;
  final List<Account> _accounts = [];
  final List<Transaction> _transactions = [];
  List<Category> _categories = [];
  String _currency = 'IDR';
  bool _hideBalance = false;
  bool _hasCompletedWelcome = false;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreState());
  }

  @override
  void dispose() {
    _persist(_store.close());
    super.dispose();
  }

  Future<void> _restoreState() async {
    try {
      final snapshot = await _store.load();
      if (!mounted) return;
      setState(() {
        _accounts
          ..clear()
          ..addAll(snapshot.accounts);
        _categories = List.of(snapshot.categories);
        _transactions
          ..clear()
          ..addAll(snapshot.transactions);
        _currency = snapshot.settings.currency;
        _themeMode = _themeModeFromSetting(snapshot.settings.themeMode);
        _hideBalance = snapshot.settings.hideBalance;
        _hasCompletedWelcome = _accounts.isNotEmpty;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to restore Flow data: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: FlowTheme.light(),
      darkTheme: FlowTheme.dark(),
      themeMode: _themeMode,
      home: _hasCompletedWelcome
          ? FlowShell(
              accounts: _accounts,
              transactions: _transactions,
              categories: _categories,
              currency: _currency,
              hideBalance: _hideBalance,
              onHideBalanceChanged: _changeHideBalance,
              themeMode: _themeMode,
              onThemeModeChanged: _changeTheme,
              onCurrencyChanged: _changeCurrency,
              onCategoriesChanged: (categories) {
                setState(() => _categories = categories);
                for (final category in categories) {
                  _persist(_store.saveCategory(category));
                }
              },
              onExportCsv: _exportCsv,
              onDeleteAll: _deleteAllData,
              onAddAccount: () => _openAccountForm(context),
              onEditAccount: (account) => _openAccountForm(context, account),
              onArchiveAccount: _archiveAccount,
              onOpenAccountDetail: (account) =>
                  _openAccountDetail(context, account),
              onAddTransaction: () => _openAddTransaction(context),
              onOpenTransactionDetail: (transaction) =>
                  _openTransactionDetail(context, transaction),
            )
          : FlowWelcomePage(
              currency: _currency,
              onCurrencyChanged: _changeCurrency,
              onCreateFirstAccount: () => _openAccountForm(context),
            ),
    );
  }

  Future<void> _openAddTransaction(
    BuildContext context, [
    Transaction? initialTransaction,
  ]) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddTransactionPage(
          accounts: _accounts,
          categories: _categories,
          currency: _currency,
          initialTransaction: initialTransaction,
          onSaved: (transaction) =>
              _saveTransaction(transaction, initialTransaction),
        ),
      ),
    );
  }

  void _saveTransaction(Transaction transaction, Transaction? editing) {
    final transactionWithId = editing == null
        ? transaction.copyWith(
            id: _nextId(_transactions.map((item) => item.id)),
          )
        : transaction.copyWith(id: editing.id);
    setState(() {
      if (editing == null) {
        _transactions.add(transactionWithId);
      } else {
        final index = _transactions.indexOf(editing);
        if (index != -1) {
          _transactions[index] = transactionWithId;
        }
      }
    });
    _persist(_store.saveTransaction(transactionWithId));
  }

  Future<void> _openTransactionDetail(
    BuildContext context,
    Transaction transaction,
  ) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransactionDetailPage(
          transaction: transaction,
          accountName: _accounts
              .firstWhere((account) => account.id == transaction.accountId)
              .name,
          destinationAccountName: transaction.destinationAccountId == null
              ? null
              : _accounts
                    .firstWhere(
                      (account) =>
                          account.id == transaction.destinationAccountId,
                    )
                    .name,
          categoryName: transaction.categoryId == null
              ? null
              : _categories
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
          currency: _currency,
          onEdit: () {
            _navigatorKey.currentState!.pop();
            unawaited(_openAddTransaction(context, transaction));
          },
          onDelete: () {
            setState(
              () => _transactions.removeWhere(
                (item) => item.id == transaction.id,
              ),
            );
            _persist(_store.deleteTransaction(transaction.id!));
            _navigatorKey.currentState!.pop();
          },
        ),
      ),
    );
  }

  Future<void> _openAccountDetail(BuildContext context, Account account) async {
    await _navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountDetailPage(
          account: account,
          transactions: _transactions,
          currency: _currency,
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
            final accountWithId = savedAccount.id == null
                ? _copyAccount(
                    savedAccount,
                    _nextId(_accounts.map((item) => item.id)),
                  )
                : savedAccount;
            setState(() {
              final index = _accounts.indexWhere(
                (item) => item.id == accountWithId.id,
              );
              if (index == -1) {
                _accounts.add(accountWithId);
              } else {
                _accounts[index] = accountWithId;
              }
              _hasCompletedWelcome = true;
            });
            _persist(_store.saveAccount(accountWithId));
          },
        ),
      ),
    );
  }

  void _archiveAccount(Account account) {
    final archived = _copyAccount(
      account,
      account.id!,
      isArchived: true,
      updatedAt: DateTime.now().toUtc(),
    );
    setState(() {
      final index = _accounts.indexWhere((item) => item.id == account.id);
      if (index == -1) return;
      _accounts[index] = archived;
    });
    _persist(_store.saveAccount(archived));
  }

  void _changeHideBalance(bool value) {
    setState(() => _hideBalance = value);
    _saveSettings();
  }

  void _changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _saveSettings();
  }

  void _changeCurrency(String currency) {
    setState(() => _currency = currency);
    _saveSettings();
  }

  void _saveSettings() {
    _persist(
      _store.saveSettings(
        AppSettings(
          currency: _currency,
          themeMode: _themeModeSetting(_themeMode),
          hideBalance: _hideBalance,
        ),
      ),
    );
  }

  void _deleteAllData() {
    setState(() {
      _accounts.clear();
      _transactions.clear();
      _categories = MemoryFlowStore.defaultCategories();
      _currency = 'IDR';
      _themeMode = ThemeMode.light;
      _hideBalance = false;
      _hasCompletedWelcome = false;
    });
    _persist(_store.deleteAll());
  }

  Future<String> _exportCsv() async {
    final file = await FlowCsvExporter.write(
      transactions: _transactions,
      accounts: _accounts,
      categories: _categories,
    );
    return file.path;
  }

  void _persist(Future<dynamic> operation) {
    unawaited(
      operation.then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Unable to save Flow data: $error\n$stackTrace');
        },
      ),
    );
  }
}

ThemeMode _themeModeFromSetting(ThemeModeSetting mode) => switch (mode) {
  ThemeModeSetting.light => ThemeMode.light,
  ThemeModeSetting.dark => ThemeMode.dark,
  ThemeModeSetting.system => ThemeMode.light,
};

ThemeModeSetting _themeModeSetting(ThemeMode mode) => switch (mode) {
  ThemeMode.light => ThemeModeSetting.light,
  ThemeMode.dark => ThemeModeSetting.dark,
  ThemeMode.system => ThemeModeSetting.light,
};

int _nextId(Iterable<int?> ids) {
  var maxId = 0;
  for (final id in ids) {
    if (id != null && id > maxId) maxId = id;
  }
  return maxId + 1;
}

Account _copyAccount(
  Account account,
  int id, {
  bool? isArchived,
  DateTime? updatedAt,
}) => Account(
  id: id,
  name: account.name,
  type: account.type,
  openingBalance: account.openingBalance,
  icon: account.icon,
  color: account.color,
  isArchived: isArchived ?? account.isArchived,
  createdAt: account.createdAt,
  updatedAt: updatedAt ?? account.updatedAt,
);

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
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysHide,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: [
                  for (final item in _pages)
                    NavigationDestination(
                      icon: Icon(item.icon),
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

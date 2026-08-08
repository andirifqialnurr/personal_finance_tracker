import 'package:flutter/material.dart';

import 'data/models/models.dart';
import 'screens/account_form_page.dart';
import 'screens/accounts_page.dart';
import 'screens/add_transaction_page.dart';
import 'screens/settings_page.dart';
import 'screens/welcome_page.dart';
import 'screens/home_dashboard.dart';
import 'theme/flow_theme.dart';
import 'theme/flow_tokens.dart';

class FlowApp extends StatefulWidget {
  const FlowApp({super.key});

  @override
  State<FlowApp> createState() => _FlowAppState();
}

class _FlowAppState extends State<FlowApp> {
  ThemeMode _themeMode = ThemeMode.system;
  final List<Account> _accounts = [];
  bool _hasCompletedWelcome = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      debugShowCheckedModeBanner: false,
      theme: FlowTheme.light(),
      darkTheme: FlowTheme.dark(),
      themeMode: _themeMode,
      home: _hasCompletedWelcome
          ? FlowShell(
              accounts: _accounts,
              onOpenSettings: _openSettings,
              onAddAccount: () => _openAccountForm(context),
              onEditAccount: (account) => _openAccountForm(context, account),
              onArchiveAccount: _archiveAccount,
            )
          : FlowWelcomePage(
              onCreateFirstAccount: () => _openAccountForm(context),
            ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FlowSettingsPage(
          initialThemeMode: _themeMode,
          onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
        ),
      ),
    );
  }

  Future<void> _openAccountForm(
    BuildContext context, [
    Account? account,
  ]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountFormPage(
          account: account,
          onSaved: (savedAccount) {
            final accountWithId = savedAccount.id == null
                ? Account(
                    id: _accounts.isEmpty
                        ? 1
                        : _accounts
                                  .map((item) => item.id ?? 0)
                                  .reduce((a, b) => a > b ? a : b) +
                              1,
                    name: savedAccount.name,
                    type: savedAccount.type,
                    openingBalance: savedAccount.openingBalance,
                    icon: savedAccount.icon,
                    color: savedAccount.color,
                    isArchived: savedAccount.isArchived,
                    createdAt: savedAccount.createdAt,
                    updatedAt: savedAccount.updatedAt,
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
          },
        ),
      ),
    );
  }

  void _archiveAccount(Account account) {
    setState(() {
      final index = _accounts.indexWhere((item) => item.id == account.id);
      if (index == -1) return;
      _accounts[index] = Account(
        id: account.id,
        name: account.name,
        type: account.type,
        openingBalance: account.openingBalance,
        icon: account.icon,
        color: account.color,
        isArchived: true,
        createdAt: account.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    });
  }
}

class FlowShell extends StatefulWidget {
  const FlowShell({
    super.key,
    required this.accounts,
    required this.onOpenSettings,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onArchiveAccount,
  });

  final List<Account> accounts;
  final Future<void> Function(BuildContext context) onOpenSettings;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final ValueChanged<Account> onArchiveAccount;

  @override
  State<FlowShell> createState() => _FlowShellState();
}

class _FlowShellState extends State<FlowShell> {
  int _selectedIndex = 0;

  static const _pages = <_FlowPageData>[
    _FlowPageData('Home', Icons.home_outlined),
    _FlowPageData('Transactions', Icons.receipt_long_outlined),
    _FlowPageData('Statistics', Icons.bar_chart_outlined),
    _FlowPageData('Accounts', Icons.account_balance_wallet_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(page.title),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              onPressed: () => widget.onOpenSettings(context),
              tooltip: 'Settings',
              icon: const Icon(Icons.person_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeDashboard(accounts: widget.accounts),
            _EmptyPage(data: _pages[1]),
            _EmptyPage(data: _pages[2]),
            AccountsPage(
              accounts: widget.accounts,
              onAdd: widget.onAddAccount,
              onEdit: widget.onEditAccount,
              onArchive: widget.onArchiveAccount,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddTransactionPage()),
        ),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final item in _pages)
            NavigationDestination(icon: Icon(item.icon), label: item.title),
        ],
      ),
    );
  }
}

class _EmptyPage extends StatelessWidget {
  const _EmptyPage({required this.data});

  final _FlowPageData data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              size: FlowIconSize.pageEmptyState,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: FlowSpacing.md),
            Text(
              '${data.title} will appear here',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FlowSpacing.xs),
            const Text(
              'Your local finance data will be available once the first account and transaction flow is added.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowPageData {
  const _FlowPageData(this.title, this.icon);

  final String title;
  final IconData icon;
}

import 'package:flutter/material.dart';

import 'screens/add_transaction_page.dart';
import 'screens/settings_page.dart';
import 'theme/flow_theme.dart';
import 'theme/flow_tokens.dart';

class FlowApp extends StatefulWidget {
  const FlowApp({super.key});

  @override
  State<FlowApp> createState() => _FlowAppState();
}

class _FlowAppState extends State<FlowApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow',
      debugShowCheckedModeBanner: false,
      theme: FlowTheme.light(),
      darkTheme: FlowTheme.dark(),
      themeMode: _themeMode,
      home: FlowShell(onOpenSettings: _openSettings),
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
}

class FlowShell extends StatefulWidget {
  const FlowShell({super.key, required this.onOpenSettings});

  final Future<void> Function(BuildContext context) onOpenSettings;

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
            const _EmptyHomePage(),
            _EmptyPage(data: _pages[1]),
            _EmptyPage(data: _pages[2]),
            _EmptyPage(data: _pages[3]),
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

class _EmptyHomePage extends StatelessWidget {
  const _EmptyHomePage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: FlowIconSize.emptyState,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: FlowSpacing.md),
            Text(
              'Start your Flow',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FlowSpacing.xs),
            Text(
              'Create your first account to see your balance and transactions here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
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

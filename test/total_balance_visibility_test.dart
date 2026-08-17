import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/app.dart';
import 'package:personal_finance_tracker/data/flow_store.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/home_dashboard.dart';
import 'package:personal_finance_tracker/theme/flow_theme.dart';
import 'package:personal_finance_tracker/utils/flow_format.dart';

void main() {
  final timestamp = DateTime(2026, 8, 9);
  final account = Account(
    id: 1,
    name: 'Cash',
    type: AccountType.cash,
    openingBalance: 100000,
    icon: 'wallet',
    color: '#168C78',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  final negativeAccount = Account(
    id: 1,
    name: 'Cash',
    type: AccountType.cash,
    openingBalance: 0,
    icon: 'wallet',
    color: '#168C78',
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  testWidgets('masks only the total balance and keeps the toggle reversible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowTheme.light(),
        home: Scaffold(body: _BalanceVisibilityHarness(account: account)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(formatCurrency(100000, 'IDR')), findsOneWidget);
    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pumpAndSettle();

    expect(find.text('Rp ••••••'), findsOneWidget);
    expect(find.text(formatCurrency(100000, 'IDR')), findsNothing);
    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();
    expect(find.text(formatCurrency(100000, 'IDR')), findsOneWidget);
  });

  testWidgets('keeps the negative sign visible while masking the amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowTheme.light(),
        home: Scaffold(
          body: HomeDashboard(
            accounts: [negativeAccount],
            transactions: [
              Transaction(
                id: 1,
                type: TransactionType.expense,
                amount: 1000,
                accountId: 1,
                categoryId: 1,
                occurredAt: timestamp,
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
            ],
            hideBalance: true,
            onAddTransaction: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rp -••••••'), findsOneWidget);
    expect(find.text('Income'), findsWidgets);
    expect(find.text('Expense'), findsWidgets);
  });

  testWidgets('restores and persists the balance visibility setting', (
    tester,
  ) async {
    final store = MemoryFlowStore(
      accounts: [account],
      settings: const AppSettings(hideBalance: true),
    );
    await tester.pumpWidget(FlowApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Rp ••••••'), findsOneWidget);
    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();

    expect(find.text(formatCurrency(100000, 'IDR')), findsOneWidget);
    expect((await store.load()).settings.hideBalance, isFalse);
  });
}

class _BalanceVisibilityHarness extends StatefulWidget {
  const _BalanceVisibilityHarness({required this.account});

  final Account account;

  @override
  State<_BalanceVisibilityHarness> createState() =>
      _BalanceVisibilityHarnessState();
}

class _BalanceVisibilityHarnessState extends State<_BalanceVisibilityHarness> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    return HomeDashboard(
      accounts: [widget.account],
      hideBalance: _hideBalance,
      onHideBalanceChanged: (value) => setState(() => _hideBalance = value),
      onAddTransaction: () {},
    );
  }
}

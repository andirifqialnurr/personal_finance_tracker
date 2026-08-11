import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/app.dart';
import 'package:personal_finance_tracker/data/flow_store.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/account_detail_page.dart';
import 'package:personal_finance_tracker/screens/home_dashboard.dart';
import 'package:personal_finance_tracker/screens/transaction_detail_page.dart';
import 'package:personal_finance_tracker/screens/transactions_page.dart';
import 'package:personal_finance_tracker/theme/flow_theme.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 9, 12);
  final account = Account(
    id: 1,
    name: 'Cash account with a deliberately long name',
    type: AccountType.cash,
    openingBalance: 100000,
    icon: 'wallet',
    color: '#168C78',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  const category = Category(
    id: 2,
    name: 'Food',
    transactionType: TransactionType.expense,
    icon: 'restaurant',
    color: '#C96B6B',
  );
  final transaction = Transaction(
    id: 1,
    type: TransactionType.expense,
    amount: 50000,
    accountId: 1,
    categoryId: 2,
    note: 'Lunch',
    occurredAt: timestamp,
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  Widget harness(Widget child) => MaterialApp(
    theme: FlowTheme.light(),
    darkTheme: FlowTheme.dark(),
    home: Scaffold(body: child),
  );

  testWidgets('populated Home remains usable at all target widths', (
    tester,
  ) async {
    for (final width in [320.0, 360.0, 400.0]) {
      await tester.binding.setSurfaceSize(Size(width, 720));
      await tester.pumpWidget(
        harness(
          HomeDashboard(
            accounts: [account],
            transactions: [transaction],
            categories: const [category],
            onAddTransaction: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final homeList = find.byType(ListView);
      expect(homeList, findsOneWidget);
      for (var attempt = 0; attempt < 5; attempt += 1) {
        if (find.text('Recent transactions').evaluate().isNotEmpty) break;
        await tester.drag(homeList, const Offset(0, -400));
        await tester.pumpAndSettle();
      }

      expect(find.text('Recent transactions'), findsOneWidget);
      expect(find.textContaining('Food'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Transactions exposes a no-result state for search', (tester) async {
    await tester.pumpWidget(
      harness(
        TransactionsPage(
          transactions: [transaction],
          accounts: [account],
          categories: const [category],
          onOpenDetail: (_) {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'not found');
    await tester.pumpAndSettle();

    expect(find.text('No matching transactions'), findsOneWidget);
  });

  testWidgets('delete confirmation requires an explicit action', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowTheme.light(),
        home: TransactionDetailPage(
          transaction: transaction,
          accountName: account.name,
          categoryName: category.name,
          onEdit: () {},
          onDelete: () => deleted = true,
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete transaction?'), findsOneWidget);
    expect(deleted, isFalse);
    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('account detail shows the populated transaction state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowTheme.light(),
        home: AccountDetailPage(
          account: account,
          transactions: [transaction],
          onEdit: () {},
          onOpenTransaction: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account transactions'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app restores a populated snapshot from its store', (tester) async {
    final store = MemoryFlowStore(
      accounts: [account],
      categories: const [category],
      transactions: [transaction],
    );
    await tester.pumpWidget(FlowApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Recent transactions'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Cash account'), findsWidgets);
    expect(find.text('Recent transactions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

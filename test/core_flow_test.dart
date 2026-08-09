import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/app.dart';
import 'package:personal_finance_tracker/data/flow_store.dart';
import 'package:personal_finance_tracker/data/models/models.dart';

void main() {
  testWidgets('core flow stores income and transfer transactions', (tester) async {
    final timestamp = DateTime.utc(2026, 8, 9);
    final store = MemoryFlowStore(
      accounts: [
        Account(
          id: 1,
          name: 'Cash',
          type: AccountType.cash,
          openingBalance: 0,
          icon: 'wallet',
          color: '#168C78',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
        Account(
          id: 2,
          name: 'Bank',
          type: AccountType.bank,
          openingBalance: 0,
          icon: 'account_balance',
          color: '#168C78',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    );
    await tester.pumpWidget(FlowApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income'));
    await tester.enterText(find.byType(TextField).first, '250000');
    await tester.tap(find.text('Select account'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.ensureVisible(find.text('Select category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salary'));
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Save transaction'),
    );
    await tester.pumpAndSettle();

    var snapshot = await store.load();
    expect(snapshot.transactions.single.type, TransactionType.income);
    expect(snapshot.transactions.single.amount, 250000);

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer'));
    await tester.enterText(find.byType(TextField).first, '100000');
    await tester.tap(find.text('Select account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.ensureVisible(find.text('Select destination'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select destination'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank').first);
    await tester.ensureVisible(find.text('Save transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save transaction'));
    await tester.pumpAndSettle();

    snapshot = await store.load();
    expect(snapshot.transactions, hasLength(2));
    expect(
      snapshot.transactions.where((item) => item.type == TransactionType.transfer),
      hasLength(1),
    );
  });
}

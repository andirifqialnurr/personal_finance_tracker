import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/components/flow_components.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:personal_finance_tracker/screens/plans_page.dart';

void main() {
  test('Memory store persists planning data in snapshots', () async {
    final store = MemoryFlowStore();
    final now = DateTime.utc(2026, 8, 17);
    final account = await store.saveAccount(
      Account(
        name: 'Savings',
        type: AccountType.bank,
        openingBalance: 500000,
        icon: 'bank',
        color: '#168C78',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final category = (await store.load())
        .categories
        .firstWhere((item) => item.transactionType == TransactionType.expense);

    final template = await store.saveRecurringTemplate(
      RecurringTemplate(
        name: 'Internet bill',
        type: TransactionType.expense,
        amount: 350000,
        accountId: account.id!,
        categoryId: category.id,
        frequency: RecurringFrequency.monthly,
        dayOfMonth: 10,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final budget = await store.saveMonthlyBudget(
      MonthlyBudget(
        categoryId: category.id,
        month: DateTime(2026, 8),
        amount: 1000000,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final goal = await store.saveSavingsGoal(
      SavingsGoal(
        name: 'Emergency fund',
        targetAmount: 5000000,
        accountId: account.id,
        manualContribution: 250000,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final snapshot = await store.load();

    expect(snapshot.recurringTemplates.single.id, template.id);
    expect(snapshot.recurringTemplates.single.amount, 350000);
    expect(snapshot.monthlyBudgets.single.id, budget.id);
    expect(snapshot.monthlyBudgets.single.month.month, 8);
    expect(snapshot.savingsGoals.single.id, goal.id);
    expect(snapshot.savingsGoals.single.manualContribution, 250000);
  });

  test('backup JSON roundtrips core and planning data', () async {
    final now = DateTime.utc(2026, 8, 17);
    final snapshot = FlowSnapshot(
      accounts: [
        Account(
          id: 7,
          name: 'Cash',
          type: AccountType.cash,
          openingBalance: 100000,
          icon: 'wallet',
          color: '#168C78',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      categories: [
        const Category(
          id: 11,
          name: 'Bills',
          transactionType: TransactionType.expense,
          icon: 'receipt',
          color: '#C96B6B',
        ),
      ],
      transactions: [
        Transaction(
          id: 21,
          type: TransactionType.expense,
          amount: 50000,
          accountId: 7,
          categoryId: 11,
          occurredAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      settings: const AppSettings(currency: 'IDR', hideBalance: true),
      recurringTemplates: [
        RecurringTemplate(
          id: 31,
          name: 'Rent',
          type: TransactionType.expense,
          amount: 2000000,
          accountId: 7,
          categoryId: 11,
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      monthlyBudgets: [
        MonthlyBudget(
          id: 41,
          categoryId: 11,
          month: DateTime(2026, 8),
          amount: 3000000,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      savingsGoals: [
        SavingsGoal(
          id: 51,
          name: 'Laptop',
          targetAmount: 12000000,
          accountId: 7,
          manualContribution: 1500000,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final json = FlowBackupCodec.encode(snapshot);
    final preview = FlowBackupCodec.preview(json);
    final decoded = FlowBackupCodec.decode(json);

    expect(preview.accounts, 1);
    expect(preview.transactions, 1);
    expect(preview.recurringTemplates, 1);
    expect(preview.monthlyBudgets, 1);
    expect(preview.savingsGoals, 1);
    expect(decoded.accounts.single.id, 7);
    expect(decoded.transactions.single.categoryId, 11);
    expect(decoded.recurringTemplates.single.name, 'Rent');
    expect(decoded.monthlyBudgets.single.amount, 3000000);
    expect(decoded.savingsGoals.single.targetAmount, 12000000);
  });

  testWidgets('planning empty states render as centered text without cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlansPage(
            section: PlansPageSection.recurringTemplates,
            accounts: const [],
            categories: const [],
            transactions: const [],
            recurringTemplates: const [],
            monthlyBudgets: const [],
            savingsGoals: const [],
            currency: 'IDR',
            onSaveRecurringTemplate: (_) {},
            onDeleteRecurringTemplate: (_) {},
            onUseRecurringTemplate: (_) {},
            onSaveMonthlyBudget: (_) {},
            onDeleteMonthlyBudget: (_) {},
            onSaveSavingsGoal: (_) {},
            onDeleteSavingsGoal: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('No recurring templates yet'), findsOneWidget);
    expect(find.byType(FlowCard), findsNothing);
  });

  testWidgets('budget detail shows matching monthly transactions', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17);
    const category = Category(
      id: 11,
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
    );
    final budget = MonthlyBudget(
      id: 41,
      categoryId: 11,
      month: DateTime(2026, 8),
      amount: 300000,
      createdAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlansPage(
            section: PlansPageSection.monthlyBudgets,
            accounts: [
              Account(
                id: 7,
                name: 'Cash',
                type: AccountType.cash,
                openingBalance: 0,
                icon: 'wallet',
                color: '#168C78',
                createdAt: now,
                updatedAt: now,
              ),
            ],
            categories: const [category],
            transactions: [
              Transaction(
                id: 21,
                type: TransactionType.expense,
                amount: 50000,
                accountId: 7,
                categoryId: 11,
                note: 'Lunch',
                occurredAt: now,
                createdAt: now,
                updatedAt: now,
              ),
              Transaction(
                id: 22,
                type: TransactionType.expense,
                amount: 75000,
                accountId: 7,
                categoryId: 11,
                note: 'Next month',
                occurredAt: DateTime.utc(2026, 9, 1),
                createdAt: now,
                updatedAt: now,
              ),
            ],
            recurringTemplates: const [],
            monthlyBudgets: [budget],
            savingsGoals: const [],
            currency: 'IDR',
            onSaveRecurringTemplate: (_) {},
            onDeleteRecurringTemplate: (_) {},
            onUseRecurringTemplate: (_) {},
            onSaveMonthlyBudget: (_) {},
            onDeleteMonthlyBudget: (_) {},
            onSaveSavingsGoal: (_) {},
            onDeleteSavingsGoal: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('Rp 50.000 of Rp 300.000 (16.7%)', findRichText: true),
      findsOneWidget,
    );
    final cardFill = tester.getSize(
      find.descendant(
        of: find.byKey(const Key('monthly-budget-card-progress')),
        matching: find.byKey(const Key('flow-progress-fill')),
      ),
    );
    expect(cardFill.width, greaterThanOrEqualTo(24));
    expect(cardFill.height, 12);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(find.text('Spent'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Next month'), findsNothing);
    expect(
      find.text('Rp 50.000 of Rp 300.000 (16.7%)', findRichText: true),
      findsWidgets,
    );
    final detailFill = tester.getSize(
      find.descendant(
        of: find.byKey(const Key('monthly-budget-detail-progress')),
        matching: find.byKey(const Key('flow-progress-fill')),
      ),
    );
    expect(detailFill.width, greaterThanOrEqualTo(24));
    expect(detailFill.height, 12);
  });

  testWidgets('budget delete uses destructive icon and confirmation sheet', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17);
    int? deletedBudgetId;
    const category = Category(
      id: 11,
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
    );
    final budget = MonthlyBudget(
      id: 41,
      categoryId: 11,
      month: DateTime(2026, 8),
      amount: 300000,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlansPage(
            section: PlansPageSection.monthlyBudgets,
            accounts: const [],
            categories: const [category],
            transactions: const [],
            recurringTemplates: const [],
            monthlyBudgets: [budget],
            savingsGoals: const [],
            currency: 'IDR',
            onSaveRecurringTemplate: (_) {},
            onDeleteRecurringTemplate: (_) {},
            onUseRecurringTemplate: (_) {},
            onSaveMonthlyBudget: (_) {},
            onDeleteMonthlyBudget: (id) => deletedBudgetId = id,
            onSaveSavingsGoal: (_) {},
            onDeleteSavingsGoal: (_) {},
          ),
        ),
      ),
    );

    final deleteButton = find.byTooltip('Delete budget');
    final deleteIcon = tester.widget<Icon>(
      find.descendant(
        of: deleteButton,
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    expect(
      deleteIcon.color,
      Theme.of(tester.element(deleteButton)).colorScheme.error,
    );
    final deleteRect = tester.getRect(deleteButton);
    final progressRect = tester.getRect(
      find.byKey(const Key('monthly-budget-card-progress')),
    );
    expect(deleteRect.right, progressRect.right);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(deletedBudgetId, isNull);
    expect(find.text('Delete budget?'), findsOneWidget);
    expect(
      find.textContaining('Existing transactions are not changed'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete budget'));
    await tester.pumpAndSettle();

    expect(deletedBudgetId, 41);
  });

  testWidgets('recurring card uses compact icon review action', (tester) async {
    final now = DateTime.utc(2026, 8, 17);
    var reviewCount = 0;
    final template = RecurringTemplate(
      id: 31,
      name: 'Internet bill',
      type: TransactionType.expense,
      amount: 350000,
      accountId: 7,
      categoryId: 11,
      frequency: RecurringFrequency.monthly,
      dayOfMonth: 10,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlansPage(
            section: PlansPageSection.recurringTemplates,
            accounts: [
              Account(
                id: 7,
                name: 'Cash',
                type: AccountType.cash,
                openingBalance: 0,
                icon: 'wallet',
                color: '#168C78',
                createdAt: now,
                updatedAt: now,
              ),
            ],
            categories: const [
              Category(
                id: 11,
                name: 'Bills',
                transactionType: TransactionType.expense,
                icon: 'receipt',
                color: '#C96B6B',
              ),
            ],
            transactions: const [],
            recurringTemplates: [template],
            monthlyBudgets: const [],
            savingsGoals: const [],
            currency: 'IDR',
            onSaveRecurringTemplate: (_) {},
            onDeleteRecurringTemplate: (_) {},
            onUseRecurringTemplate: (_) => reviewCount += 1,
            onSaveMonthlyBudget: (_) {},
            onDeleteMonthlyBudget: (_) {},
            onSaveSavingsGoal: (_) {},
            onDeleteSavingsGoal: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Review'), findsNothing);

    await tester.tap(find.byTooltip('Review transaction'));
    await tester.pumpAndSettle();

    expect(reviewCount, 1);
  });

  testWidgets('savings goal detail and contribution update manual amount', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 17);
    SavingsGoal? savedGoal;
    final goal = SavingsGoal(
      id: 51,
      name: 'Emergency fund',
      targetAmount: 1200000,
      accountId: 7,
      manualContribution: 250000,
      createdAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlansPage(
            section: PlansPageSection.savingsGoals,
            accounts: [
              Account(
                id: 7,
                name: 'Savings',
                type: AccountType.bank,
                openingBalance: 1000000,
                icon: 'bank',
                color: '#168C78',
                createdAt: now,
                updatedAt: now,
              ),
            ],
            categories: const [],
            transactions: const [],
            recurringTemplates: const [],
            monthlyBudgets: const [],
            savingsGoals: [goal],
            currency: 'IDR',
            onSaveRecurringTemplate: (_) {},
            onDeleteRecurringTemplate: (_) {},
            onUseRecurringTemplate: (_) {},
            onSaveMonthlyBudget: (_) {},
            onDeleteMonthlyBudget: (_) {},
            onSaveSavingsGoal: (value) => savedGoal = value,
            onDeleteSavingsGoal: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Emergency fund'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Savings (Rp 1.000.000)'), findsOneWidget);
    await tester.tap(find.text('Add contribution').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '50000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add contribution').last);
    await tester.pumpAndSettle();

    expect(savedGoal?.manualContribution, 300000);
  });
}

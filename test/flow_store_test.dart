import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

void main() {
  late Directory directory;
  late String databasePath;

  setUpAll(() {
    ffi.sqfliteFfiInit();
    ffi.databaseFactory = ffi.databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('flow_store_test_');
    databasePath =
        '${directory.path}${Platform.pathSeparator}flow_persistence.db';
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('SQLite store preserves core data after close and reopen', () async {
    final firstStore = await SqliteFlowStore.open(path: databasePath);
    final now = DateTime.utc(2026, 8, 9, 12);
    final account = await firstStore.saveAccount(
      Account(
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: 100000,
        icon: 'wallet',
        color: '#168C78',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final category = (await firstStore.load()).categories.first;
    final expenseCategory = (await firstStore.load())
        .categories
        .firstWhere((item) => item.transactionType == TransactionType.expense);
    final transaction = await firstStore.saveTransaction(
      Transaction(
        type: TransactionType.income,
        amount: 250000,
        accountId: account.id!,
        categoryId: category.id,
        note: 'Salary',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await firstStore.saveSettings(
      const AppSettings(
        currency: 'USD',
        themeMode: ThemeModeSetting.dark,
        hideBalance: true,
      ),
    );
    final template = await firstStore.saveRecurringTemplate(
      RecurringTemplate(
        name: 'Weekly groceries',
        type: TransactionType.expense,
        amount: 150000,
        accountId: account.id!,
        categoryId: expenseCategory.id,
        frequency: RecurringFrequency.weekly,
        weekday: 6,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final budget = await firstStore.saveMonthlyBudget(
      MonthlyBudget(
        categoryId: expenseCategory.id,
        month: DateTime(2026, 8),
        amount: 1200000,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final goal = await firstStore.saveSavingsGoal(
      SavingsGoal(
        name: 'Holiday',
        targetAmount: 10000000,
        accountId: account.id,
        manualContribution: 500000,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await firstStore.close();

    final reopenedStore = await SqliteFlowStore.open(path: databasePath);
    final snapshot = await reopenedStore.load();

    expect(snapshot.accounts.single.name, 'Cash');
    expect(snapshot.transactions.single.id, transaction.id);
    expect(snapshot.transactions.single.amount, 250000);
    expect(snapshot.settings.currency, 'USD');
    expect(snapshot.settings.themeMode, ThemeModeSetting.dark);
    expect(snapshot.settings.hideBalance, isTrue);
    expect(snapshot.recurringTemplates.single.id, template.id);
    expect(snapshot.monthlyBudgets.single.id, budget.id);
    expect(snapshot.savingsGoals.single.id, goal.id);

    await reopenedStore.deleteTransaction(transaction.id!);
    await reopenedStore.deleteRecurringTemplate(template.id!);
    await reopenedStore.deleteMonthlyBudget(budget.id!);
    await reopenedStore.deleteSavingsGoal(goal.id!);
    await reopenedStore.close();

    final afterDeleteStore = await SqliteFlowStore.open(path: databasePath);
    final afterDeleteSnapshot = await afterDeleteStore.load();
    expect(afterDeleteSnapshot.transactions, isEmpty);
    expect(afterDeleteSnapshot.recurringTemplates, isEmpty);
    expect(afterDeleteSnapshot.monthlyBudgets, isEmpty);
    expect(afterDeleteSnapshot.savingsGoals, isEmpty);
    await afterDeleteStore.close();
  });
}

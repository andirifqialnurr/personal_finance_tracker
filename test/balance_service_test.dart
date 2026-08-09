import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

void main() {
  late Directory directory;
  late FlowDatabase database;

  setUpAll(() {
    ffi.sqfliteFfiInit();
    ffi.databaseFactory = ffi.databaseFactoryFfi;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('flow_balance_test_');
    database = await FlowDatabase.open(
      path:
          '${directory.path}${Platform.pathSeparator}flow_balance.sqlite',
    );
  });

  tearDown(() async {
    await database.close();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test('income, expense, and transfer recalculate both account balances', () async {
    final accounts = AccountRepository(database);
    final transactions = TransactionRepository(database);
    final now = DateTime.utc(2026, 8, 9);
    final cashId = await accounts.create(
      Account(
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: 1000,
        icon: 'wallet',
        color: '#168C78',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final bankId = await accounts.create(
      Account(
        name: 'Bank',
        type: AccountType.bank,
        openingBalance: 500,
        icon: 'account_balance',
        color: '#168C78',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final incomeId = await transactions.create(
      Transaction(
        type: TransactionType.income,
        amount: 200,
        accountId: cashId,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await transactions.create(
      Transaction(
        type: TransactionType.expense,
        amount: 50,
        accountId: cashId,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final transferId = await transactions.create(
      Transaction(
        type: TransactionType.transfer,
        amount: 100,
        accountId: cashId,
        destinationAccountId: bankId,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final balanceService = AccountBalanceService(database);
    expect(await balanceService.calculateForAccount(cashId), 1050);
    expect(await balanceService.calculateForAccount(bankId), 600);

    final updatedIncome = (await transactions.findById(incomeId))!.copyWith(
      amount: 300,
      updatedAt: now.add(const Duration(minutes: 1)),
    );
    final afterUpdate = await transactions.updateAndRecalculate(updatedIncome);
    expect(afterUpdate[cashId], 1150);

    final afterDelete = await transactions.deleteAndRecalculate(transferId);
    expect(afterDelete[cashId], 1250);
    expect(afterDelete[bankId], 500);
  });
}

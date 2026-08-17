import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:personal_finance_tracker/state/state.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 13, 10);

  test('FlowController restores state from the configured store', () async {
    final store = MemoryFlowStore(
      accounts: [
        Account(
          id: 1,
          name: 'Cash',
          type: AccountType.cash,
          openingBalance: 100000,
          icon: 'wallet',
          color: '#168C78',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
      settings: const AppSettings(currency: 'USD'),
    );
    final container = ProviderContainer(
      overrides: [flowStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final state = await _readLoaded(container);

    expect(state.accounts.single.name, 'Cash');
    expect(state.currency, 'USD');
    expect(state.hasCompletedWelcome, isTrue);
  });

  test('FlowController persists basic settings changes', () async {
    final store = MemoryFlowStore();
    final container = ProviderContainer(
      overrides: [flowStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await _readLoaded(container);

    final controller = container.read(flowControllerProvider.notifier);
    await controller.changeCurrency('SGD');
    await controller.changeThemeMode(ThemeMode.dark);
    await controller.changeHideBalance(true);

    final snapshot = await store.load();
    expect(snapshot.settings.currency, 'SGD');
    expect(snapshot.settings.themeMode, ThemeModeSetting.dark);
    expect(snapshot.settings.hideBalance, isTrue);
  });

  test('FlowController saves and archives accounts', () async {
    final store = MemoryFlowStore();
    final container = ProviderContainer(
      overrides: [flowStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await _readLoaded(container);

    final controller = container.read(flowControllerProvider.notifier);
    await controller.saveAccount(
      Account(
        name: 'Bank',
        type: AccountType.bank,
        openingBalance: 250000,
        icon: 'account_balance',
        color: '#168C78',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    var state = container.read(flowControllerProvider).requireValue;
    expect(state.accounts.single.id, 1);
    expect(state.hasCompletedWelcome, isTrue);

    await controller.archiveAccount(state.accounts.single);

    state = container.read(flowControllerProvider).requireValue;
    expect(state.accounts.single.isArchived, isTrue);
    expect((await store.load()).accounts.single.isArchived, isTrue);

    await controller.restoreAccount(state.accounts.single);

    state = container.read(flowControllerProvider).requireValue;
    expect(state.accounts.single.isArchived, isFalse);
    expect((await store.load()).accounts.single.isArchived, isFalse);
  });

  test('FlowController saves, edits, and deletes transactions', () async {
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
      ],
    );
    final container = ProviderContainer(
      overrides: [flowStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await _readLoaded(container);

    final controller = container.read(flowControllerProvider.notifier);
    final transaction = Transaction(
      type: TransactionType.income,
      amount: 100000,
      accountId: 1,
      categoryId: 1,
      note: 'Salary',
      occurredAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await controller.saveTransaction(transaction);

    var state = container.read(flowControllerProvider).requireValue;
    expect(state.transactions.single.id, 1);
    expect(state.transactions.single.amount, 100000);

    await controller.saveTransaction(
      transaction.copyWith(amount: 150000),
      editing: state.transactions.single,
    );

    state = container.read(flowControllerProvider).requireValue;
    expect(state.transactions.single.amount, 150000);

    await controller.deleteTransaction(state.transactions.single.id!);

    state = container.read(flowControllerProvider).requireValue;
    expect(state.transactions, isEmpty);
    expect((await store.load()).transactions, isEmpty);
  });

  test('FlowController previews and imports CSV transactions', () async {
    final accounts = [
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
    ];
    final store = MemoryFlowStore(
      accounts: accounts,
    );
    final container = ProviderContainer(
      overrides: [flowStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await _readLoaded(container);

    final controller = container.read(flowControllerProvider.notifier);
    final csv = FlowCsvExporter.build(
      accounts: accounts,
      categories: MemoryFlowStore.defaultCategories(),
      transactions: [
        Transaction(
          type: TransactionType.income,
          amount: 250000,
          accountId: 1,
          categoryId: 1,
          note: 'Freelance',
          occurredAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
    );

    final preview = await controller.previewCsvImport(csv);
    expect(preview.readyCount, 1);
    expect(preview.errorCount, 0);

    final imported = await controller.importCsv(preview);

    final state = container.read(flowControllerProvider).requireValue;
    expect(imported, 1);
    expect(state.transactions.single.amount, 250000);
    expect(state.transactions.single.id, 1);
    expect((await store.load()).transactions.single.note, 'Freelance');
  });

  test('FlowController saves categories and deletes all data', () async {
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
      ],
      settings: const AppSettings(currency: 'USD'),
    );
    final container = ProviderContainer(
      overrides: [flowStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await _readLoaded(container);

    final controller = container.read(flowControllerProvider.notifier);
    await controller.saveCategory(
      const Category(
        name: 'Gift',
        transactionType: TransactionType.income,
        icon: 'card_giftcard',
        color: '#168C78',
      ),
    );

    var state = container.read(flowControllerProvider).requireValue;
    expect(
      state.categories.where((category) => category.name == 'Gift'),
      hasLength(1),
    );

    await controller.deleteAllData();

    state = container.read(flowControllerProvider).requireValue;
    expect(state.accounts, isEmpty);
    expect(state.transactions, isEmpty);
    expect(state.settings.currency, 'IDR');
    expect(state.hasCompletedWelcome, isFalse);
    expect(
      state.categories.map((category) => category.name),
      contains('Salary'),
    );
  });
}

Future<FlowState> _readLoaded(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    final state = container.read(flowControllerProvider);
    if (state.hasValue) return state.requireValue;
    if (state.hasError) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError('FlowController did not finish loading');
}

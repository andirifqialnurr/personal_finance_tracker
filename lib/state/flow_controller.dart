import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data.dart';
import 'flow_state.dart';

class FlowController extends StateNotifier<AsyncValue<FlowState>> {
  FlowController(this._store) : super(const AsyncValue.loading()) {
    unawaited(restore());
  }

  final FlowStore _store;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final snapshot = await _store.load();
      return FlowState.fromSnapshot(snapshot);
    });
  }

  Future<void> saveAccount(Account account) async {
    await _guardMutation(() async {
      final current = _currentState();
      final saved = await _store.saveAccount(account);
      final accounts = _replaceOrAdd<Account>(
        current.accounts,
        saved,
        (item) => item.id == saved.id,
      );
      state = AsyncValue.data(
        current.copyWith(accounts: accounts, hasCompletedWelcome: true),
      );
    });
  }

  Future<void> archiveAccount(Account account) async {
    final id = account.id;
    if (id == null) return;
    final archived = _copyAccount(
      account,
      id,
      isArchived: true,
      updatedAt: DateTime.now().toUtc(),
    );
    await saveAccount(archived);
  }

  Future<void> saveTransaction(
    Transaction transaction, {
    Transaction? editing,
  }) async {
    await _guardMutation(() async {
      final current = _currentState();
      final transactionToSave = editing == null
          ? transaction
          : transaction.copyWith(id: editing.id);
      final saved = await _store.saveTransaction(transactionToSave);
      final transactions = _replaceOrAdd<Transaction>(
        current.transactions,
        saved,
        (item) => item.id == saved.id,
      );
      state = AsyncValue.data(current.copyWith(transactions: transactions));
    });
  }

  Future<void> deleteTransaction(int id) async {
    await _guardMutation(() async {
      final current = _currentState();
      await _store.deleteTransaction(id);
      state = AsyncValue.data(
        current.copyWith(
          transactions: [
            for (final transaction in current.transactions)
              if (transaction.id != id) transaction,
          ],
        ),
      );
    });
  }

  Future<void> saveCategory(Category category) async {
    await _guardMutation(() async {
      final current = _currentState();
      final saved = await _store.saveCategory(category);
      final categories = _replaceOrAdd<Category>(
        current.categories,
        saved,
        (item) => item.id == saved.id,
      );
      state = AsyncValue.data(current.copyWith(categories: categories));
    });
  }

  Future<void> saveCategories(List<Category> categories) async {
    await _guardMutation(() async {
      final current = _currentState();
      final savedCategories = <Category>[];
      for (final category in categories) {
        savedCategories.add(await _store.saveCategory(category));
      }
      state = AsyncValue.data(
        current.copyWith(categories: List.unmodifiable(savedCategories)),
      );
    });
  }

  Future<void> changeHideBalance(bool value) async {
    await _saveSettings(
      (settings) => AppSettings(
        currency: settings.currency,
        themeMode: settings.themeMode,
        hideBalance: value,
      ),
    );
  }

  Future<void> changeThemeMode(ThemeMode mode) async {
    await _saveSettings(
      (settings) => AppSettings(
        currency: settings.currency,
        themeMode: _themeModeSetting(mode),
        hideBalance: settings.hideBalance,
      ),
    );
  }

  Future<void> changeCurrency(String currency) async {
    await _saveSettings(
      (settings) => AppSettings(
        currency: currency,
        themeMode: settings.themeMode,
        hideBalance: settings.hideBalance,
      ),
    );
  }

  Future<void> deleteAllData() async {
    await _guardMutation(() async {
      await _store.deleteAll();
      final snapshot = await _store.load();
      state = AsyncValue.data(
        FlowState.fromSnapshot(snapshot).copyWith(hasCompletedWelcome: false),
      );
    });
  }

  Future<String> exportCsv() async {
    final current = _currentState();
    final file = await FlowCsvExporter.write(
      transactions: current.transactions,
      accounts: current.accounts,
      categories: current.categories,
    );
    return file.path;
  }

  Future<void> closeStore() => _store.close();

  Future<void> _saveSettings(AppSettings Function(AppSettings) update) async {
    final current = _currentState();
    final nextSettings = update(current.settings);
    state = AsyncValue.data(current.copyWith(settings: nextSettings));
    try {
      await _store.saveSettings(nextSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> _guardMutation(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  FlowState _currentState() => state.value ?? FlowState.initial();

  @override
  void dispose() {
    unawaited(_store.close());
    super.dispose();
  }
}

ThemeModeSetting _themeModeSetting(ThemeMode mode) => switch (mode) {
  ThemeMode.dark => ThemeModeSetting.dark,
  ThemeMode.light || ThemeMode.system => ThemeModeSetting.light,
};

List<T> _replaceOrAdd<T>(
  List<T> items,
  T item,
  bool Function(T existing) matches,
) {
  final updated = List<T>.of(items);
  final index = updated.indexWhere(matches);
  if (index == -1) {
    updated.add(item);
  } else {
    updated[index] = item;
  }
  return List.unmodifiable(updated);
}

Account _copyAccount(
  Account account,
  int id, {
  bool? isArchived,
  DateTime? updatedAt,
}) {
  return Account(
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
}

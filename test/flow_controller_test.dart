import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:personal_finance_tracker/state/state.dart';

void main() {
  test('FlowController restores state from the configured store', () async {
    final timestamp = DateTime.utc(2026, 8, 13, 10);
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

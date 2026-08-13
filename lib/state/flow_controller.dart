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
      return FlowState.fromSnapshot(
        FlowSnapshotData(
          accounts: snapshot.accounts,
          categories: snapshot.categories,
          transactions: snapshot.transactions,
          settings: snapshot.settings,
        ),
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

  Future<void> _saveSettings(AppSettings Function(AppSettings) update) async {
    final current = state.value ?? FlowState.initial();
    final nextSettings = update(current.settings);
    state = AsyncValue.data(current.copyWith(settings: nextSettings));
    try {
      await _store.saveSettings(nextSettings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

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

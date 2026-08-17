import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data.dart';
import 'flow_controller.dart';
import 'flow_state.dart';

final flowStoreProvider = Provider<FlowStore>((ref) => MemoryFlowStore());

final flowControllerProvider =
    StateNotifierProvider<FlowController, AsyncValue<FlowState>>((ref) {
      return FlowController(ref.watch(flowStoreProvider));
    });

final flowStateProvider = Provider<FlowState?>((ref) {
  return ref.watch(flowControllerProvider).value;
});

final accountsProvider = Provider<List<Account>>((ref) {
  return ref.watch(flowStateProvider)?.accounts ?? const [];
});

final transactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(flowStateProvider)?.transactions ?? const [];
});

final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(flowStateProvider)?.categories ?? const [];
});

final settingsProvider = Provider<AppSettings>((ref) {
  return ref.watch(flowStateProvider)?.settings ?? const AppSettings();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(flowStateProvider)?.themeMode ?? ThemeMode.light;
});

final hideBalanceProvider = Provider<bool>((ref) {
  return ref.watch(flowStateProvider)?.hideBalance ?? false;
});

final currencyProvider = Provider<String>((ref) {
  return ref.watch(flowStateProvider)?.currency ?? 'IDR';
});

final recurringTemplatesProvider = Provider<List<RecurringTemplate>>((ref) {
  return ref.watch(flowStateProvider)?.recurringTemplates ?? const [];
});

final monthlyBudgetsProvider = Provider<List<MonthlyBudget>>((ref) {
  return ref.watch(flowStateProvider)?.monthlyBudgets ?? const [];
});

final savingsGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  return ref.watch(flowStateProvider)?.savingsGoals ?? const [];
});

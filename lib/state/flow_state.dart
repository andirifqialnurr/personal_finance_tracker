import 'package:flutter/material.dart';

import '../data/flow_store.dart';
import '../data/models/models.dart';

class FlowState {
  const FlowState({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.settings,
    required this.hasCompletedWelcome,
    this.recurringTemplates = const [],
    this.monthlyBudgets = const [],
    this.savingsGoals = const [],
  });

  factory FlowState.initial() => const FlowState(
    accounts: [],
    categories: [],
    transactions: [],
    settings: AppSettings(),
    hasCompletedWelcome: false,
    recurringTemplates: [],
    monthlyBudgets: [],
    savingsGoals: [],
  );

  factory FlowState.fromSnapshot(FlowSnapshot snapshot) => FlowState(
    accounts: List.unmodifiable(snapshot.accounts),
    categories: List.unmodifiable(snapshot.categories),
    transactions: List.unmodifiable(snapshot.transactions),
    settings: snapshot.settings,
    hasCompletedWelcome: snapshot.accounts.isNotEmpty,
    recurringTemplates: List.unmodifiable(snapshot.recurringTemplates),
    monthlyBudgets: List.unmodifiable(snapshot.monthlyBudgets),
    savingsGoals: List.unmodifiable(snapshot.savingsGoals),
  );

  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final AppSettings settings;
  final bool hasCompletedWelcome;
  final List<RecurringTemplate> recurringTemplates;
  final List<MonthlyBudget> monthlyBudgets;
  final List<SavingsGoal> savingsGoals;

  String get currency => settings.currency;

  ThemeMode get themeMode => switch (settings.themeMode) {
    ThemeModeSetting.dark => ThemeMode.dark,
    ThemeModeSetting.light || ThemeModeSetting.system => ThemeMode.light,
  };

  bool get hideBalance => settings.hideBalance;

  List<Account> get activeAccounts =>
      List.unmodifiable(accounts.where((account) => !account.isArchived));

  bool get hasAccounts => accounts.isNotEmpty;

  FlowState copyWith({
    List<Account>? accounts,
    List<Category>? categories,
    List<Transaction>? transactions,
    AppSettings? settings,
    bool? hasCompletedWelcome,
    List<RecurringTemplate>? recurringTemplates,
    List<MonthlyBudget>? monthlyBudgets,
    List<SavingsGoal>? savingsGoals,
  }) {
    return FlowState(
      accounts: List.unmodifiable(accounts ?? this.accounts),
      categories: List.unmodifiable(categories ?? this.categories),
      transactions: List.unmodifiable(transactions ?? this.transactions),
      settings: settings ?? this.settings,
      hasCompletedWelcome: hasCompletedWelcome ?? this.hasCompletedWelcome,
      recurringTemplates: List.unmodifiable(
        recurringTemplates ?? this.recurringTemplates,
      ),
      monthlyBudgets: List.unmodifiable(monthlyBudgets ?? this.monthlyBudgets),
      savingsGoals: List.unmodifiable(savingsGoals ?? this.savingsGoals),
    );
  }
}

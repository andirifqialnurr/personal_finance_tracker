import 'package:flutter/material.dart';

import '../data/models/models.dart';

class FlowState {
  const FlowState({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.settings,
    required this.hasCompletedWelcome,
  });

  factory FlowState.initial() => const FlowState(
    accounts: [],
    categories: [],
    transactions: [],
    settings: AppSettings(),
    hasCompletedWelcome: false,
  );

  factory FlowState.fromSnapshot(FlowSnapshotData snapshot) => FlowState(
    accounts: List.unmodifiable(snapshot.accounts),
    categories: List.unmodifiable(snapshot.categories),
    transactions: List.unmodifiable(snapshot.transactions),
    settings: snapshot.settings,
    hasCompletedWelcome: snapshot.accounts.isNotEmpty,
  );

  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final AppSettings settings;
  final bool hasCompletedWelcome;

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
  }) {
    return FlowState(
      accounts: List.unmodifiable(accounts ?? this.accounts),
      categories: List.unmodifiable(categories ?? this.categories),
      transactions: List.unmodifiable(transactions ?? this.transactions),
      settings: settings ?? this.settings,
      hasCompletedWelcome: hasCompletedWelcome ?? this.hasCompletedWelcome,
    );
  }
}

class FlowSnapshotData {
  const FlowSnapshotData({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.settings,
  });

  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final AppSettings settings;
}

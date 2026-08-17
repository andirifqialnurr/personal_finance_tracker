import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'flow_store.dart';
import 'models/models.dart';

class FlowBackupPreview {
  const FlowBackupPreview({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.recurringTemplates,
    required this.monthlyBudgets,
    required this.savingsGoals,
    required this.currency,
  });

  final int accounts;
  final int categories;
  final int transactions;
  final int recurringTemplates;
  final int monthlyBudgets;
  final int savingsGoals;
  final String currency;
}

class FlowBackupCodec {
  const FlowBackupCodec._();

  static Future<File> write(FlowSnapshot snapshot) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${directory.path}/flow-backup-$timestamp.json');
    await file.writeAsString(encode(snapshot), flush: true);
    return file;
  }

  static String encode(FlowSnapshot snapshot) {
    return const JsonEncoder.withIndent('  ').convert({
      'schema': 'flow.local-backup',
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'accounts': [for (final item in snapshot.accounts) item.toMap()],
      'categories': [for (final item in snapshot.categories) item.toMap()],
      'transactions': [
        for (final item in snapshot.transactions) item.toMap(),
      ],
      'settings': snapshot.settings.toMap(),
      'recurring_templates': [
        for (final item in snapshot.recurringTemplates) item.toMap(),
      ],
      'monthly_budgets': [
        for (final item in snapshot.monthlyBudgets) item.toMap(),
      ],
      'savings_goals': [for (final item in snapshot.savingsGoals) item.toMap()],
    });
  }

  static FlowBackupPreview preview(String json) {
    final snapshot = decode(json);
    return FlowBackupPreview(
      accounts: snapshot.accounts.length,
      categories: snapshot.categories.length,
      transactions: snapshot.transactions.length,
      recurringTemplates: snapshot.recurringTemplates.length,
      monthlyBudgets: snapshot.monthlyBudgets.length,
      savingsGoals: snapshot.savingsGoals.length,
      currency: snapshot.settings.currency,
    );
  }

  static FlowSnapshot decode(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, Object?> ||
        decoded['schema'] != 'flow.local-backup') {
      throw const FormatException('Unsupported Flow backup file');
    }
    if (decoded['version'] != 1) {
      throw const FormatException('Unsupported Flow backup version');
    }
    return FlowSnapshot(
      accounts: _list(decoded, 'accounts', Account.fromMap),
      categories: _list(decoded, 'categories', Category.fromMap),
      transactions: _list(decoded, 'transactions', Transaction.fromMap),
      settings: AppSettings.fromMap(_map(decoded, 'settings')),
      recurringTemplates: _list(
        decoded,
        'recurring_templates',
        RecurringTemplate.fromMap,
      ),
      monthlyBudgets: _list(decoded, 'monthly_budgets', MonthlyBudget.fromMap),
      savingsGoals: _list(decoded, 'savings_goals', SavingsGoal.fromMap),
    );
  }

  static Map<String, Object?> _map(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw FormatException('Missing $key');
  }

  static List<T> _list<T>(
    Map<String, Object?> source,
    String key,
    T Function(Map<String, Object?> map) parse,
  ) {
    final value = source[key];
    if (value is! List) throw FormatException('Missing $key');
    return [
      for (final item in value)
        parse(item is Map<String, Object?> ? item : Map.from(item as Map)),
    ];
  }
}

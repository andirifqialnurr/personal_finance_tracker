import 'package:sqflite/sqflite.dart' hide Transaction;

import 'flow_database.dart';
import 'models/models.dart';

class AccountRepository {
  AccountRepository(this._database);
  final FlowDatabase _database;

  Future<int> create(Account account) =>
      _database.database.insert('accounts', account.toMap());

  Future<Account?> findById(int id) async {
    final rows = await _database.database.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Account.fromMap(rows.first);
  }

  Future<List<Account>> list({bool includeArchived = false}) async {
    final rows = await _database.database.query(
      'accounts',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Account.fromMap).toList(growable: false);
  }

  Future<int> update(Account account) async {
    final id = _id(account.id, 'account');
    return _database.database.update(
      'accounts',
      account.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) =>
      _database.database.delete('accounts', where: 'id = ?', whereArgs: [id]);
}

class CategoryRepository {
  CategoryRepository(this._database);
  final FlowDatabase _database;

  Future<int> create(Category category) =>
      _database.database.insert('categories', category.toMap());

  Future<Category?> findById(int id) async {
    final rows = await _database.database.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Category.fromMap(rows.first);
  }

  Future<List<Category>> list({
    bool includeArchived = false,
    TransactionType? type,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (!includeArchived) clauses.add('is_archived = 0');
    if (type != null) {
      clauses.add('transaction_type = ?');
      args.add(type.name);
    }
    final rows = await _database.database.query(
      'categories',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'is_default DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromMap).toList(growable: false);
  }

  Future<int> update(Category category) async {
    final id = _id(category.id, 'category');
    return _database.database.update(
      'categories',
      category.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) =>
      _database.database.delete('categories', where: 'id = ?', whereArgs: [id]);
}

class TransactionRepository {
  TransactionRepository(this._database);
  final FlowDatabase _database;

  Future<int> create(Transaction transaction) =>
      _database.database.insert('transactions', transaction.toMap());

  Future<Transaction?> findById(int id) async {
    final rows = await _database.database.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Transaction.fromMap(rows.first);
  }

  Future<List<Transaction>> list({
    int? accountId,
    TransactionType? type,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (accountId != null) {
      clauses.add('(account_id = ? OR destination_account_id = ?)');
      args.addAll([accountId, accountId]);
    }
    if (type != null) {
      clauses.add('type = ?');
      args.add(type.name);
    }
    final rows = await _database.database.query(
      'transactions',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'occurred_at DESC, id DESC',
    );
    return rows.map(Transaction.fromMap).toList(growable: false);
  }

  Future<int> update(Transaction transaction) async {
    final id = _id(transaction.id, 'transaction');
    return _database.database.update(
      'transactions',
      transaction.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) => _database.database.delete(
    'transactions',
    where: 'id = ?',
    whereArgs: [id],
  );
}

class SettingsRepository {
  SettingsRepository(this._database);
  final FlowDatabase _database;

  Future<AppSettings> get() async {
    final rows = await _database.database.query(
      'app_settings',
      where: 'id = 1',
      limit: 1,
    );
    return rows.isEmpty ? const AppSettings() : AppSettings.fromMap(rows.first);
  }

  Future<void> save(AppSettings settings) async {
    await _database.database.insert(
      'app_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

int _id(int? id, String entity) {
  if (id == null) throw StateError('Cannot update $entity without an id');
  return id;
}

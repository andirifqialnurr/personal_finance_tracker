import 'package:sqflite/sqflite.dart';

class FlowDatabase {
  FlowDatabase._(this._database);

  static const version = 1;
  final Database _database;

  Database get database => _database;

  static Future<FlowDatabase> open({String? path}) async {
    final databasePath = path ?? '${await getDatabasesPath()}/flow.db';
    final database = await openDatabase(
      databasePath,
      version: version,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async => _createSchema(database),
      onUpgrade: (database, oldVersion, newVersion) async {
        for (
          var migration = oldVersion + 1;
          migration <= newVersion;
          migration++
        ) {
          await _migrations[migration]?.call(database);
        }
      },
    );
    return FlowDatabase._(database);
  }

  Future<void> close() => _database.close();

  static final Map<int, Future<void> Function(Database)> _migrations = {
    1: _createSchema,
  };

  static Future<void> _createSchema(Database database) async {
    await database.transaction((transaction) async {
      await transaction.execute('''
        CREATE TABLE accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          opening_balance INTEGER NOT NULL DEFAULT 0,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          is_archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await transaction.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          transaction_type TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          is_archived INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await transaction.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          amount INTEGER NOT NULL CHECK (amount >= 0),
          account_id INTEGER NOT NULL,
          destination_account_id INTEGER,
          category_id INTEGER,
          note TEXT,
          occurred_at TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
          FOREIGN KEY (destination_account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
          FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
        )
      ''');
      await transaction.execute('''
        CREATE TABLE app_settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          currency TEXT NOT NULL,
          theme_mode TEXT NOT NULL,
          hide_balance INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await transaction.insert('app_settings', const {
        'id': 1,
        'currency': 'IDR',
        'theme_mode': 'system',
        'hide_balance': 0,
      });
      await transaction.execute(
        'CREATE INDEX transactions_occurred_at_idx ON transactions(occurred_at)',
      );
      await transaction.execute(
        'CREATE INDEX transactions_account_id_idx ON transactions(account_id)',
      );
      await transaction.execute(
        'CREATE INDEX transactions_category_id_idx ON transactions(category_id)',
      );
    });
  }
}

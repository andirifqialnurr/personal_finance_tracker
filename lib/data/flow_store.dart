import 'default_category_seeder.dart';
import 'flow_database.dart';
import 'flow_repositories.dart';
import 'models/models.dart';

class FlowSnapshot {
  const FlowSnapshot({
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

abstract interface class FlowStore {
  Future<FlowSnapshot> load();

  Future<Account> saveAccount(Account account);

  Future<Category> saveCategory(Category category);

  Future<Transaction> saveTransaction(Transaction transaction);

  Future<void> deleteTransaction(int id);

  Future<void> deleteAll();

  Future<void> saveSettings(AppSettings settings);

  Future<void> close();
}

/// A small store used by widget tests and unsupported desktop targets.
/// Production mobile builds use [SqliteFlowStore] from main.dart.
class MemoryFlowStore implements FlowStore {
  static List<Category> defaultCategories() => _defaultCategories();

  MemoryFlowStore({
    List<Account>? accounts,
    List<Category>? categories,
    List<Transaction>? transactions,
    AppSettings settings = const AppSettings(),
  }) : _accounts = List.of(accounts ?? const []),
       _categories = List.of(categories ?? _defaultCategories()),
       _transactions = List.of(transactions ?? const []),
       _settings = settings;

  final List<Account> _accounts;
  final List<Category> _categories;
  final List<Transaction> _transactions;
  AppSettings _settings;

  @override
  Future<FlowSnapshot> load() async => FlowSnapshot(
    accounts: List.unmodifiable(_accounts),
    categories: List.unmodifiable(_categories),
    transactions: List.unmodifiable(_transactions),
    settings: _settings,
  );

  @override
  Future<Account> saveAccount(Account account) async {
    final saved = account.id == null
        ? _copyAccount(account, _nextId(_accounts.map((item) => item.id)))
        : account;
    _replaceOrAdd(_accounts, saved, (item) => item.id == saved.id);
    return saved;
  }

  @override
  Future<Category> saveCategory(Category category) async {
    final saved = category.id == null
        ? _copyCategory(category, _nextId(_categories.map((item) => item.id)))
        : category;
    _replaceOrAdd(_categories, saved, (item) => item.id == saved.id);
    return saved;
  }

  @override
  Future<Transaction> saveTransaction(Transaction transaction) async {
    final saved = transaction.id == null
        ? _copyTransaction(
            transaction,
            _nextId(_transactions.map((item) => item.id)),
          )
        : transaction;
    _replaceOrAdd(_transactions, saved, (item) => item.id == saved.id);
    return saved;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
  }

  @override
  Future<void> deleteAll() async {
    _accounts.clear();
    _categories
      ..clear()
      ..addAll(_defaultCategories());
    _transactions.clear();
    _settings = const AppSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> close() async {}

  static List<Category> _defaultCategories() => [
    for (var index = 0; index < DefaultCategorySeeder.defaults.length; index++)
      _copyCategory(DefaultCategorySeeder.defaults[index], index + 1),
  ];
}

class SqliteFlowStore implements FlowStore {
  SqliteFlowStore._(this._database)
    : _accounts = AccountRepository(_database),
      _categories = CategoryRepository(_database),
      _transactions = TransactionRepository(_database),
      _settings = SettingsRepository(_database);

  final FlowDatabase _database;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final SettingsRepository _settings;

  static Future<SqliteFlowStore> open({String? path}) async {
    return SqliteFlowStore._(await FlowDatabase.open(path: path));
  }

  @override
  Future<FlowSnapshot> load() async => FlowSnapshot(
    accounts: await _accounts.list(includeArchived: true),
    categories: await _categories.list(includeArchived: true),
    transactions: await _transactions.list(),
    settings: await _settings.get(),
  );

  @override
  Future<Account> saveAccount(Account account) async {
    final id = account.id;
    if (id == null) {
      final createdId = await _accounts.create(account);
      return (await _accounts.findById(createdId))!;
    }
    if (await _accounts.findById(id) == null) {
      await _accounts.create(account);
    } else {
      await _accounts.update(account);
    }
    return (await _accounts.findById(id))!;
  }

  @override
  Future<Category> saveCategory(Category category) async {
    final id = category.id;
    if (id == null) {
      final createdId = await _categories.create(category);
      return (await _categories.findById(createdId))!;
    }
    if (await _categories.findById(id) == null) {
      await _categories.create(category);
    } else {
      await _categories.update(category);
    }
    return (await _categories.findById(id))!;
  }

  @override
  Future<Transaction> saveTransaction(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      final createdId = await _transactions.create(transaction);
      return (await _transactions.findById(createdId))!;
    }
    if (await _transactions.findById(id) == null) {
      await _transactions.create(transaction);
    } else {
      await _transactions.update(transaction);
    }
    return (await _transactions.findById(id))!;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _transactions.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _database.database.transaction((transaction) async {
      await transaction.delete('transactions');
      await transaction.delete('categories');
      await transaction.delete('accounts');
      await transaction.delete('app_settings');
      await transaction.insert('app_settings', const {
        'id': 1,
        'currency': 'IDR',
        'theme_mode': 'light',
        'hide_balance': 0,
      });
      for (final category in DefaultCategorySeeder.defaults) {
        await transaction.insert('categories', category.toMap());
      }
    });
  }

  @override
  Future<void> saveSettings(AppSettings settings) => _settings.save(settings);

  @override
  Future<void> close() => _database.close();
}

void _replaceOrAdd<T>(
  List<T> items,
  T item,
  bool Function(T existing) matches,
) {
  final index = items.indexWhere(matches);
  if (index == -1) {
    items.add(item);
  } else {
    items[index] = item;
  }
}

int _nextId(Iterable<int?> ids) {
  var maxId = 0;
  for (final id in ids) {
    if (id != null && id > maxId) maxId = id;
  }
  return maxId + 1;
}

Account _copyAccount(Account account, int id) => Account(
  id: id,
  name: account.name,
  type: account.type,
  openingBalance: account.openingBalance,
  icon: account.icon,
  color: account.color,
  isArchived: account.isArchived,
  createdAt: account.createdAt,
  updatedAt: account.updatedAt,
);

Category _copyCategory(Category category, int id) => Category(
  id: id,
  name: category.name,
  transactionType: category.transactionType,
  icon: category.icon,
  color: category.color,
  isDefault: category.isDefault,
  isArchived: category.isArchived,
);

Transaction _copyTransaction(Transaction transaction, int id) => Transaction(
  id: id,
  type: transaction.type,
  amount: transaction.amount,
  accountId: transaction.accountId,
  destinationAccountId: transaction.destinationAccountId,
  categoryId: transaction.categoryId,
  note: transaction.note,
  occurredAt: transaction.occurredAt,
  createdAt: transaction.createdAt,
  updatedAt: transaction.updatedAt,
);

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
    this.recurringTemplates = const [],
    this.monthlyBudgets = const [],
    this.savingsGoals = const [],
  });

  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final AppSettings settings;
  final List<RecurringTemplate> recurringTemplates;
  final List<MonthlyBudget> monthlyBudgets;
  final List<SavingsGoal> savingsGoals;
}

abstract interface class FlowStore {
  Future<FlowSnapshot> load();

  Future<Account> saveAccount(Account account);

  Future<Category> saveCategory(Category category);

  Future<Transaction> saveTransaction(Transaction transaction);

  Future<void> deleteTransaction(int id);

  Future<void> deleteAll();

  Future<void> saveSettings(AppSettings settings);

  Future<RecurringTemplate> saveRecurringTemplate(
    RecurringTemplate template,
  );

  Future<void> deleteRecurringTemplate(int id);

  Future<MonthlyBudget> saveMonthlyBudget(MonthlyBudget budget);

  Future<void> deleteMonthlyBudget(int id);

  Future<SavingsGoal> saveSavingsGoal(SavingsGoal goal);

  Future<void> deleteSavingsGoal(int id);

  Future<void> replaceSnapshot(FlowSnapshot snapshot);

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
    List<RecurringTemplate>? recurringTemplates,
    List<MonthlyBudget>? monthlyBudgets,
    List<SavingsGoal>? savingsGoals,
  }) : _accounts = List.of(accounts ?? const []),
       _categories = List.of(categories ?? _defaultCategories()),
       _transactions = List.of(transactions ?? const []),
       _recurringTemplates = List.of(recurringTemplates ?? const []),
       _monthlyBudgets = List.of(monthlyBudgets ?? const []),
       _savingsGoals = List.of(savingsGoals ?? const []),
       _settings = settings;

  final List<Account> _accounts;
  final List<Category> _categories;
  final List<Transaction> _transactions;
  final List<RecurringTemplate> _recurringTemplates;
  final List<MonthlyBudget> _monthlyBudgets;
  final List<SavingsGoal> _savingsGoals;
  AppSettings _settings;

  @override
  Future<FlowSnapshot> load() async => FlowSnapshot(
    accounts: List.unmodifiable(_accounts),
    categories: List.unmodifiable(_categories),
    transactions: List.unmodifiable(_transactions),
    settings: _settings,
    recurringTemplates: List.unmodifiable(_recurringTemplates),
    monthlyBudgets: List.unmodifiable(_monthlyBudgets),
    savingsGoals: List.unmodifiable(_savingsGoals),
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
    _recurringTemplates.clear();
    _monthlyBudgets.clear();
    _savingsGoals.clear();
    _settings = const AppSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }

  @override
  Future<RecurringTemplate> saveRecurringTemplate(
    RecurringTemplate template,
  ) async {
    final saved = template.id == null
        ? _copyRecurringTemplate(
            template,
            _nextId(_recurringTemplates.map((item) => item.id)),
          )
        : template;
    _replaceOrAdd(_recurringTemplates, saved, (item) => item.id == saved.id);
    return saved;
  }

  @override
  Future<void> deleteRecurringTemplate(int id) async {
    _recurringTemplates.removeWhere((template) => template.id == id);
  }

  @override
  Future<MonthlyBudget> saveMonthlyBudget(MonthlyBudget budget) async {
    final saved = budget.id == null
        ? _copyMonthlyBudget(
            budget,
            _nextId(_monthlyBudgets.map((item) => item.id)),
          )
        : budget;
    _replaceOrAdd(_monthlyBudgets, saved, (item) => item.id == saved.id);
    return saved;
  }

  @override
  Future<void> deleteMonthlyBudget(int id) async {
    _monthlyBudgets.removeWhere((budget) => budget.id == id);
  }

  @override
  Future<SavingsGoal> saveSavingsGoal(SavingsGoal goal) async {
    final saved = goal.id == null
        ? _copySavingsGoal(goal, _nextId(_savingsGoals.map((item) => item.id)))
        : goal;
    _replaceOrAdd(_savingsGoals, saved, (item) => item.id == saved.id);
    return saved;
  }

  @override
  Future<void> deleteSavingsGoal(int id) async {
    _savingsGoals.removeWhere((goal) => goal.id == id);
  }

  @override
  Future<void> replaceSnapshot(FlowSnapshot snapshot) async {
    _accounts
      ..clear()
      ..addAll(snapshot.accounts);
    _categories
      ..clear()
      ..addAll(snapshot.categories);
    _transactions
      ..clear()
      ..addAll(snapshot.transactions);
    _recurringTemplates
      ..clear()
      ..addAll(snapshot.recurringTemplates);
    _monthlyBudgets
      ..clear()
      ..addAll(snapshot.monthlyBudgets);
    _savingsGoals
      ..clear()
      ..addAll(snapshot.savingsGoals);
    _settings = snapshot.settings;
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
      _settings = SettingsRepository(_database),
      _recurringTemplates = RecurringTemplateRepository(_database),
      _monthlyBudgets = MonthlyBudgetRepository(_database),
      _savingsGoals = SavingsGoalRepository(_database);

  final FlowDatabase _database;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final SettingsRepository _settings;
  final RecurringTemplateRepository _recurringTemplates;
  final MonthlyBudgetRepository _monthlyBudgets;
  final SavingsGoalRepository _savingsGoals;

  static Future<SqliteFlowStore> open({String? path}) async {
    return SqliteFlowStore._(await FlowDatabase.open(path: path));
  }

  @override
  Future<FlowSnapshot> load() async => FlowSnapshot(
    accounts: await _accounts.list(includeArchived: true),
    categories: await _categories.list(includeArchived: true),
    transactions: await _transactions.list(),
    settings: await _settings.get(),
    recurringTemplates: await _recurringTemplates.list(includeArchived: true),
    monthlyBudgets: await _monthlyBudgets.list(),
    savingsGoals: await _savingsGoals.list(includeArchived: true),
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
      await transaction.delete('recurring_templates');
      await transaction.delete('monthly_budgets');
      await transaction.delete('savings_goals');
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
  Future<RecurringTemplate> saveRecurringTemplate(
    RecurringTemplate template,
  ) async {
    final id = template.id;
    if (id == null) {
      final createdId = await _recurringTemplates.create(template);
      return (await _recurringTemplates.findById(createdId))!;
    }
    if (await _recurringTemplates.findById(id) == null) {
      await _recurringTemplates.create(template);
    } else {
      await _recurringTemplates.update(template);
    }
    return (await _recurringTemplates.findById(id))!;
  }

  @override
  Future<void> deleteRecurringTemplate(int id) =>
      _recurringTemplates.delete(id);

  @override
  Future<MonthlyBudget> saveMonthlyBudget(MonthlyBudget budget) async {
    final id = budget.id;
    if (id == null) {
      final createdId = await _monthlyBudgets.create(budget);
      return (await _monthlyBudgets.findById(createdId))!;
    }
    if (await _monthlyBudgets.findById(id) == null) {
      await _monthlyBudgets.create(budget);
    } else {
      await _monthlyBudgets.update(budget);
    }
    return (await _monthlyBudgets.findById(id))!;
  }

  @override
  Future<void> deleteMonthlyBudget(int id) => _monthlyBudgets.delete(id);

  @override
  Future<SavingsGoal> saveSavingsGoal(SavingsGoal goal) async {
    final id = goal.id;
    if (id == null) {
      final createdId = await _savingsGoals.create(goal);
      return (await _savingsGoals.findById(createdId))!;
    }
    if (await _savingsGoals.findById(id) == null) {
      await _savingsGoals.create(goal);
    } else {
      await _savingsGoals.update(goal);
    }
    return (await _savingsGoals.findById(id))!;
  }

  @override
  Future<void> deleteSavingsGoal(int id) => _savingsGoals.delete(id);

  @override
  Future<void> replaceSnapshot(FlowSnapshot snapshot) async {
    await _database.database.transaction((transaction) async {
      await transaction.delete('transactions');
      await transaction.delete('recurring_templates');
      await transaction.delete('monthly_budgets');
      await transaction.delete('savings_goals');
      await transaction.delete('categories');
      await transaction.delete('accounts');
      await transaction.delete('app_settings');
      for (final account in snapshot.accounts) {
        await transaction.insert('accounts', account.toMap());
      }
      for (final category in snapshot.categories) {
        await transaction.insert('categories', category.toMap());
      }
      for (final item in snapshot.transactions) {
        await transaction.insert('transactions', item.toMap());
      }
      await transaction.insert('app_settings', snapshot.settings.toMap());
      for (final item in snapshot.recurringTemplates) {
        await transaction.insert('recurring_templates', item.toMap());
      }
      for (final item in snapshot.monthlyBudgets) {
        await transaction.insert('monthly_budgets', item.toMap());
      }
      for (final item in snapshot.savingsGoals) {
        await transaction.insert('savings_goals', item.toMap());
      }
    });
  }

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

RecurringTemplate _copyRecurringTemplate(
  RecurringTemplate template,
  int id,
) => RecurringTemplate(
  id: id,
  name: template.name,
  type: template.type,
  amount: template.amount,
  accountId: template.accountId,
  destinationAccountId: template.destinationAccountId,
  categoryId: template.categoryId,
  note: template.note,
  frequency: template.frequency,
  dayOfMonth: template.dayOfMonth,
  weekday: template.weekday,
  isArchived: template.isArchived,
  createdAt: template.createdAt,
  updatedAt: template.updatedAt,
);

MonthlyBudget _copyMonthlyBudget(MonthlyBudget budget, int id) =>
    MonthlyBudget(
      id: id,
      categoryId: budget.categoryId,
      month: budget.month,
      amount: budget.amount,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
    );

SavingsGoal _copySavingsGoal(SavingsGoal goal, int id) => SavingsGoal(
  id: id,
  name: goal.name,
  targetAmount: goal.targetAmount,
  accountId: goal.accountId,
  manualContribution: goal.manualContribution,
  isArchived: goal.isArchived,
  createdAt: goal.createdAt,
  updatedAt: goal.updatedAt,
);

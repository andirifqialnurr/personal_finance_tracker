import 'category.dart';

enum RecurringFrequency { weekly, monthly }

class RecurringTemplate {
  const RecurringTemplate({
    this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.note,
    required this.frequency,
    this.dayOfMonth,
    this.weekday,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final TransactionType type;
  final int amount;
  final int accountId;
  final int? destinationAccountId;
  final int? categoryId;
  final String? note;
  final RecurringFrequency frequency;
  final int? dayOfMonth;
  final int? weekday;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionType get transactionType => type;

  factory RecurringTemplate.fromMap(Map<String, Object?> map) =>
      RecurringTemplate(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: TransactionType.values.byName(map['transaction_type'] as String),
        amount: map['amount'] as int,
        accountId: map['account_id'] as int,
        destinationAccountId: map['destination_account_id'] as int?,
        categoryId: map['category_id'] as int?,
        note: map['note'] as String?,
        frequency: RecurringFrequency.values.byName(
          map['frequency'] as String,
        ),
        dayOfMonth: map['day_of_month'] as int?,
        weekday: map['weekday'] as int?,
        isArchived: (map['is_archived'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'transaction_type': type.name,
    'amount': amount,
    'account_id': accountId,
    'destination_account_id': destinationAccountId,
    'category_id': categoryId,
    'note': note,
    'frequency': frequency.name,
    'day_of_month': dayOfMonth,
    'weekday': weekday,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

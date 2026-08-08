import 'category.dart';

class Transaction {
  const Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.accountId,
    this.destinationAccountId,
    this.categoryId,
    this.note,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final TransactionType type;
  final int amount;
  final int accountId;
  final int? destinationAccountId;
  final int? categoryId;
  final String? note;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction copyWith({
    int? id,
    TransactionType? type,
    int? amount,
    int? accountId,
    int? destinationAccountId,
    int? categoryId,
    String? note,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Transaction(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    accountId: accountId ?? this.accountId,
    destinationAccountId: destinationAccountId ?? this.destinationAccountId,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Transaction.fromMap(Map<String, Object?> map) => Transaction(
    id: map['id'] as int?,
    type: TransactionType.values.byName(map['type'] as String),
    amount: map['amount'] as int,
    accountId: map['account_id'] as int,
    destinationAccountId: map['destination_account_id'] as int?,
    categoryId: map['category_id'] as int?,
    note: map['note'] as String?,
    occurredAt: DateTime.parse(map['occurred_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.name,
    'amount': amount,
    'account_id': accountId,
    'destination_account_id': destinationAccountId,
    'category_id': categoryId,
    'note': note,
    'occurred_at': occurredAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

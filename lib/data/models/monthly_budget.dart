class MonthlyBudget {
  const MonthlyBudget({
    this.id,
    required this.categoryId,
    required this.month,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int? categoryId;
  final DateTime month;
  final int amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MonthlyBudget.fromMap(Map<String, Object?> map) {
    final parts = (map['month'] as String).split('-');
    return MonthlyBudget(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      month: DateTime(int.parse(parts[0]), int.parse(parts[1])),
      amount: map['amount'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'category_id': categoryId,
    'month': '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}',
    'amount': amount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class SavingsGoal {
  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.accountId,
    this.manualContribution = 0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int targetAmount;
  final int? accountId;
  final int manualContribution;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SavingsGoal.fromMap(Map<String, Object?> map) => SavingsGoal(
    id: map['id'] as int?,
    name: map['name'] as String,
    targetAmount: map['target_amount'] as int,
    accountId: map['account_id'] as int?,
    manualContribution: map['manual_contribution'] as int,
    isArchived: (map['is_archived'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'target_amount': targetAmount,
    'account_id': accountId,
    'manual_contribution': manualContribution,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

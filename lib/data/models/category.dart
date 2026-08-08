enum TransactionType { income, expense, transfer }

class Category {
  const Category({
    this.id,
    required this.name,
    required this.transactionType,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isArchived = false,
  });

  final int? id;
  final String name;
  final TransactionType transactionType;
  final String icon;
  final String color;
  final bool isDefault;
  final bool isArchived;

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    transactionType: TransactionType.values.byName(
      map['transaction_type'] as String,
    ),
    icon: map['icon'] as String,
    color: map['color'] as String,
    isDefault: (map['is_default'] as int) == 1,
    isArchived: (map['is_archived'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'transaction_type': transactionType.name,
    'icon': icon,
    'color': color,
    'is_default': isDefault ? 1 : 0,
    'is_archived': isArchived ? 1 : 0,
  };
}

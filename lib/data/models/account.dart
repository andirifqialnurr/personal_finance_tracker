enum AccountType { cash, bank, eWallet, other }

class Account {
  const Account({
    this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.icon,
    required this.color,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final AccountType type;
  final int openingBalance;
  final String icon;
  final String color;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Account.fromMap(Map<String, Object?> map) => Account(
    id: map['id'] as int?,
    name: map['name'] as String,
    type: AccountType.values.byName(map['type'] as String),
    openingBalance: map['opening_balance'] as int,
    icon: map['icon'] as String,
    color: map['color'] as String,
    isArchived: (map['is_archived'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type.name,
    'opening_balance': openingBalance,
    'icon': icon,
    'color': color,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

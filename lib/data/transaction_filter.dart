import 'models/models.dart';

class FlowTransactionFilter {
  const FlowTransactionFilter({
    this.query = '',
    this.type,
    this.accountId,
    this.categoryId,
    this.startDate,
    this.endDate,
  });

  final String query;
  final TransactionType? type;
  final int? accountId;
  final int? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;

  List<Transaction> apply(
    Iterable<Transaction> transactions, {
    Map<int, String> categoryNames = const {},
  }) => [
    for (final transaction in transactions)
      if (matches(transaction, categoryNames: categoryNames)) transaction,
  ];

  bool matches(
    Transaction transaction, {
    Map<int, String> categoryNames = const {},
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      final note = transaction.note?.toLowerCase() ?? '';
      final category = transaction.categoryId == null
          ? ''
          : categoryNames[transaction.categoryId]?.toLowerCase() ?? '';
      if (!note.contains(normalizedQuery) &&
          !category.contains(normalizedQuery)) {
        return false;
      }
    }
    if (type != null && transaction.type != type) return false;
    if (accountId != null &&
        transaction.accountId != accountId &&
        transaction.destinationAccountId != accountId) {
      return false;
    }
    if (categoryId != null && transaction.categoryId != categoryId) {
      return false;
    }
    if (startDate != null && transaction.occurredAt.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && transaction.occurredAt.isAfter(endDate!)) {
      return false;
    }
    return true;
  }
}

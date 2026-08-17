import 'flow_csv_exporter.dart';
import 'models/models.dart';

class FlowCsvImportPreview {
  const FlowCsvImportPreview({
    required this.transactions,
    required this.errors,
    required this.skippedDuplicates,
    required this.matchedAccountNames,
    required this.matchedCategoryNames,
  });

  final List<Transaction> transactions;
  final List<FlowCsvImportError> errors;
  final int skippedDuplicates;
  final Set<String> matchedAccountNames;
  final Set<String> matchedCategoryNames;

  int get readyCount => transactions.length;
  int get errorCount => errors.length;
  bool get canImport => transactions.isNotEmpty;
}

class FlowCsvImportError {
  const FlowCsvImportError({required this.rowNumber, required this.message});

  final int rowNumber;
  final String message;
}

class FlowCsvImporter {
  const FlowCsvImporter._();

  static FlowCsvImportPreview preview({
    required String csv,
    required List<Account> accounts,
    required List<Category> categories,
    required List<Transaction> existingTransactions,
    DateTime? importedAt,
  }) {
    final rows = _parse(csv);
    if (rows.isEmpty) {
      return const FlowCsvImportPreview(
        transactions: [],
        errors: [FlowCsvImportError(rowNumber: 1, message: 'CSV is empty.')],
        skippedDuplicates: 0,
        matchedAccountNames: {},
        matchedCategoryNames: {},
      );
    }
    if (!_hasExpectedHeaders(rows.first)) {
      return const FlowCsvImportPreview(
        transactions: [],
        errors: [
          FlowCsvImportError(
            rowNumber: 1,
            message: 'CSV headers do not match the Flow export format.',
          ),
        ],
        skippedDuplicates: 0,
        matchedAccountNames: {},
        matchedCategoryNames: {},
      );
    }

    final now = importedAt ?? DateTime.now().toUtc();
    final accountByName = {
      for (final account in accounts) _normalize(account.name): account,
    };
    final categoriesByName = <String, List<Category>>{};
    for (final category in categories) {
      categoriesByName
          .putIfAbsent(_normalize(category.name), () => <Category>[])
          .add(category);
    }
    final seenKeys = {
      for (final transaction in existingTransactions)
        _TransactionImportKey.fromTransaction(transaction),
    };
    final errors = <FlowCsvImportError>[];
    final transactions = <Transaction>[];
    final matchedAccountNames = <String>{};
    final matchedCategoryNames = <String>{};
    var skippedDuplicates = 0;

    for (var index = 1; index < rows.length; index += 1) {
      final rowNumber = index + 1;
      final row = rows[index];
      if (row.every((value) => value.trim().isEmpty)) continue;
      if (row.length != FlowCsvExporter.headers.length) {
        errors.add(
          FlowCsvImportError(
            rowNumber: rowNumber,
            message: 'Expected ${FlowCsvExporter.headers.length} columns.',
          ),
        );
        continue;
      }

      final parsed = _parseRow(
        row,
        rowNumber,
        accountByName,
        categoriesByName,
        now,
      );
      if (parsed.error != null) {
        errors.add(parsed.error!);
        continue;
      }

      final transaction = parsed.transaction!;
      final key = _TransactionImportKey.fromTransaction(transaction);
      if (seenKeys.contains(key)) {
        skippedDuplicates += 1;
        continue;
      }
      seenKeys.add(key);
      transactions.add(transaction);
      matchedAccountNames.add(parsed.accountName!);
      if (parsed.destinationAccountName != null) {
        matchedAccountNames.add(parsed.destinationAccountName!);
      }
      if (parsed.categoryName != null) {
        matchedCategoryNames.add(parsed.categoryName!);
      }
    }

    return FlowCsvImportPreview(
      transactions: List.unmodifiable(transactions),
      errors: List.unmodifiable(errors),
      skippedDuplicates: skippedDuplicates,
      matchedAccountNames: Set.unmodifiable(matchedAccountNames),
      matchedCategoryNames: Set.unmodifiable(matchedCategoryNames),
    );
  }

  static _ParsedImportRow _parseRow(
    List<String> row,
    int rowNumber,
    Map<String, Account> accountByName,
    Map<String, List<Category>> categoriesByName,
    DateTime importedAt,
  ) {
    final occurredAt = DateTime.tryParse(row[0].trim());
    if (occurredAt == null) {
      return _ParsedImportRow.error(rowNumber, 'Date is invalid.');
    }

    final type = _parseType(row[1]);
    if (type == null) {
      return _ParsedImportRow.error(rowNumber, 'Type is invalid.');
    }

    final amount = int.tryParse(row[2].trim());
    if (amount == null || amount <= 0) {
      return _ParsedImportRow.error(rowNumber, 'Amount must be positive.');
    }

    final accountName = row[3].trim();
    final account = accountByName[_normalize(accountName)];
    if (account?.id == null) {
      return _ParsedImportRow.error(rowNumber, 'Account "$accountName" was not found.');
    }

    final destinationName = row[4].trim();
    Account? destinationAccount;
    if (type == TransactionType.transfer) {
      if (destinationName.isEmpty) {
        return _ParsedImportRow.error(
          rowNumber,
          'Transfer destination account is required.',
        );
      }
      destinationAccount = accountByName[_normalize(destinationName)];
      if (destinationAccount?.id == null) {
        return _ParsedImportRow.error(
          rowNumber,
          'Destination account "$destinationName" was not found.',
        );
      }
      if (destinationAccount!.id == account!.id) {
        return _ParsedImportRow.error(
          rowNumber,
          'Transfer accounts must be different.',
        );
      }
    }

    final categoryName = row[5].trim();
    Category? category;
    if (type == TransactionType.income || type == TransactionType.expense) {
      if (categoryName.isEmpty) {
        return _ParsedImportRow.error(rowNumber, 'Category is required.');
      }
      category = categoriesByName[_normalize(categoryName)]?.firstWhere(
        (item) => item.transactionType == type,
        orElse: () => const Category(
          name: '',
          transactionType: TransactionType.expense,
          icon: '',
          color: '',
        ),
      );
      if (category?.id == null || category!.name.isEmpty) {
        return _ParsedImportRow.error(
          rowNumber,
          'Category "$categoryName" was not found for ${row[1].trim()}.',
        );
      }
    }

    final note = row[6].trim();
    return _ParsedImportRow(
      transaction: Transaction(
        type: type,
        amount: amount,
        accountId: account!.id!,
        destinationAccountId: destinationAccount?.id,
        categoryId: category?.id,
        note: note.isEmpty ? null : note,
        occurredAt: occurredAt,
        createdAt: importedAt,
        updatedAt: importedAt,
      ),
      accountName: account.name,
      destinationAccountName: destinationAccount?.name,
      categoryName: category?.name,
    );
  }

  static List<List<String>> _parse(String csv) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < csv.length; index += 1) {
      final char = csv[index];
      if (inQuotes) {
        if (char == '"') {
          final nextIndex = index + 1;
          if (nextIndex < csv.length && csv[nextIndex] == '"') {
            field.write('"');
            index += 1;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(char);
        }
        continue;
      }

      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        row.add(field.toString());
        field.clear();
      } else if (char == '\r' || char == '\n') {
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
        if (char == '\r' && index + 1 < csv.length && csv[index + 1] == '\n') {
          index += 1;
        }
      } else {
        field.write(char);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  static bool _hasExpectedHeaders(List<String> headers) {
    if (headers.length != FlowCsvExporter.headers.length) return false;
    for (var index = 0; index < headers.length; index += 1) {
      if (headers[index].trim() != FlowCsvExporter.headers[index]) {
        return false;
      }
    }
    return true;
  }

  static TransactionType? _parseType(String value) {
    final normalized = _normalize(value);
    return switch (normalized) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      'transfer' => TransactionType.transfer,
      _ => null,
    };
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}

class _ParsedImportRow {
  const _ParsedImportRow({
    this.transaction,
    this.error,
    this.accountName,
    this.destinationAccountName,
    this.categoryName,
  });

  factory _ParsedImportRow.error(int rowNumber, String message) =>
      _ParsedImportRow(
        error: FlowCsvImportError(rowNumber: rowNumber, message: message),
      );

  final Transaction? transaction;
  final FlowCsvImportError? error;
  final String? accountName;
  final String? destinationAccountName;
  final String? categoryName;
}

class _TransactionImportKey {
  const _TransactionImportKey({
    required this.occurredAt,
    required this.type,
    required this.amount,
    required this.accountId,
    required this.destinationAccountId,
    required this.categoryId,
    required this.note,
  });

  factory _TransactionImportKey.fromTransaction(Transaction transaction) =>
      _TransactionImportKey(
        occurredAt: transaction.occurredAt.toUtc().toIso8601String(),
        type: transaction.type,
        amount: transaction.amount,
        accountId: transaction.accountId,
        destinationAccountId: transaction.destinationAccountId,
        categoryId: transaction.categoryId,
        note: _normalizeNote(transaction.note),
      );

  final String occurredAt;
  final TransactionType type;
  final int amount;
  final int accountId;
  final int? destinationAccountId;
  final int? categoryId;
  final String note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TransactionImportKey &&
          occurredAt == other.occurredAt &&
          type == other.type &&
          amount == other.amount &&
          accountId == other.accountId &&
          destinationAccountId == other.destinationAccountId &&
          categoryId == other.categoryId &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
    occurredAt,
    type,
    amount,
    accountId,
    destinationAccountId,
    categoryId,
    note,
  );

  static String _normalizeNote(String? value) => value?.trim() ?? '';
}

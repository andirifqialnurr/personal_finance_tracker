import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/flow_format.dart';
import 'models/models.dart';

class FlowMonthlyReport {
  const FlowMonthlyReport({
    required this.month,
    required this.transactions,
    required this.income,
    required this.expense,
    required this.transfers,
    required this.topExpenseCategory,
  });

  final DateTime month;
  final List<Transaction> transactions;
  final int income;
  final int expense;
  final int transfers;
  final String topExpenseCategory;

  int get netCashFlow => income - expense;
}

class FlowReportExporter {
  const FlowReportExporter._();

  static FlowMonthlyReport monthly({
    required DateTime month,
    required List<Transaction> transactions,
    required List<Category> categories,
  }) {
    final filtered = transactions
        .where(
          (transaction) =>
              transaction.occurredAt.year == month.year &&
              transaction.occurredAt.month == month.month,
        )
        .toList(growable: false)
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final income = filtered
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expense = filtered
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final transfers = filtered
        .where((transaction) => transaction.type == TransactionType.transfer)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    return FlowMonthlyReport(
      month: DateTime(month.year, month.month),
      transactions: filtered,
      income: income,
      expense: expense,
      transfers: transfers,
      topExpenseCategory: _topExpenseCategory(filtered, categories),
    );
  }

  static Future<File> writeMonthlyPdf({
    required DateTime month,
    required String currency,
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final period =
        '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final file = File(
      '${directory.path}/flow-report-$period-$timestamp.pdf',
    );
    return file.writeAsBytes(
      buildMonthlyPdf(
        month: month,
        currency: currency,
        transactions: transactions,
        accounts: accounts,
        categories: categories,
      ),
      flush: true,
    );
  }

  static List<int> buildMonthlyPdf({
    required DateTime month,
    required String currency,
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    final report = monthly(
      month: month,
      transactions: transactions,
      categories: categories,
    );
    final accountNames = {
      for (final account in accounts)
        if (account.id != null) account.id!: account.name,
    };
    final categoryNames = {
      for (final category in categories)
        if (category.id != null) category.id!: category.name,
    };
    final lines = <String>[
      'Flow Monthly Report',
      'Period: ${_monthName(report.month.month)} ${report.month.year}',
      'Exported: ${DateTime.now().toUtc().toIso8601String()}',
      '',
      'Summary',
      'Income: ${formatCurrency(report.income, currency)}',
      'Expense: ${formatCurrency(report.expense, currency)}',
      'Net cash flow: ${formatCurrency(report.netCashFlow, currency)}',
      'Transfers: ${formatCurrency(report.transfers, currency)}',
      'Transactions: ${report.transactions.length}',
      'Top expense: ${report.topExpenseCategory}',
      '',
      'Transactions',
    ];
    if (report.transactions.isEmpty) {
      lines.add('No transactions for this period.');
    } else {
      lines.add('Date        Type      Amount            Account       Category/To       Note');
      for (final transaction in report.transactions) {
        lines.add(
          _tableLine(
            date:
                '${transaction.occurredAt.year}-${transaction.occurredAt.month.toString().padLeft(2, '0')}-${transaction.occurredAt.day.toString().padLeft(2, '0')}',
            type: transaction.type.name,
            amount: formatCurrency(transaction.amount, currency),
            account: accountNames[transaction.accountId] ??
                'Account ${transaction.accountId}',
            category: transaction.destinationAccountId == null
                ? transaction.categoryId == null
                      ? '-'
                      : categoryNames[transaction.categoryId] ??
                            'Category ${transaction.categoryId}'
                : accountNames[transaction.destinationAccountId] ??
                      'Account ${transaction.destinationAccountId}',
            note: transaction.note ?? '',
          ),
        );
      }
    }
    return _SimplePdfWriter.write(lines);
  }

  static String _topExpenseCategory(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final categoryTotals = <int, int>{};
    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      if (transaction.type != TransactionType.expense || categoryId == null) {
        continue;
      }
      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0) + transaction.amount;
    }
    if (categoryTotals.isEmpty) return 'None';
    final top = categoryTotals.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );
    var name = 'Category ${top.key}';
    for (final category in categories) {
      if (category.id == top.key) {
        name = category.name;
        break;
      }
    }
    return name;
  }

  static String _tableLine({
    required String date,
    required String type,
    required String amount,
    required String account,
    required String category,
    required String note,
  }) {
    return [
      date.padRight(11),
      type.padRight(9),
      amount.padRight(17),
      _clip(account, 13).padRight(14),
      _clip(category, 16).padRight(17),
      _clip(note, 28),
    ].join('');
  }

  static String _clip(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    if (maxLength <= 1) return value.substring(0, maxLength);
    return '${value.substring(0, maxLength - 1)}.';
  }

  static String _monthName(int month) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month];
}

class _SimplePdfWriter {
  const _SimplePdfWriter._();

  static List<int> write(List<String> lines) {
    final pages = <List<String>>[];
    for (var index = 0; index < lines.length; index += 46) {
      pages.add(lines.skip(index).take(46).toList(growable: false));
    }
    if (pages.isEmpty) pages.add(const []);
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [${[
        for (var page = 0; page < pages.length; page++) '${4 + page * 2} 0 R',
      ].join(' ')}] /Count ${pages.length} >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];
    for (var page = 0; page < pages.length; page++) {
      final contentObject = 5 + page * 2;
      final content = _content(pages[page], page + 1, pages.length);
      objects.add(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R >> >> /Contents $contentObject 0 R >>',
      );
      objects.add('<< /Length ${latin1.encode(content).length} >>\nstream\n$content\nendstream');
    }
    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (var index = 0; index < objects.length; index++) {
      offsets.add(latin1.encode(buffer.toString()).length);
      buffer
        ..write('${index + 1} 0 obj\n')
        ..write(objects[index])
        ..write('\nendobj\n');
    }
    final xrefOffset = latin1.encode(buffer.toString()).length;
    buffer
      ..write('xref\n')
      ..write('0 ${objects.length + 1}\n')
      ..write('0000000000 65535 f \n');
    for (final offset in offsets.skip(1)) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    buffer
      ..write('trailer\n')
      ..write('<< /Size ${objects.length + 1} /Root 1 0 R >>\n')
      ..write('startxref\n')
      ..write('$xrefOffset\n')
      ..write('%%EOF\n');
    return latin1.encode(buffer.toString());
  }

  static String _content(List<String> lines, int page, int pageCount) {
    final buffer = StringBuffer('BT\n/F1 10 Tf\n12 TL\n50 790 Td\n');
    for (final line in lines) {
      buffer.write('(${_escape(line)}) Tj\n0 -14 Td\n');
    }
    buffer
      ..write('0 -14 Td\n')
      ..write('(Page $page of $pageCount) Tj\n')
      ..write('ET');
    return buffer.toString();
  }

  static String _escape(String value) {
    final sanitized = String.fromCharCodes(
      value.runes.map((rune) => rune >= 32 && rune <= 126 ? rune : 63),
    );
    return sanitized
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}

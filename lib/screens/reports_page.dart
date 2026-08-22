import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
    required this.onExportMonthlyCsv,
    required this.onExportMonthlyPdf,
    required this.onExportBackup,
  });

  final List<Transaction> transactions;
  final List<Category> categories;
  final String currency;
  final Future<String> Function(DateTime month) onExportMonthlyCsv;
  final Future<String> Function(DateTime month) onExportMonthlyPdf;
  final Future<String> Function() onExportBackup;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  var _isExportingCsv = false;
  var _isExportingPdf = false;
  var _isExportingBackup = false;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final monthTransactions = widget.transactions.where(
      (transaction) =>
          transaction.occurredAt.year == _selectedMonth.year &&
          transaction.occurredAt.month == _selectedMonth.month,
    ).toList(growable: false);
    final income = monthTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expense = monthTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final transfers = monthTransactions
        .where((transaction) => transaction.type == TransactionType.transfer)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final transactionCount = monthTransactions.length;
    final topCategory = _topExpenseCategory(monthTransactions);
    final hasReportData = monthTransactions.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.md),
      children: [
        const SizedBox(height: FlowSpacing.gapSection),
        Row(
          children: [
            IconButton(
              onPressed: () => _moveMonth(-1),
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => _moveMonth(1),
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: FlowSpacing.sm),
        if (!hasReportData)
          const _CenteredEmptyText(
            message:
                'No report data for this month yet. Add income, expense, or transfer transactions to build a monthly report.',
          )
        else
          FlowCard(
            density: FlowCardDensity.standard,
            child: Column(
              children: [
                _ReportMetric(
                  label: 'Income',
                  value: formatCurrency(income, widget.currency),
                ),
                const SizedBox(height: FlowSpacing.gapGroup),
                _ReportMetric(
                  label: 'Expense',
                  value: formatCurrency(expense, widget.currency),
                ),
                const SizedBox(height: FlowSpacing.gapGroup),
                _ReportMetric(
                  label: 'Net cash flow',
                  value: formatCurrency(income - expense, widget.currency),
                ),
                const SizedBox(height: FlowSpacing.gapGroup),
                _ReportMetric(
                  label: 'Transfers',
                  value: formatCurrency(transfers, widget.currency),
                ),
                const SizedBox(height: FlowSpacing.gapGroup),
                _ReportMetric(
                  label: 'Transactions',
                  value: '$transactionCount',
                ),
                const SizedBox(height: FlowSpacing.gapGroup),
                _ReportMetric(
                  label: 'Top expense',
                  value: topCategory,
                ),
              ],
            ),
          ),
        const SizedBox(height: FlowSpacing.gapSection),
        Text('Exports', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: FlowSpacing.gapBlock),
        FlowButton(
          label: _isExportingCsv ? 'Exporting CSV...' : 'Export monthly CSV',
          variant: FlowButtonVariant.secondary,
          icon: Icons.file_download_outlined,
          onPressed: _isExportingCsv ? null : _exportCsv,
        ),
        const SizedBox(height: FlowSpacing.gapGroup),
        FlowButton(
          label: _isExportingPdf ? 'Exporting PDF...' : 'Export monthly PDF',
          variant: FlowButtonVariant.secondary,
          icon: Icons.picture_as_pdf_outlined,
          onPressed: _isExportingPdf ? null : _exportPdf,
        ),
        const SizedBox(height: FlowSpacing.gapSection),
        Text('Backup', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: FlowSpacing.gapBlock),
        Text(
          'Backup stores the app data file. Use CSV or PDF for readable financial reports.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: FlowSpacing.gapGroup),
        FlowButton(
          label: _isExportingBackup
              ? 'Exporting backup...'
              : 'Export local backup',
          variant: FlowButtonVariant.secondary,
          icon: Icons.backup_outlined,
          onPressed: _isExportingBackup ? null : _exportBackup,
        ),
      ],
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _isExportingCsv = true);
    try {
      final path = await widget.onExportMonthlyCsv(_selectedMonth);
      _showMessage('CSV exported to $path');
    } catch (error) {
      _showMessage('CSV export failed: $error');
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExportingPdf = true);
    try {
      final path = await widget.onExportMonthlyPdf(_selectedMonth);
      _showMessage('PDF exported to $path');
    } catch (error) {
      _showMessage('PDF export failed: $error');
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isExportingBackup = true);
    try {
      final path = await widget.onExportBackup();
      _showMessage('Backup exported to $path');
    } catch (error) {
      _showMessage('Backup export failed: $error');
    } finally {
      if (mounted) setState(() => _isExportingBackup = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _moveMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  String _topExpenseCategory(Iterable<Transaction> monthTransactions) {
    final categoryTotals = <int, int>{};
    for (final transaction in monthTransactions) {
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
    String? categoryName;
    for (final category in widget.categories) {
      if (category.id == top.key) {
        categoryName = category.name;
        break;
      }
    }
    return '${categoryName ?? 'Category ${top.key}'} (${formatCurrency(top.value, widget.currency)})';
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

class _CenteredEmptyText extends StatelessWidget {
  const _CenteredEmptyText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 136,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ),
  );
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      const SizedBox(width: FlowSpacing.sm),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ],
  );
}

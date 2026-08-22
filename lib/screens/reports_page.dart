import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';
import '../utils/flow_format.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.transactions,
    required this.currency,
    required this.onExportCsv,
    required this.onExportBackup,
  });

  final List<Transaction> transactions;
  final String currency;
  final Future<String> Function() onExportCsv;
  final Future<String> Function() onExportBackup;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  var _isExportingCsv = false;
  var _isExportingBackup = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTransactions = widget.transactions.where(
      (transaction) =>
          transaction.occurredAt.year == now.year &&
          transaction.occurredAt.month == now.month,
    );
    final income = monthTransactions
        .where((transaction) => transaction.type == TransactionType.income)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final expense = monthTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);
    final transfers = monthTransactions
        .where((transaction) => transaction.type == TransactionType.transfer)
        .fold<int>(0, (sum, transaction) => sum + transaction.amount);

    return ListView(
      padding: const EdgeInsets.all(FlowSpacing.md),
      children: [
        const SizedBox(height: FlowSpacing.gapSection),
        Text(
          '${_monthName(now.month)} ${now.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: FlowSpacing.sm),
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
          label: 'Export monthly PDF',
          variant: FlowButtonVariant.secondary,
          icon: Icons.picture_as_pdf_outlined,
          onPressed: () => _showMessage('PDF export is scheduled for the next reports batch.'),
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
      final path = await widget.onExportCsv();
      _showMessage('CSV exported to $path');
    } catch (error) {
      _showMessage('CSV export failed: $error');
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
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

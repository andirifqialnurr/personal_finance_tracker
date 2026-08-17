import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/data.dart';
import 'manage_categories_page.dart';
import '../theme/flow_tokens.dart';

class FlowSettingsPage extends StatefulWidget {
  const FlowSettingsPage({
    super.key,
    required this.initialThemeMode,
    required this.onThemeModeChanged,
    required this.currency,
    required this.onCurrencyChanged,
    required this.categories,
    required this.onCategoriesChanged,
    required this.onExportCsv,
    required this.onPreviewImportCsv,
    required this.onImportCsv,
    required this.onDeleteAll,
    this.showAppBar = true,
  });
  final ThemeMode initialThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final List<Category> categories;
  final ValueChanged<List<Category>> onCategoriesChanged;
  final Future<String> Function() onExportCsv;
  final Future<FlowCsvImportPreview> Function(String csv) onPreviewImportCsv;
  final Future<int> Function(FlowCsvImportPreview preview) onImportCsv;
  final VoidCallback onDeleteAll;
  final bool showAppBar;

  @override
  State<FlowSettingsPage> createState() => _FlowSettingsPageState();
}

class _FlowSettingsPageState extends State<FlowSettingsPage> {
  late ThemeMode _themeMode = _normalizeThemeMode(widget.initialThemeMode);
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _themeMode == ThemeMode.dark ? 1 : 0;
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Settings'),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                icon: const Icon(Icons.close),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.md),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.gapBlock),
          FlowSegmentedControl(
            labels: const ['Light', 'Dark'],
            selectedIndex: selectedIndex,
            onChanged: (index) {
              final mode = index == 1 ? ThemeMode.dark : ThemeMode.light;
              setState(() => _themeMode = mode);
              widget.onThemeModeChanged(mode);
            },
          ),
          const SizedBox(height: FlowSpacing.gapSection),
          FlowSelector(
            label: 'Currency',
            value: widget.currency,
            icon: Icons.payments_outlined,
            onTap: _selectCurrency,
          ),
          const SizedBox(height: FlowSpacing.gapSection),
          FlowSelector(
            label: 'Categories',
            value:
                '${widget.categories.where((category) => !category.isArchived).length} active',
            icon: Icons.category_outlined,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ManageCategoriesPage(
                  categories: widget.categories,
                  onChanged: widget.onCategoriesChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: FlowSpacing.gapSection),
          Text(
            'Data management',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: FlowSpacing.gapBlock),
          FlowButton(
            label: _isExporting ? 'Exporting CSV...' : 'Export CSV',
            variant: FlowButtonVariant.secondary,
            icon: Icons.file_download_outlined,
            onPressed: _isExporting ? null : _exportCsv,
          ),
          const SizedBox(height: FlowSpacing.gapGroup),
          FlowButton(
            label: 'Import CSV',
            variant: FlowButtonVariant.secondary,
            icon: Icons.file_upload_outlined,
            onPressed: _openImportCsv,
          ),
          const SizedBox(height: FlowSpacing.gapSection),
          Text('Danger zone', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.gapBlock),
          FlowButton(
            label: 'Delete all data',
            variant: FlowButtonVariant.destructive,
            onPressed: _confirmDeleteAll,
          ),
        ],
      ),
    );
  }

  static ThemeMode _normalizeThemeMode(ThemeMode mode) =>
      mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> _selectCurrency() async {
    final currency = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ['IDR', 'USD', 'SGD'])
              ListTile(
                title: Text(option),
                trailing: option == widget.currency
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (currency != null) widget.onCurrencyChanged(currency);
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
          'This removes every account and transaction, then restores the default categories on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDeleteAll();
      if (widget.showAppBar) Navigator.of(context).pop();
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final path = await widget.onExportCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV exported to $path')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $error')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openImportCsv() async {
    final result = await showModalBottomSheet<_CsvImportResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CsvImportSheet(
        onPreviewImportCsv: widget.onPreviewImportCsv,
        onImportCsv: widget.onImportCsv,
      ),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${result.importedCount} transactions. Skipped ${result.skippedDuplicates} duplicates.',
        ),
      ),
    );
  }
}

class _CsvImportSheet extends StatefulWidget {
  const _CsvImportSheet({
    required this.onPreviewImportCsv,
    required this.onImportCsv,
  });

  final Future<FlowCsvImportPreview> Function(String csv) onPreviewImportCsv;
  final Future<int> Function(FlowCsvImportPreview preview) onImportCsv;

  @override
  State<_CsvImportSheet> createState() => _CsvImportSheetState();
}

class _CsvImportSheetState extends State<_CsvImportSheet> {
  final _csvController = TextEditingController();
  FlowCsvImportPreview? _preview;
  String? _error;
  bool _isPreviewing = false;
  bool _isApplying = false;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final canApply =
        preview?.canImport == true && !_isPreviewing && !_isApplying;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(FlowSpacing.md),
          children: [
            Text('Import CSV', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: FlowSpacing.gapBlock),
            TextField(
              key: const Key('flow-import-csv-input'),
              controller: _csvController,
              minLines: 5,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'CSV content',
                hintText:
                    'Date,Type,Amount,Account,Destination Account,Category,Note',
              ),
              onChanged: (_) {
                if (_preview != null || _error != null) {
                  setState(() {
                    _preview = null;
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: FlowSpacing.gapBlock),
            Row(
              children: [
                Expanded(
                  child: FlowButton(
                    label: _isPreviewing ? 'Previewing...' : 'Preview',
                    variant: FlowButtonVariant.secondary,
                    icon: Icons.visibility_outlined,
                    onPressed: _isPreviewing || _isApplying
                        ? null
                        : _previewCsv,
                  ),
                ),
                const SizedBox(width: FlowSpacing.gapGroup),
                Expanded(
                  child: FlowButton(
                    label: _isApplying ? 'Importing...' : 'Import',
                    icon: Icons.file_upload_outlined,
                    onPressed: canApply ? () => _applyImport(preview) : null,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: FlowSpacing.gapBlock),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: FlowSpacing.gapBlock),
              _CsvImportPreviewCard(preview: preview),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _previewCsv() async {
    setState(() {
      _isPreviewing = true;
      _error = null;
    });
    try {
      final preview = await widget.onPreviewImportCsv(_csvController.text);
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'CSV preview failed: $error');
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  Future<void> _applyImport(FlowCsvImportPreview? preview) async {
    if (preview == null || !preview.canImport) return;
    setState(() {
      _isApplying = true;
      _error = null;
    });
    try {
      final importedCount = await widget.onImportCsv(preview);
      if (!mounted) return;
      Navigator.of(context).pop(
        _CsvImportResult(
          importedCount: importedCount,
          skippedDuplicates: preview.skippedDuplicates,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'CSV import failed: $error');
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }
}

class _CsvImportPreviewCard extends StatelessWidget {
  const _CsvImportPreviewCard({required this.preview});

  final FlowCsvImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;
    final visibleErrors = preview.errors.take(4).toList();
    return FlowCard(
      density: FlowCardDensity.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview result', style: textTheme.titleSmall),
          const SizedBox(height: FlowSpacing.gapGroup),
          _PreviewMetric(label: 'Ready', value: preview.readyCount.toString()),
          _PreviewMetric(
            label: 'Duplicates',
            value: preview.skippedDuplicates.toString(),
          ),
          _PreviewMetric(label: 'Errors', value: preview.errorCount.toString()),
          _PreviewMetric(
            label: 'Matched accounts',
            value: preview.matchedAccountNames.length.toString(),
          ),
          _PreviewMetric(
            label: 'Matched categories',
            value: preview.matchedCategoryNames.length.toString(),
          ),
          if (visibleErrors.isNotEmpty) ...[
            const SizedBox(height: FlowSpacing.gapGroup),
            for (final error in visibleErrors)
              Text(
                'Row ${error.rowNumber}: ${error.message}',
                style: textTheme.bodySmall?.copyWith(color: errorColor),
              ),
            if (preview.errorCount > visibleErrors.length)
              Text(
                '+${preview.errorCount - visibleErrors.length} more errors',
                style: textTheme.bodySmall?.copyWith(color: errorColor),
              ),
          ],
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlowSpacing.gapTight),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: FlowSpacing.gapGroup),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _CsvImportResult {
  const _CsvImportResult({
    required this.importedCount,
    required this.skippedDuplicates,
  });

  final int importedCount;
  final int skippedDuplicates;
}

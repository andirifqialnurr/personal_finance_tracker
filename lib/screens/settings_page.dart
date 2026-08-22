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
    required this.onDeleteAll,
    this.showAppBar = true,
  });
  final ThemeMode initialThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final List<Category> categories;
  final ValueChanged<List<Category>> onCategoriesChanged;
  final VoidCallback onDeleteAll;
  final bool showAppBar;

  @override
  State<FlowSettingsPage> createState() => _FlowSettingsPageState();
}

class _FlowSettingsPageState extends State<FlowSettingsPage> {
  late ThemeMode _themeMode = _normalizeThemeMode(widget.initialThemeMode);

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
}

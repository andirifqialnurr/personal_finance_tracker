import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../theme/flow_tokens.dart';

class FlowSettingsPage extends StatefulWidget {
  const FlowSettingsPage({
    super.key,
    required this.initialThemeMode,
    required this.onThemeModeChanged,
  });
  final ThemeMode initialThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<FlowSettingsPage> createState() => _FlowSettingsPageState();
}

class _FlowSettingsPageState extends State<FlowSettingsPage> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (_themeMode) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      ThemeMode.system => 2,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: FlowSpacing.sm),
          FlowSegmentedControl(
            labels: const ['Light', 'Dark', 'System'],
            selectedIndex: selectedIndex,
            onChanged: (index) {
              final mode = switch (index) {
                0 => ThemeMode.light,
                1 => ThemeMode.dark,
                _ => ThemeMode.system,
              };
              setState(() => _themeMode = mode);
              widget.onThemeModeChanged(mode);
            },
          ),
          const SizedBox(height: FlowSpacing.lg),
          const FlowSelector(
            label: 'Currency',
            value: 'IDR',
            icon: Icons.payments_outlined,
          ),
        ],
      ),
    );
  }
}

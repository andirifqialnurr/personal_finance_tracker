import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../theme/flow_tokens.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  int _selectedType = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add transaction'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FlowSpacing.lg),
        children: [
          FlowSegmentedControl(
            labels: const ['Expense', 'Income', 'Transfer'],
            selectedIndex: _selectedType,
            onChanged: (index) => setState(() => _selectedType = index),
          ),
          const SizedBox(height: FlowSpacing.lg),
          Text('Amount', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: FlowSpacing.xs),
          TextField(
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Rp 0'),
          ),
          const SizedBox(height: FlowSpacing.md),
          const FlowSelector(
            label: 'Account',
            value: 'Select account',
            icon: Icons.wallet_outlined,
          ),
          if (_selectedType == 2) ...[
            const SizedBox(height: FlowSpacing.md),
            const FlowSelector(
              label: 'To account',
              value: 'Select destination',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ] else ...[
            const SizedBox(height: FlowSpacing.md),
            const FlowSelector(
              label: 'Category',
              value: 'Select category',
              icon: Icons.category_outlined,
            ),
          ],
          const SizedBox(height: FlowSpacing.md),
          const TextField(
            decoration: InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: FlowSpacing.lg),
          FlowButton(label: 'Save transaction', onPressed: () {}),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../data/models/models.dart';
import '../theme/flow_tokens.dart';

class AccountFormPage extends StatefulWidget {
  const AccountFormPage({super.key, this.account, required this.onSaved});

  final Account? account;
  final ValueChanged<Account> onSaved;

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.account?.name,
  );
  late final TextEditingController _balanceController = TextEditingController(
    text: widget.account?.openingBalance.toString() ?? '0',
  );
  late AccountType _type = widget.account?.type ?? AccountType.cash;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Add account' : 'Edit account'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
          icon: const Icon(Icons.close),
        ),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(FlowSpacing.lg),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'e.g. Cash wallet',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: FlowSpacing.md),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: [
                for (final type in AccountType.values)
                  DropdownMenuItem(value: type, child: Text(_typeLabel(type))),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: FlowSpacing.md),
            TextFormField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Opening balance',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: FlowSpacing.lg),
            FlowButton(
              label: widget.account == null ? 'Create account' : 'Save changes',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final balance = int.tryParse(
      _balanceController.text.replaceAll(RegExp(r'[^0-9-]'), ''),
    );
    if (name.isEmpty || balance == null || balance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and valid opening balance')),
      );
      return;
    }
    final now = DateTime.now().toUtc();
    widget.onSaved(
      Account(
        id: widget.account?.id,
        name: name,
        type: _type,
        openingBalance: balance,
        icon: _iconFor(_type),
        color: '#168C78',
        isArchived: widget.account?.isArchived ?? false,
        createdAt: widget.account?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    Navigator.of(context).pop();
  }

  static String _typeLabel(AccountType type) => switch (type) {
    AccountType.cash => 'Cash',
    AccountType.bank => 'Bank',
    AccountType.eWallet => 'E-wallet',
    AccountType.other => 'Other',
  };

  static String _iconFor(AccountType type) => switch (type) {
    AccountType.cash => 'wallet',
    AccountType.bank => 'account_balance',
    AccountType.eWallet => 'phone_android',
    AccountType.other => 'savings',
  };
}

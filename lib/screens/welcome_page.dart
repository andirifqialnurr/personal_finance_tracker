import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../theme/flow_tokens.dart';

class FlowWelcomePage extends StatelessWidget {
  const FlowWelcomePage({
    super.key,
    required this.onCreateFirstAccount,
    this.currency = 'IDR',
    this.onCurrencyChanged,
  });

  final VoidCallback onCreateFirstAccount;
  final String currency;
  final ValueChanged<String>? onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FlowSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              FlowIconContainer(
                icon: Icons.auto_awesome,
                variant: FlowIconContainerVariant.account,
              ),
              const SizedBox(height: FlowSpacing.lg),
              Text(
                'Welcome to Flow',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: FlowSpacing.xs),
              Text(
                'A calm, simple place to understand your money.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: FlowSpacing.lg),
              FlowSelector(
                label: 'Currency',
                value: currency,
                icon: Icons.payments_outlined,
                onTap: onCurrencyChanged == null
                    ? null
                    : () async {
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final option in ['IDR', 'USD', 'SGD'])
                                  ListTile(
                                    title: Text(option),
                                    trailing: option == currency
                                        ? const Icon(Icons.check)
                                        : null,
                                    onTap: () => Navigator.pop(context, option),
                                  ),
                              ],
                            ),
                          ),
                        );
                        if (selected != null) onCurrencyChanged!(selected);
                      },
              ),
              const SizedBox(height: FlowSpacing.md),
              FlowButton(
                label: 'Create first account',
                onPressed: onCreateFirstAccount,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

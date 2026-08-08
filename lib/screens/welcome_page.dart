import 'package:flutter/material.dart';

import '../components/flow_components.dart';
import '../theme/flow_tokens.dart';

class FlowWelcomePage extends StatelessWidget {
  const FlowWelcomePage({super.key, required this.onCreateFirstAccount});

  final VoidCallback onCreateFirstAccount;

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
              const FlowSelector(
                label: 'Currency',
                value: 'IDR',
                icon: Icons.payments_outlined,
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

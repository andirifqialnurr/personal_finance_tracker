import 'package:flutter/material.dart';

import '../theme/flow_tokens.dart';
import 'flow_icon_container.dart';

class FlowEmptyState extends StatelessWidget {
  const FlowEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(FlowSpacing.lg),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowIconContainer(
              icon: icon,
              variant: FlowIconContainerVariant.account,
            ),
            const SizedBox(height: FlowSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FlowSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: FlowSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}

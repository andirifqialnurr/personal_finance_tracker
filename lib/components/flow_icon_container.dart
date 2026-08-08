import 'package:flutter/material.dart';

import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';

enum FlowIconContainerVariant { account, category, income, expense, transfer }

class FlowIconContainer extends StatelessWidget {
  const FlowIconContainer({
    super.key,
    required this.icon,
    this.variant = FlowIconContainerVariant.category,
  });
  final IconData icon;
  final FlowIconContainerVariant variant;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      FlowIconContainerVariant.income => FlowColors.income,
      FlowIconContainerVariant.expense => FlowColors.expense,
      FlowIconContainerVariant.transfer => Theme.of(
        context,
      ).colorScheme.primary,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Container(
      width: FlowControlSize.iconContainer,
      height: FlowControlSize.iconContainer,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
        ),
        borderRadius: BorderRadius.circular(FlowRadii.input),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/flow_colors.dart';

enum FlowAmountVariant { balance, income, expense, transfer }

class FlowAmountText extends StatelessWidget {
  const FlowAmountText({
    super.key,
    required this.amount,
    this.variant = FlowAmountVariant.balance,
    this.style,
  });
  final String amount;
  final FlowAmountVariant variant;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      FlowAmountVariant.income => FlowColors.income,
      FlowAmountVariant.expense => FlowColors.expense,
      FlowAmountVariant.transfer => Theme.of(context).colorScheme.primary,
      FlowAmountVariant.balance => Theme.of(context).colorScheme.onSurface,
    };
    return Text(
      amount,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.displaySmall?.copyWith(color: color).merge(style),
    );
  }
}

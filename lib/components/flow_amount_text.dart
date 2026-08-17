import 'package:flutter/material.dart';

import '../theme/flow_colors.dart';

enum FlowAmountVariant { balance, income, expense, transfer }

class FlowAmountText extends StatelessWidget {
  const FlowAmountText({
    super.key,
    required this.amount,
    this.variant = FlowAmountVariant.balance,
    this.style,
    this.alignment = Alignment.centerLeft,
  });
  final String amount;
  final FlowAmountVariant variant;
  final TextStyle? style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      FlowAmountVariant.income => FlowColors.income,
      FlowAmountVariant.expense => FlowColors.expense,
      FlowAmountVariant.transfer => Theme.of(context).colorScheme.primary,
      FlowAmountVariant.balance => Theme.of(context).colorScheme.onSurface,
    };
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = switch (variant) {
      FlowAmountVariant.balance => textTheme.displaySmall,
      FlowAmountVariant.income ||
      FlowAmountVariant.expense ||
      FlowAmountVariant.transfer => textTheme.labelLarge?.copyWith(
        fontSize: 16,
      ),
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        amount,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: baseStyle
            ?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            )
            .merge(style),
      ),
    );
  }
}

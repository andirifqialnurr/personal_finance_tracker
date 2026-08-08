import 'package:flutter/material.dart';

import '../theme/flow_tokens.dart';
import 'flow_amount_text.dart';
import 'flow_icon_container.dart';

class FlowTransactionTile extends StatelessWidget {
  const FlowTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.amountVariant = FlowAmountVariant.expense,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final FlowAmountVariant amountVariant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconVariant = switch (amountVariant) {
      FlowAmountVariant.income => FlowIconContainerVariant.income,
      FlowAmountVariant.expense => FlowIconContainerVariant.expense,
      FlowAmountVariant.transfer => FlowIconContainerVariant.transfer,
      FlowAmountVariant.balance => FlowIconContainerVariant.account,
    };
    return Semantics(
      button: onTap != null,
      label: '$title, $subtitle, $amount',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FlowRadii.input),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: FlowSpacing.sm),
          child: Row(
            children: [
              FlowIconContainer(icon: icon, variant: iconVariant),
              const SizedBox(width: FlowSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: FlowSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FlowSpacing.sm),
              Flexible(
                child: FlowAmountText(
                  amount: amount,
                  variant: amountVariant,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

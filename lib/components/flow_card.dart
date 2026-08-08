import 'package:flutter/material.dart';

import '../theme/flow_theme.dart';
import '../theme/flow_tokens.dart';

enum FlowCardVariant { balance, summary, chart, transaction, action }

class FlowCard extends StatelessWidget {
  const FlowCard({
    super.key,
    required this.child,
    this.variant = FlowCardVariant.summary,
  });
  final Widget child;
  final FlowCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<FlowThemeExtension>();
    final padding = variant == FlowCardVariant.balance
        ? FlowSpacing.lg
        : FlowSpacing.md;
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FlowRadii.card),
          boxShadow: extension?.shadows,
        ),
        child: child,
      ),
    );
  }
}

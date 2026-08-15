import 'package:flutter/material.dart';

import '../theme/flow_theme.dart';
import '../theme/flow_tokens.dart';

enum FlowCardVariant { balance, summary, chart, transaction, action }

enum FlowCardDensity { compact, standard, featured }

class FlowCard extends StatelessWidget {
  const FlowCard({
    super.key,
    required this.child,
    this.variant = FlowCardVariant.summary,
    this.density,
  });
  final Widget child;
  final FlowCardVariant variant;
  final FlowCardDensity? density;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<FlowThemeExtension>();
    final cardDensity = density ?? _densityForVariant(variant);
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardDensity.padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FlowRadii.card),
          boxShadow: extension?.shadows,
        ),
        child: child,
      ),
    );
  }

  static FlowCardDensity _densityForVariant(FlowCardVariant variant) =>
      switch (variant) {
        FlowCardVariant.summary => FlowCardDensity.compact,
        FlowCardVariant.action => FlowCardDensity.compact,
        FlowCardVariant.transaction => FlowCardDensity.standard,
        FlowCardVariant.balance => FlowCardDensity.featured,
        FlowCardVariant.chart => FlowCardDensity.featured,
      };
}

extension FlowCardDensityPadding on FlowCardDensity {
  double get padding => switch (this) {
    FlowCardDensity.compact => FlowSpacing.cardCompact,
    FlowCardDensity.standard => FlowSpacing.cardStandard,
    FlowCardDensity.featured => FlowSpacing.cardFeatured,
  };
}

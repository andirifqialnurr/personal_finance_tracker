import 'package:flutter/material.dart';

import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';

class FlowProgressBar extends StatelessWidget {
  const FlowProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 10,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.isFinite ? value : 0.0;
    final overRatio = safeValue <= 1
        ? 0.0
        : ((safeValue - 1) / safeValue).clamp(0.0, 1.0).toDouble();
    final trackColor = Theme.of(context).colorScheme.outline.withValues(
      alpha: 0.24,
    );
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final progressWidth = safeValue > 1
              ? width
              : width * safeValue.clamp(0.0, 1.0).toDouble();
          final overWidth = width * overRatio;
          return ClipRRect(
            borderRadius: BorderRadius.circular(FlowRadii.pill),
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: trackColor)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: progressWidth,
                    child: ColoredBox(color: color),
                  ),
                ),
                if (overWidth > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: overWidth,
                      child: const ColoredBox(color: FlowColors.expense),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

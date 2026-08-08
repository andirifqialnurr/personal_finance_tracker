import 'package:flutter/material.dart';

import '../theme/flow_colors.dart';
import '../theme/flow_tokens.dart';

enum FlowButtonVariant { primary, secondary, ghost, destructive }

class FlowButton extends StatelessWidget {
  const FlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FlowButtonVariant.primary,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final FlowButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary =
        variant == FlowButtonVariant.primary ||
        variant == FlowButtonVariant.destructive;
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(width: FlowSpacing.xs),
              Text(label),
            ],
          );
    final base = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(0, FlowControlSize.minTouchTarget),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowRadii.button),
        ),
      ),
    );
    if (primary) {
      return FilledButton(
        onPressed: onPressed,
        style: base.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            variant == FlowButtonVariant.destructive
                ? FlowColors.destructive
                : colors.primary,
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
        ),
        child: child,
      );
    }
    if (variant == FlowButtonVariant.secondary) {
      return OutlinedButton(onPressed: onPressed, style: base, child: child);
    }
    return TextButton(onPressed: onPressed, style: base, child: child);
  }
}

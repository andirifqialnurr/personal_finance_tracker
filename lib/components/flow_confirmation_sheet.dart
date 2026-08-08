import 'package:flutter/material.dart';

import '../theme/flow_tokens.dart';
import 'flow_button.dart';

class FlowConfirmationSheet extends StatelessWidget {
  const FlowConfirmationSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => FlowConfirmationSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.lg,
        FlowSpacing.sm,
        FlowSpacing.lg,
        FlowSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: FlowSpacing.xs),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FlowSpacing.lg),
          FlowButton(
            label: confirmLabel,
            variant: FlowButtonVariant.destructive,
            onPressed: onConfirm,
          ),
          const SizedBox(height: FlowSpacing.xs),
          FlowButton(
            label: 'Cancel',
            variant: FlowButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
}

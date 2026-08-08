import 'package:flutter/material.dart';

import '../theme/flow_tokens.dart';

class FlowSelector extends StatelessWidget {
  const FlowSelector({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.errorText,
  });
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '$label: $value',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FlowRadii.input),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: FlowSpacing.xs),
            ],
            Expanded(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    ),
  );
}

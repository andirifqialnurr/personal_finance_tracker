import 'package:flutter/material.dart';

import '../theme/flow_tokens.dart';

class FlowSegmentedControl extends StatelessWidget {
  const FlowSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(labels.isNotEmpty);
    assert(selectedIndex >= 0 && selectedIndex < labels.length);
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(FlowRadii.button),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlowRadii.button),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  label: labels[i],
                  child: InkWell(
                    onTap: () => onChanged(i),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: FlowControlSize.minTouchTarget,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FlowSpacing.xs,
                      ),
                      color: i == selectedIndex
                          ? colors.primary.withValues(alpha: 0.14)
                          : null,
                      child: Text(
                        labels[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

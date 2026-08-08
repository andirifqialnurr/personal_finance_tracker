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
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < labels.length; i++)
          ButtonSegment(
            value: i,
            label: Text(
              labels[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(0, FlowControlSize.minTouchTarget),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FlowRadii.button),
          ),
        ),
      ),
    );
  }
}

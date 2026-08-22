import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/components/flow_progress_bar.dart';
import 'package:personal_finance_tracker/theme/flow_colors.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 150, child: child),
      ),
    ),
  );

  testWidgets('shows a visible green segment for small budget progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const FlowProgressBar(
          value: 100000 / 1500000,
          color: FlowColors.income,
        ),
      ),
    );

    final fill = tester.getSize(find.byKey(const Key('flow-progress-fill')));
    expect(fill.width, closeTo(10, 0.1));
    expect(find.byKey(const Key('flow-progress-overfill')), findsNothing);
  });

  testWidgets('renders over-budget as full green with red overage overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const FlowProgressBar(
          value: 2000000 / 1500000,
          color: FlowColors.income,
        ),
      ),
    );

    final fill = tester.getSize(find.byKey(const Key('flow-progress-fill')));
    final overfill = tester.getSize(
      find.byKey(const Key('flow-progress-overfill')),
    );

    expect(fill.width, closeTo(150, 0.1));
    expect(overfill.width, closeTo(50, 0.1));
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:personal_finance_tracker/app.dart';

void main() {
  testWidgets('Flow starts in an empty Home state', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Start your Flow'), findsOneWidget);
    expect(find.text('You have pushed the button this many times:'), findsNothing);
  });

  testWidgets('Flow shell switches between primary destinations', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowApp());

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    expect(find.text('Transactions will appear here'), findsOneWidget);
  });
}

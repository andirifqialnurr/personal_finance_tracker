import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/components/flow_components.dart';
import 'package:personal_finance_tracker/screens/reports_page.dart';

void main() {
  testWidgets('Reports empty month uses centered text without a summary card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsPage(
            transactions: const [],
            categories: const [],
            currency: 'IDR',
            onExportMonthlyCsv: (_) async => 'report.csv',
            onExportMonthlyPdf: (_) async => 'report.pdf',
            onExportBackup: () async => 'backup.flow.local-backup',
          ),
        ),
      ),
    );

    expect(find.textContaining('No report data for this month yet'), findsOneWidget);
    expect(find.byType(FlowCard), findsNothing);
    expect(find.text('Export monthly CSV'), findsOneWidget);
    expect(find.text('Export monthly PDF'), findsOneWidget);
  });
}

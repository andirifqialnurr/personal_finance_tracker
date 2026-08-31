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
            onOpenExportedFile: (_) async {},
            onChooseExportLocation: (_) async => null,
          ),
        ),
      ),
    );

    expect(
      find.textContaining('No report data for this month yet'),
      findsOneWidget,
    );
    expect(find.byType(FlowCard), findsNothing);
    expect(find.text('Export monthly CSV'), findsOneWidget);
    expect(find.text('Export monthly PDF'), findsOneWidget);
  });

  testWidgets('exported CSV can be opened or saved to a chosen location', (
    tester,
  ) async {
    String? openedPath;
    String? locatedPath;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsPage(
            transactions: const [],
            categories: const [],
            currency: 'IDR',
            onExportMonthlyCsv: (_) async => '/exports/flow-report.csv',
            onExportMonthlyPdf: (_) async => '/exports/flow-report.pdf',
            onExportBackup: () async => '/exports/flow-backup.json',
            onOpenExportedFile: (path) async => openedPath = path,
            onChooseExportLocation: (path) async {
              locatedPath = path;
              return '/Downloads/flow-report.csv';
            },
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Export monthly CSV'));
    await tester.tap(find.text('Export monthly CSV'));
    await tester.pumpAndSettle();

    expect(find.text('CSV report ready'), findsOneWidget);
    expect(find.text('flow-report.csv'), findsOneWidget);
    expect(find.text('Open file'), findsOneWidget);
    expect(find.text('Choose file location'), findsOneWidget);

    await tester.tap(find.text('Open file'));
    await tester.pumpAndSettle();
    expect(openedPath, '/exports/flow-report.csv');

    await tester.tap(find.text('Export monthly CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose file location'));
    await tester.pumpAndSettle();
    expect(locatedPath, '/exports/flow-report.csv');
    expect(find.textContaining('Export saved to'), findsOneWidget);
  });

  testWidgets('database backup uses the same open and locate result flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsPage(
            transactions: const [],
            categories: const [],
            currency: 'IDR',
            onExportMonthlyCsv: (_) async => '/exports/flow-report.csv',
            onExportMonthlyPdf: (_) async => '/exports/flow-report.pdf',
            onExportBackup: () async => '/exports/flow-backup.json',
            onOpenExportedFile: (_) async {},
            onChooseExportLocation: (_) async => null,
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Export database backup'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Export database backup'));
    await tester.pumpAndSettle();

    expect(find.text('Database backup ready'), findsOneWidget);
    expect(find.text('flow-backup.json'), findsOneWidget);
    expect(find.text('Open file'), findsOneWidget);
    expect(find.text('Choose file location'), findsOneWidget);
  });
}

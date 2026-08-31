import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/screens/exported_file_preview_page.dart';

void main() {
  testWidgets('opens exported CSV content inside the app', (tester) async {
    final directory = await Directory.systemTemp.createTemp('flow-export-test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/flow-report.csv');
    await file.writeAsString('Date,Type,Amount\n2026-08-01,Income,100000');

    await tester.pumpWidget(
      MaterialApp(home: ExportedFilePreviewPage(path: file.path)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exported file'), findsOneWidget);
    expect(find.text('flow-report.csv'), findsOneWidget);
    expect(find.textContaining('2026-08-01,Income,100000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

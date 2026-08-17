import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:personal_finance_tracker/screens/settings_page.dart';

void main() {
  testWidgets('Settings previews and applies pasted CSV import', (tester) async {
    final timestamp = DateTime.utc(2026, 8, 17, 9);
    final preview = FlowCsvImportPreview(
      transactions: [
        Transaction(
          type: TransactionType.income,
          amount: 250000,
          accountId: 1,
          categoryId: 1,
          note: 'Freelance',
          occurredAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      ],
      errors: const [
        FlowCsvImportError(rowNumber: 4, message: 'Amount must be positive.'),
      ],
      skippedDuplicates: 2,
      matchedAccountNames: const {'Cash'},
      matchedCategoryNames: const {'Salary'},
    );
    var didPreview = false;
    var didImport = false;

    await tester.pumpWidget(
      MaterialApp(
        home: FlowSettingsPage(
          initialThemeMode: ThemeMode.light,
          onThemeModeChanged: (_) {},
          currency: 'IDR',
          onCurrencyChanged: (_) {},
          categories: const [
            Category(
              id: 1,
              name: 'Salary',
              transactionType: TransactionType.income,
              icon: 'payments',
              color: '#168C78',
            ),
          ],
          onCategoriesChanged: (_) {},
          onExportCsv: () async => 'flow.csv',
          onPreviewImportCsv: (csv) async {
            didPreview = true;
            expect(csv, contains('Date,Type,Amount'));
            return preview;
          },
          onImportCsv: (value) async {
            didImport = true;
            expect(value, same(preview));
            return 1;
          },
          onDeleteAll: () {},
          showAppBar: false,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Import CSV'));
    await tester.tap(find.text('Import CSV'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('flow-import-csv-input')),
      '${FlowCsvExporter.headers.join(',')}\n2026-08-17T09:00:00.000Z,Income,250000,Cash,,Salary,Freelance',
    );
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(didPreview, isTrue);
    expect(find.text('Preview result'), findsOneWidget);
    expect(find.text('Row 4: Amount must be positive.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(didImport, isTrue);
    expect(
      find.text('Imported 1 transactions. Skipped 2 duplicates.'),
      findsOneWidget,
    );
  });
}

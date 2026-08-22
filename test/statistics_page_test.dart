import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/components/flow_budget_progress_value.dart';
import 'package:personal_finance_tracker/components/flow_progress_bar.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/statistics_page.dart';

void main() {
  testWidgets('Statistics shows budget progress with inline amount percent', (
    tester,
  ) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    const category = Category(
      id: 11,
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsPage(
            transactions: [
              Transaction(
                id: 21,
                type: TransactionType.expense,
                amount: 100000,
                accountId: 7,
                categoryId: 11,
                occurredAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            ],
            categories: const [category],
            monthlyBudgets: [
              MonthlyBudget(
                id: 41,
                categoryId: 11,
                month: month,
                amount: 1500000,
                createdAt: now,
                updatedAt: now,
              ),
            ],
            currency: 'IDR',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    for (var attempt = 0; attempt < 6; attempt += 1) {
      if (find.text('Budget progress').evaluate().isNotEmpty) break;
      await tester.drag(list, const Offset(0, -420));
      await tester.pumpAndSettle();
    }

    expect(find.text('Budget progress'), findsOneWidget);
    expect(find.byType(FlowBudgetProgressValue), findsOneWidget);
    expect(find.byType(FlowProgressBar), findsOneWidget);

    final value = tester
        .widget<RichText>(find.descendant(
          of: find.byType(FlowBudgetProgressValue),
          matching: find.byType(RichText),
        ))
        .text
        .toPlainText();
    expect(value, 'Rp 100.000 of Rp 1.500.000 (6.7%)');
  });
}

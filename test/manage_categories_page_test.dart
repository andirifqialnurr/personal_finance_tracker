import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:personal_finance_tracker/screens/manage_categories_page.dart';

void main() {
  testWidgets('adds a custom category from Manage categories', (tester) async {
    List<Category>? changedCategories;

    await tester.pumpWidget(
      MaterialApp(
        home: ManageCategoriesPage(
          categories: const [
            Category(
              id: 1,
              name: 'Food',
              transactionType: TransactionType.expense,
              icon: 'restaurant',
              color: '#C96B6B',
            ),
          ],
          onChanged: (categories) async {
            changedCategories = categories;
            return [
              for (final category in categories)
                if (category.id == null)
                  Category(
                    id: 2,
                    name: category.name,
                    transactionType: category.transactionType,
                    icon: category.icon,
                    color: category.color,
                    isDefault: category.isDefault,
                    isArchived: category.isArchived,
                  )
                else
                  category,
            ];
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Investing');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(changedCategories, isNotNull);
    expect(changedCategories!.last.id, isNull);
    expect(changedCategories!.last.name, 'Investing');
    expect(changedCategories!.last.transactionType, TransactionType.expense);
    expect(find.text('Investing'), findsOneWidget);
  });

  testWidgets('requires unique category names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ManageCategoriesPage(
          categories: const [
            Category(
              id: 1,
              name: 'Food',
              transactionType: TransactionType.expense,
              icon: 'restaurant',
              color: '#C96B6B',
            ),
          ],
          onChanged: (categories) async => categories,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'food');
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(
      find.text('A category with this name already exists.'),
      findsOneWidget,
    );
  });
}

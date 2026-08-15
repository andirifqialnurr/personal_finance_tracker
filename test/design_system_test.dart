import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/components/flow_components.dart';
import 'package:personal_finance_tracker/theme/flow_colors.dart';
import 'package:personal_finance_tracker/theme/flow_theme.dart';
import 'package:personal_finance_tracker/theme/flow_tokens.dart';

void main() {
  Widget harness(Widget child, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: FlowTheme.light(),
      darkTheme: FlowTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(body: child),
    );
  }

  test('themes expose the shared design tokens', () {
    expect(FlowTheme.light().colorScheme.primary, FlowColors.accent);
    expect(FlowTheme.dark().brightness, Brightness.dark);
    expect(FlowRadii.card, greaterThan(FlowRadii.input));
    expect(FlowControlSize.minTouchTarget, greaterThanOrEqualTo(44));
    expect(FlowCardDensity.compact.padding, 12);
    expect(FlowCardDensity.standard.padding, 16);
    expect(FlowCardDensity.featured.padding, 20);
    expect(FlowSpacing.gapTight, 4);
    expect(FlowSpacing.gapGroup, 8);
    expect(FlowSpacing.gapBlock, 12);
    expect(FlowSpacing.gapSection, 16);
    final textTheme = FlowTheme.light().textTheme;
    expect(textTheme.labelSmall?.fontSize, 11);
    expect(textTheme.labelMedium?.fontSize, 12);
    expect(textTheme.bodyMedium?.fontSize, 13);
    expect(textTheme.titleMedium?.fontSize, 15);
    expect(textTheme.displaySmall?.fontSize, 28);
    expect(textTheme.displaySmall?.letterSpacing, 0);
  });

  testWidgets('component variants render with shared structure', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        SingleChildScrollView(
          child: Column(
            children: [
              for (final variant in FlowCardVariant.values)
                FlowCard(variant: variant, child: const Text('Card')),
              for (final variant in FlowButtonVariant.values)
                FlowButton(label: 'Action', variant: variant, onPressed: () {}),
              for (final variant in FlowAmountVariant.values)
                FlowAmountText(amount: 'Rp 1.000', variant: variant),
              for (final variant in FlowIconContainerVariant.values)
                FlowIconContainer(icon: Icons.wallet, variant: variant),
              FlowTransactionTile(
                title: 'Long transaction name',
                subtitle: 'Account · Category',
                amount: '- Rp 20.000',
                icon: Icons.receipt,
              ),
              FlowEmptyState(
                icon: Icons.wallet,
                title: 'No accounts',
                message: 'Create an account to get started.',
              ),
              FlowSegmentedControl(
                labels: const ['Expense', 'Income', 'Transfer'],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
              const FlowSelector(
                label: 'Account',
                value: 'Cash',
                icon: Icons.wallet,
              ),
              FlowButton(
                label: 'Delete',
                variant: FlowButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Card'), findsNWidgets(5));
    expect(find.text('Action'), findsNWidgets(4));
    expect(find.text('No accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('empty state remains readable at ${width.toInt()}dp', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        harness(
          const FlowEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Start your Flow',
            message:
                'Create your first account to see your balance and transactions here.',
          ),
        ),
      );

      expect(find.text('Start your Flow'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

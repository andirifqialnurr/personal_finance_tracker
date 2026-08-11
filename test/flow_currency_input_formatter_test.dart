import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/utils/flow_currency_input_formatter.dart';

void main() {
  const formatter = FlowCurrencyInputFormatter();

  TextEditingValue format(
    String text, {
    int? baseOffset,
    int? extentOffset,
  }) {
    final selection = TextSelection(
      baseOffset: baseOffset ?? text.length,
      extentOffset: extentOffset ?? baseOffset ?? text.length,
    );
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text, selection: selection),
    );
  }

  test('formats digits with thousand separators and strips other characters', () {
    expect(format('1000000').text, '1.000.000');
    expect(format('Rp 1,000,000').text, '1.000.000');
    expect(format('abc').text, isEmpty);
  });

  test('keeps the cursor after the inserted digit in the middle', () {
    final value = format('12.000', baseOffset: 2);

    expect(value.text, '12.000');
    expect(value.selection.baseOffset, 2);
  });

  test('maps a selected range through inserted separators', () {
    final value = format('1000000', baseOffset: 1, extentOffset: 4);

    expect(value.text, '1.000.000');
    expect(value.selection.baseOffset, 1);
    expect(value.selection.extentOffset, 5);
  });

  test('parses formatted values back to positive integers', () {
    expect(parseCurrencyInput('1.000.000'), 1000000);
    expect(parseCurrencyInput(''), isNull);
    expect(parseCurrencyInput('Rp 0'), 0);
  });
}

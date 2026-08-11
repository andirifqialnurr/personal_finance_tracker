import 'package:flutter/services.dart';

/// Formats an unsigned integer while the user is entering a currency amount.
///
/// The formatter keeps only digits, inserts Indonesian-style thousand
/// separators, and maps the selection back to the formatted text so editing in
/// the middle of an amount does not jump the cursor to the end.
class FlowCurrencyInputFormatter extends TextInputFormatter {
  const FlowCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(newValue.text);
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = formatCurrencyInput(digits);
    return newValue.copyWith(
      text: formatted,
      selection: _mapSelection(newValue.selection, newValue.text, formatted),
      composing: TextRange.empty,
    );
  }

  static TextSelection _mapSelection(
    TextSelection selection,
    String source,
    String formatted,
  ) {
    int mapOffset(int offset) {
      final safeOffset = offset < 0
          ? 0
          : offset > source.length
          ? source.length
          : offset;
      final digitsBefore = _digitsOnly(
        source.substring(0, safeOffset),
      ).length;
      return _formattedOffsetForDigitCount(formatted, digitsBefore);
    }

    final baseOffset = mapOffset(selection.baseOffset);
    final extentOffset = mapOffset(selection.extentOffset);
    if (selection.isCollapsed) {
      return TextSelection.collapsed(
        offset: extentOffset,
        affinity: selection.affinity,
      );
    }
    return TextSelection(
      baseOffset: baseOffset,
      extentOffset: extentOffset,
      affinity: selection.affinity,
      isDirectional: selection.isDirectional,
    );
  }

  static int _formattedOffsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var digitsSeen = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (_isDigit(formatted.codeUnitAt(index))) {
        digitsSeen++;
        if (digitsSeen == digitCount) return index + 1;
      }
    }
    return formatted.length;
  }
}

String formatCurrencyInput(String value) {
  final digits = _digitsOnly(value);
  if (digits.isEmpty) return '';
  return digits.replaceAllMapped(
    RegExp(r'(?<!^)(?=(\d{3})+$)'),
    (_) => '.',
  );
}

int? parseCurrencyInput(String value) {
  final digits = _digitsOnly(value);
  return digits.isEmpty ? null : int.tryParse(digits);
}

String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;

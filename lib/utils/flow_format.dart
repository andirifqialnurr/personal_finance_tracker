String currencySymbol(String currency) => switch (currency) {
  'USD' => '\$',
  'SGD' => 'S\$',
  _ => 'Rp',
};

String formatInteger(int value) => value.toString().replaceAllMapped(
  RegExp(r'(?<!^)(?=(\d{3})+$)'),
  (_) => '.',
);

String formatCurrency(int value, String currency) =>
    '${currencySymbol(currency)} ${formatInteger(value)}';

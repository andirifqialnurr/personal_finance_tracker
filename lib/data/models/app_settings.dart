enum ThemeModeSetting { light, dark, system }

class AppSettings {
  const AppSettings({
    this.currency = 'IDR',
    this.themeMode = ThemeModeSetting.system,
    this.hideBalance = false,
  });

  final String currency;
  final ThemeModeSetting themeMode;
  final bool hideBalance;

  factory AppSettings.fromMap(Map<String, Object?> map) => AppSettings(
    currency: map['currency'] as String,
    themeMode: ThemeModeSetting.values.byName(map['theme_mode'] as String),
    hideBalance: (map['hide_balance'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': 1,
    'currency': currency,
    'theme_mode': themeMode.name,
    'hide_balance': hideBalance ? 1 : 0,
  };
}

/// `system` remains readable for databases created by the previous MVP.
/// The current UI intentionally exposes only Light and Dark.
enum ThemeModeSetting { light, dark, system }

class AppSettings {
  const AppSettings({
    this.currency = 'IDR',
    this.themeMode = ThemeModeSetting.light,
    this.hideBalance = false,
  });

  final String currency;
  final ThemeModeSetting themeMode;
  final bool hideBalance;

  factory AppSettings.fromMap(Map<String, Object?> map) {
    final themeMode = switch (map['theme_mode'] as String?) {
      'dark' => ThemeModeSetting.dark,
      'system' => ThemeModeSetting.system,
      _ => ThemeModeSetting.light,
    };
    return AppSettings(
      currency: (map['currency'] as String?) ?? 'IDR',
      themeMode: themeMode,
      hideBalance: (map['hide_balance'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() => {
    'id': 1,
    'currency': currency,
    'theme_mode': themeMode.name,
    'hide_balance': hideBalance ? 1 : 0,
  };
}

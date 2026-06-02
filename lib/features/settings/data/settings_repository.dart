import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeightUnit { kg, lbs }

enum AppThemeMode { light, dark, system }

class AppSettings {
  final WeightUnit weightUnit;
  final double? heightCm;
  final AppThemeMode themeMode;
  final Locale locale;

  const AppSettings({
    this.weightUnit = WeightUnit.lbs,
    this.heightCm,
    this.themeMode = AppThemeMode.system,
    this.locale = const Locale('en'),
  });

  AppSettings copyWith({
    WeightUnit? weightUnit,
    double? heightCm,
    bool clearHeight = false,
    AppThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppSettings(
      weightUnit: weightUnit ?? this.weightUnit,
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get useLbs => weightUnit == WeightUnit.lbs;
  bool get useMetric => weightUnit == WeightUnit.kg;
  String get heightUnitLabel => useMetric ? 'cm' : 'ft';
  String get weightUnitLabel => useMetric ? 'kg' : 'lbs';

  double get displayHeight {
    if (heightCm == null) return 0;
    return useMetric ? heightCm! : heightCm! / 30.48;
  }

  double heightToDisplayUnit(double cm) => useMetric ? cm : cm / 30.48;
  double heightToCm(double value) => useMetric ? value : value * 30.48;

  double? calculateBmi(double weightKg) {
    if (heightCm == null || heightCm! <= 0) return null;
    final heightM = heightCm! / 100;
    return weightKg / (heightM * heightM);
  }

  String getBmiCategory(double bmi, bool isKorean) {
    if (bmi < 18.5) return isKorean ? '저체중' : 'Underweight';
    if (bmi < 25) return isKorean ? '정상' : 'Normal';
    if (bmi < 30) return isKorean ? '과체중' : 'Overweight';
    return isKorean ? '비만' : 'Obese';
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  static const _weightUnitKey = 'weight_unit';
  static const _heightCmKey = 'height_cm';
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';

  void _loadSettings() {
    final weightUnitIndex = _prefs.getInt(_weightUnitKey) ?? 1;
    final heightCm = _prefs.getDouble(_heightCmKey);
    final themeModeIndex = _prefs.getInt(_themeModeKey) ?? 2;
    final localeCode = _prefs.getString(_localeKey) ?? 'en';

    state = AppSettings(
      weightUnit: WeightUnit.values[weightUnitIndex],
      heightCm: heightCm,
      themeMode: AppThemeMode.values[themeModeIndex],
      locale: Locale(localeCode),
    );
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    await _prefs.setInt(_weightUnitKey, unit.index);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setHeightCm(double heightCm) async {
    await _prefs.setDouble(_heightCmKey, heightCm);
    state = state.copyWith(heightCm: heightCm);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_localeKey, locale.languageCode);
    state = state.copyWith(locale: locale);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

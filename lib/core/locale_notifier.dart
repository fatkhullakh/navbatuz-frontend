// lib/core/locale_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  static const _prefsKey = 'app_locale_code'; // 'en', 'ru', 'uz'
  Locale? _locale;
  Locale? get locale => _locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  LocaleNotifier() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// Directly set by language code: 'en' | 'ru' | 'uz'
  Future<void> setLocaleCode(String code) async {
    _locale = Locale(code);
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, code);
    notifyListeners();
  }

  /// Map backend enum ('EN' | 'RU' | 'UZ') to locale and set it.
  Future<void> setLocaleByBackend(String? backendCode) async {
    final s = (backendCode ?? '').toUpperCase();
    final mapped = switch (s) {
      'RU' => 'ru',
      'UZ' => 'uz',
      _ => 'en',
    };
    await setLocaleCode(mapped);
  }

  /// Reset to system
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey);
    _locale = null;
    notifyListeners();
  }
}

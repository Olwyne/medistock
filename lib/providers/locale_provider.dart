import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLocale = 'locale'; // 'fr' | 'en' | '' for system

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLocale);
    _locale = code == null || code.isEmpty ? null : Locale(code);
    notifyListeners();
  }

  Future<void> setLocale(Locale? value) async {
    _locale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, value?.languageCode ?? '');
    notifyListeners();
  }
}

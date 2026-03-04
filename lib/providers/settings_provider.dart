import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyFirstDayOfWeek = 'first_day_of_week'; // 0 = Sunday, 1 = Monday
const _keyScanSound = 'scan_sound';
const _keyOnboardingDone = 'onboarding_done';

class SettingsProvider extends ChangeNotifier {
  int _firstDayOfWeek = 1; // Monday default
  bool _scanSound = true;
  bool _onboardingDone = false;

  int get firstDayOfWeek => _firstDayOfWeek;
  bool get scanSound => _scanSound;
  bool get onboardingDone => _onboardingDone;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _firstDayOfWeek = prefs.getInt(_keyFirstDayOfWeek) ?? 1;
    _scanSound = prefs.getBool(_keyScanSound) ?? true;
    _onboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
    notifyListeners();
  }

  Future<void> setFirstDayOfWeek(int value) async {
    _firstDayOfWeek = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFirstDayOfWeek, value);
    notifyListeners();
  }

  Future<void> setScanSound(bool value) async {
    _scanSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyScanSound, value);
    notifyListeners();
  }

  Future<void> setOnboardingDone(bool value) async {
    _onboardingDone = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, value);
    notifyListeners();
  }
}

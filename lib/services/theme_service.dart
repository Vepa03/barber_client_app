import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _key = 'theme_mode';
  static final notifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    notifier.value = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggle() async {
    final next = notifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next == ThemeMode.dark ? 'dark' : 'light');
  }

  static bool get isDark => notifier.value == ThemeMode.dark;
}

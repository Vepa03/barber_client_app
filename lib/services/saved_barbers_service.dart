import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barber_model.dart';

class SavedBarbersService {
  static const _key = 'saved_barbers';

  static Future<List<Barber>> getSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => Barber.fromSavedJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> isSaved(String id) async {
    final saved = await getSaved();
    return saved.any((b) => b.id == id);
  }

  static Future<void> save(Barber barber) async {
    final prefs  = await SharedPreferences.getInstance();
    final raw    = prefs.getStringList(_key) ?? [];
    if (raw.any((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == barber.id;
    })) return;
    raw.add(jsonEncode(barber.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> unsave(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == id;
    });
    await prefs.setStringList(_key, raw);
  }

  static Future<bool> toggle(Barber barber) async {
    if (await isSaved(barber.id)) {
      await unsave(barber.id);
      return false;
    } else {
      await save(barber);
      return true;
    }
  }
}

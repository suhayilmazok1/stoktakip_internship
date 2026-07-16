import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences ile yerel veri depolamayı yöneten singleton sınıf.
class LocalStorageManager {
  LocalStorageManager._();
  static final LocalStorageManager instance = LocalStorageManager._();

  late final SharedPreferences _prefs;

  /// SharedPreferences nesnesini başlatır. main() fonksiyonu içinde çağrılmalıdır.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Okuma (Read) ──
  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);

  // ── Yazma / Ekleme (Write / Set) ──
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  // ── Silme (Delete / Remove) ──
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

/// Service penyimpanan lokal menggunakan SharedPreferences
/// untuk menyimpan lokasi favorit, riwayat pencarian, dan lokasi terakhir dipilih.
class LocalStorageService {
  static const String _favoritesKey = 'favorite_locations';
  static const String _historyKey = 'search_history';
  static const String _selectedLocationKey = 'selected_location';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Mengambil daftar lokasi favorit yang tersimpan.
  Future<List<LocationModel>> getFavorites() async {
    final prefs = await _prefs;
    return _readLocationList(prefs, _favoritesKey);
  }

  /// Menyimpan daftar lokasi favorit ke Local Storage.
  Future<void> saveFavorites(List<LocationModel> favorites) async {
    final prefs = await _prefs;
    await _writeLocationList(prefs, _favoritesKey, favorites);
  }

  /// Mengambil riwayat pencarian lokasi yang tersimpan.
  Future<List<LocationModel>> getSearchHistory() async {
    final prefs = await _prefs;
    return _readLocationList(prefs, _historyKey);
  }

  /// Menyimpan riwayat pencarian lokasi ke Local Storage.
  Future<void> saveSearchHistory(List<LocationModel> history) async {
    final prefs = await _prefs;
    await _writeLocationList(prefs, _historyKey, history);
  }

  /// Mengambil lokasi terakhir yang dipilih pengguna.
  Future<LocationModel?> getSelectedLocation() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_selectedLocationKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return LocationModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan lokasi terakhir yang dipilih pengguna.
  Future<void> saveSelectedLocation(LocationModel location) async {
    final prefs = await _prefs;
    await prefs.setString(_selectedLocationKey, jsonEncode(location.toJson()));
  }

  List<LocationModel> _readLocationList(SharedPreferences prefs, String key) {
    final rawList = prefs.getStringList(key);
    if (rawList == null) return [];
    final locations = <LocationModel>[];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        locations.add(LocationModel.fromJson(decoded));
      } catch (_) {
        // Lewati entri yang korup agar aplikasi tetap stabil.
      }
    }
    return locations;
  }

  Future<void> _writeLocationList(
    SharedPreferences prefs,
    String key,
    List<LocationModel> items,
  ) async {
    final encoded = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(key, encoded);
  }
}

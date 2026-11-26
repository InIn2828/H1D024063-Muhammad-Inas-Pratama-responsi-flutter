import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status state untuk pencarian lokasi kota.
enum SearchStatus { idle, loading, loaded, empty, error }

/// ViewModel untuk Search / Location Screen (pola MVVM).
/// Mengelola pencarian kota melalui Open-Meteo Geocoding API
/// serta riwayat pencarian yang disimpan di Local Storage.
class SearchViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  static const int _maxHistoryItems = 10;

  SearchViewModel({
    WeatherApiService? apiService,
    LocalStorageService? storageService,
  })  : _apiService = apiService ?? WeatherApiService(),
        _storageService = storageService ?? LocalStorageService();

  SearchStatus _status = SearchStatus.idle;
  List<LocationModel> _results = [];
  List<LocationModel> _history = [];
  String _lastQuery = '';
  String? _errorMessage;

  SearchStatus get status => _status;
  List<LocationModel> get results => List.unmodifiable(_results);
  List<LocationModel> get history => List.unmodifiable(_history);
  String get lastQuery => _lastQuery;
  String? get errorMessage => _errorMessage;

  /// Memuat riwayat pencarian lokasi dari Local Storage.
  Future<void> loadHistory() async {
    _history = await _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Melakukan pencarian kota ke Open-Meteo Geocoding API.
  Future<void> searchCities(String query) async {
    final trimmed = query.trim();
    _lastQuery = trimmed;

    if (trimmed.isEmpty) {
      _results = [];
      _status = SearchStatus.idle;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = SearchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final locations = await _apiService.searchLocations(trimmed);
      _results = locations;
      _status =
          locations.isEmpty ? SearchStatus.empty : SearchStatus.loaded;
    } catch (e) {
      _results = [];
      _errorMessage = e.toString();
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  /// Menyimpan lokasi yang dipilih ke riwayat pencarian di Local Storage.
  Future<void> addToHistory(LocationModel location) async {
    _history.removeWhere((item) => item.uniqueKey == location.uniqueKey);
    _history.insert(0, location);
    if (_history.length > _maxHistoryItems) {
      _history = _history.sublist(0, _maxHistoryItems);
    }
    await _storageService.saveSearchHistory(_history);
    notifyListeners();
  }

  /// Menghapus satu item dari riwayat pencarian.
  Future<void> removeFromHistory(LocationModel location) async {
    _history.removeWhere((item) => item.uniqueKey == location.uniqueKey);
    await _storageService.saveSearchHistory(_history);
    notifyListeners();
  }

  /// Menghapus seluruh riwayat pencarian.
  Future<void> clearHistory() async {
    _history.clear();
    await _storageService.saveSearchHistory(_history);
    notifyListeners();
  }

  /// Mengatur ulang hasil pencarian ke kondisi awal.
  void clearResults() {
    _results = [];
    _lastQuery = '';
    _status = SearchStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}

import 'package:material_ui/material_ui.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status state untuk pengambilan data cuaca.
enum WeatherStatus { initial, loading, loaded, empty, error }

/// ViewModel utama untuk Home / Weather Screen (pola MVVM).
/// Mengelola state lokasi terpilih, data cuaca dari Open-Meteo API,
/// daftar lokasi favorit di Local Storage, dan tema aplikasi.
class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  static const LocationModel defaultLocation = LocationModel(
    name: 'Jakarta',
    latitude: -6.2088,
    longitude: 106.8456,
    country: 'Indonesia',
    admin1: 'DKI Jakarta',
  );

  WeatherViewModel({
    WeatherApiService? apiService,
    LocalStorageService? storageService,
  })  : _apiService = apiService ?? WeatherApiService(),
        _storageService = storageService ?? LocalStorageService();

  WeatherStatus _status = WeatherStatus.initial;
  LocationModel _selectedLocation = defaultLocation;
  WeatherResponse? _weather;
  String? _errorMessage;
  List<LocationModel> _favorites = [];
  ThemeMode _themeMode = ThemeMode.light;

  WeatherStatus get status => _status;
  LocationModel get selectedLocation => _selectedLocation;
  WeatherResponse? get weather => _weather;
  String? get errorMessage => _errorMessage;
  List<LocationModel> get favorites => List.unmodifiable(_favorites);
  ThemeMode get themeMode => _themeMode;

  /// Inisialisasi awal: muat favorit & lokasi terakhir dari Local Storage,
  /// lalu ambil data cuaca dari Open-Meteo API.
  Future<void> initialize() async {
    _favorites = await _storageService.getFavorites();
    final savedLocation = await _storageService.getSelectedLocation();
    if (savedLocation != null) {
      _selectedLocation = savedLocation;
    }
    notifyListeners();
    await fetchWeatherForCurrentLocation();
  }

  /// Mengambil data cuaca terbaru untuk [_selectedLocation].
  Future<void> fetchWeatherForCurrentLocation() async {
    _status = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      if (response.daily.isEmpty) {
        _weather = null;
        _status = WeatherStatus.empty;
      } else {
        _weather = response;
        _status = WeatherStatus.loaded;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = WeatherStatus.error;
    }
    notifyListeners();
  }

  /// Mengganti lokasi yang dipilih, menyimpannya ke Local Storage,
  /// dan memuat ulang data cuaca dari API.
  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    await _storageService.saveSelectedLocation(location);
    notifyListeners();
    await fetchWeatherForCurrentLocation();
  }

  /// Mengecek apakah [location] sudah tersimpan di daftar favorit.
  bool isFavorite(LocationModel location) {
    return _favorites.any((item) => item.uniqueKey == location.uniqueKey);
  }

  /// Menambah atau menghapus [location] dari daftar favorit di Local Storage.
  Future<void> toggleFavorite(LocationModel location) async {
    final index =
        _favorites.indexWhere((item) => item.uniqueKey == location.uniqueKey);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.insert(0, location);
    }
    await _storageService.saveFavorites(_favorites);
    notifyListeners();
  }

  /// Mengubah tema antara Light Mode dan Dark Mode.
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

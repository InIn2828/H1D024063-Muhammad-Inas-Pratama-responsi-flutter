import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:responsi_pemmob2/models/location_model.dart';
import 'package:responsi_pemmob2/models/weather_model.dart';
import 'package:responsi_pemmob2/services/local_storage_service.dart';
import 'package:responsi_pemmob2/services/weather_api_service.dart';
import 'package:responsi_pemmob2/viewmodels/search_viewmodel.dart';
import 'package:responsi_pemmob2/viewmodels/weather_viewmodel.dart';
import 'package:responsi_pemmob2/views/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sampleWeatherJson = {
    'latitude': -6.2,
    'longitude': 106.8,
    'timezone': 'Asia/Jakarta',
    'current': {
      'time': '2026-11-26T09:00',
      'temperature_2m': 30.5,
      'relative_humidity_2m': 72,
      'apparent_temperature': 34.2,
      'precipitation': 0.2,
      'weather_code': 2,
      'wind_speed_10m': 12.4,
    },
    'daily': {
      'time': ['2026-11-26', '2026-11-27'],
      'weather_code': [2, 61],
      'temperature_2m_max': [33.0, 31.5],
      'temperature_2m_min': [25.0, 24.5],
      'precipitation_probability_max': [40, 80],
    },
  };

  const sampleGeocodingJson = {
    'results': [
      {
        'id': 1621177,
        'name': 'Yogyakarta',
        'latitude': -7.7956,
        'longitude': 110.3695,
        'country': 'Indonesia',
        'admin1': 'DI Yogyakarta',
      },
    ],
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model & API Service Tests', () {
    test('WeatherResponse.fromJson parses all required Open-Meteo fields', () {
      final response = WeatherResponse.fromJson(sampleWeatherJson);

      expect(response.timezone, 'Asia/Jakarta');
      expect(response.current.temperature2m, 30.5);
      expect(response.current.relativeHumidity2m, 72);
      expect(response.current.apparentTemperature, 34.2);
      expect(response.current.precipitation, 0.2);
      expect(response.current.weatherCode, 2);
      expect(response.current.windSpeed10m, 12.4);
      expect(response.daily.length, 2);
      expect(response.daily.first.temperature2mMax, 33.0);
      expect(response.daily.first.temperature2mMin, 25.0);
      expect(response.daily.first.precipitationProbabilityMax, 40);
    });

    test('WeatherApiService.fetchWeather sends GET with expected query params',
        () async {
      late Uri capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        expect(request.method, 'GET');
        return http.Response(jsonEncode(sampleWeatherJson), 200);
      });

      final service = WeatherApiService(client: mockClient);
      final result = await service.fetchWeather(
        latitude: -6.2088,
        longitude: 106.8456,
      );

      expect(capturedUri.host, 'api.open-meteo.com');
      expect(capturedUri.path, '/v1/forecast');
      expect(capturedUri.queryParameters['timezone'], 'auto');
      expect(capturedUri.queryParameters['current'], contains('temperature_2m'));
      expect(
        capturedUri.queryParameters['daily'],
        contains('precipitation_probability_max'),
      );
      expect(result.current.temperature2m, 30.5);
    });

    test('WeatherApiService.fetchWeather throws WeatherApiException on error',
        () async {
      final mockClient = MockClient(
        (_) async => http.Response('Server Error', 500),
      );
      final service = WeatherApiService(client: mockClient);

      expect(
        () => service.fetchWeather(latitude: 0, longitude: 0),
        throwsA(isA<WeatherApiException>()),
      );
    });
  });

  group('ViewModel & LocalStorage Tests', () {
    test('WeatherViewModel loads weather and persists favorites', () async {
      final mockClient = MockClient(
        (_) async => http.Response(jsonEncode(sampleWeatherJson), 200),
      );
      final viewModel = WeatherViewModel(
        apiService: WeatherApiService(client: mockClient),
        storageService: LocalStorageService(),
      );

      await viewModel.initialize();
      expect(viewModel.status, WeatherStatus.loaded);
      expect(viewModel.weather?.current.temperature2m, 30.5);

      const yogya = LocationModel(
        name: 'Yogyakarta',
        latitude: -7.7956,
        longitude: 110.3695,
        country: 'Indonesia',
        admin1: 'DI Yogyakarta',
      );
      await viewModel.toggleFavorite(yogya);
      expect(viewModel.isFavorite(yogya), isTrue);
      expect(viewModel.favorites.length, 1);

      // Verifikasi data tersimpan di SharedPreferences dan terbaca ulang.
      final storage = LocalStorageService();
      final savedFavorites = await storage.getFavorites();
      expect(savedFavorites.length, 1);
      expect(savedFavorites.first.name, 'Yogyakarta');
    });

    test('SearchViewModel searches cities and stores history', () async {
      final mockClient = MockClient(
        (_) async => http.Response(jsonEncode(sampleGeocodingJson), 200),
      );
      final searchVm = SearchViewModel(
        apiService: WeatherApiService(client: mockClient),
        storageService: LocalStorageService(),
      );

      await searchVm.searchCities('Yogyakarta');
      expect(searchVm.status, SearchStatus.loaded);
      expect(searchVm.results.length, 1);
      expect(searchVm.results.first.name, 'Yogyakarta');

      await searchVm.addToHistory(searchVm.results.first);
      expect(searchVm.history.length, 1);
    });
  });

  group('Widget Tests', () {
    testWidgets('HomeScreen renders weather data from ViewModel',
        (tester) async {
      final mockClient = MockClient(
        (_) async => http.Response(jsonEncode(sampleWeatherJson), 200),
      );
      final weatherVm = WeatherViewModel(
        apiService: WeatherApiService(client: mockClient),
        storageService: LocalStorageService(),
      );
      final searchVm = SearchViewModel(
        apiService: WeatherApiService(client: mockClient),
        storageService: LocalStorageService(),
      );

      await weatherVm.initialize();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: weatherVm),
            ChangeNotifierProvider.value(value: searchVm),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jakarta'), findsWidgets);
      expect(find.text('30.5°C'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('Prakiraan Beberapa Hari Ke Depan'), findsOneWidget);
    });
  });
}

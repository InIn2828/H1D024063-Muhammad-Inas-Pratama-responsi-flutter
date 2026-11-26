import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';
import '../models/weather_model.dart';

/// Exception khusus untuk error dari Open-Meteo API.
class WeatherApiException implements Exception {
  final String message;
  const WeatherApiException(this.message);

  @override
  String toString() => message;
}

/// Service untuk berkomunikasi dengan Open-Meteo REST API
/// (Weather Forecast API & Geocoding API) menggunakan HTTP GET.
class WeatherApiService {
  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mengambil data cuaca terkini dan prakiraan harian berdasarkan koordinat.
  Future<WeatherResponse> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
    });

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw WeatherApiException(
          'Gagal memuat data cuaca (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['current'] == null || decoded['daily'] == null) {
        throw const WeatherApiException(
          'Format data cuaca dari server tidak lengkap.',
        );
      }

      return WeatherResponse.fromJson(decoded);
    } on SocketException {
      throw const WeatherApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda.',
      );
    } on TimeoutException {
      throw const WeatherApiException(
        'Permintaan ke server cuaca melebihi batas waktu.',
      );
    } on FormatException {
      throw const WeatherApiException(
        'Gagal membaca respons JSON dari server cuaca.',
      );
    }
  }

  /// Mencari daftar kota berdasarkan kata kunci menggunakan Open-Meteo Geocoding API.
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': trimmed,
      'count': '10',
      'language': 'id',
      'format': 'json',
    });

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw WeatherApiException(
          'Gagal mencari lokasi (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return [];
      }

      return results
          .map((item) =>
              LocationModel.fromGeocodingJson(item as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const WeatherApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda.',
      );
    } on TimeoutException {
      throw const WeatherApiException(
        'Pencarian lokasi melebihi batas waktu.',
      );
    } on FormatException {
      throw const WeatherApiException(
        'Gagal membaca hasil pencarian lokasi.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Model data untuk merepresentasikan lokasi kota dari Open-Meteo Geocoding API
/// maupun penyimpanan lokal (SharedPreferences).
class LocationModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin1;

  const LocationModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin1,
  });

  /// Membuat [LocationModel] dari respons JSON Open-Meteo Geocoding API.
  factory LocationModel.fromGeocodingJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }

  /// Membuat [LocationModel] dari JSON yang tersimpan di Local Storage.
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      country: json['country'] as String?,
      admin1: json['admin1'] as String?,
    );
  }

  /// Mengonversi [LocationModel] menjadi Map JSON untuk disimpan di Local Storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'admin1': admin1,
    };
  }

  /// Key unik berdasarkan koordinat untuk identifikasi duplikat lokasi.
  String get uniqueKey =>
      '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';

  /// Subtitle lokasi yang informatif (provinsi/negara).
  String get displaySubtitle {
    final parts = <String>[
      if (admin1 != null && admin1!.isNotEmpty) admin1!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel && other.uniqueKey == uniqueKey;
  }

  @override
  int get hashCode => uniqueKey.hashCode;
}

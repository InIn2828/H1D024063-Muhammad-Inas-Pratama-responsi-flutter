import 'package:material_ui/material_ui.dart';

/// Informasi tampilan untuk kode cuaca WMO dari Open-Meteo.
class WeatherConditionInfo {
  final String label;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;

  const WeatherConditionInfo({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
  });
}

/// Helper untuk menerjemahkan `weather_code` (WMO) dari Open-Meteo
/// menjadi deskripsi, ikon Material, dan skema warna.
class WeatherCodeHelper {
  WeatherCodeHelper._();

  static WeatherConditionInfo getInfo(int code) {
    switch (code) {
      case 0:
        return const WeatherConditionInfo(
          label: 'Cerah',
          icon: Icons.wb_sunny_rounded,
          accentColor: Color(0xFFFFB300),
          gradientColors: [Color(0xFF1E88E5), Color(0xFF4FC3F7)],
        );
      case 1:
        return const WeatherConditionInfo(
          label: 'Cerah Berawan',
          icon: Icons.wb_sunny_outlined,
          accentColor: Color(0xFFFFCA28),
          gradientColors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
        );
      case 2:
        return const WeatherConditionInfo(
          label: 'Berawan Sebagian',
          icon: Icons.cloud_queue_rounded,
          accentColor: Color(0xFF90CAF9),
          gradientColors: [Color(0xFF283593), Color(0xFF5C6BC0)],
        );
      case 3:
        return const WeatherConditionInfo(
          label: 'Mendung',
          icon: Icons.cloud_rounded,
          accentColor: Color(0xFFB0BEC5),
          gradientColors: [Color(0xFF455A64), Color(0xFF78909C)],
        );
      case 45:
      case 48:
        return const WeatherConditionInfo(
          label: 'Berkabut',
          icon: Icons.foggy,
          accentColor: Color(0xFFCFD8DC),
          gradientColors: [Color(0xFF546E7A), Color(0xFF90A4AE)],
        );
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return const WeatherConditionInfo(
          label: 'Gerimis',
          icon: Icons.grain_rounded,
          accentColor: Color(0xFF4DD0E1),
          gradientColors: [Color(0xFF00695C), Color(0xFF26A69A)],
        );
      case 61:
      case 63:
      case 66:
        return const WeatherConditionInfo(
          label: 'Hujan Ringan',
          icon: Icons.water_drop_outlined,
          accentColor: Color(0xFF29B6F6),
          gradientColors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        );
      case 65:
      case 67:
      case 80:
      case 81:
      case 82:
        return const WeatherConditionInfo(
          label: 'Hujan Lebat',
          icon: Icons.water_drop_rounded,
          accentColor: Color(0xFF0288D1),
          gradientColors: [Color(0xFF1A237E), Color(0xFF283593)],
        );
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return const WeatherConditionInfo(
          label: 'Salju',
          icon: Icons.ac_unit_rounded,
          accentColor: Color(0xFFE1F5FE),
          gradientColors: [Color(0xFF37474F), Color(0xFF607D8B)],
        );
      case 95:
      case 96:
      case 99:
        return const WeatherConditionInfo(
          label: 'Badai Petir',
          icon: Icons.thunderstorm_rounded,
          accentColor: Color(0xFFFFD54F),
          gradientColors: [Color(0xFF212121), Color(0xFF4A148C)],
        );
      default:
        return const WeatherConditionInfo(
          label: 'Tidak Diketahui',
          icon: Icons.help_outline_rounded,
          accentColor: Color(0xFFB0BEC5),
          gradientColors: [Color(0xFF37474F), Color(0xFF546E7A)],
        );
    }
  }
}

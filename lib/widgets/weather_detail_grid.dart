import 'package:material_ui/material_ui.dart';

import '../models/weather_model.dart';

/// Widget responsif untuk menampilkan metrik detail cuaca terkini:
/// kelembapan, kecepatan angin, curah hujan, peluang hujan, serta suhu min/max hari ini.
class WeatherDetailGrid extends StatelessWidget {
  final CurrentWeather current;
  final DailyForecast? todayForecast;

  const WeatherDetailGrid({
    super.key,
    required this.current,
    this.todayForecast,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MetricItem>[
      _MetricItem(
        icon: Icons.water_drop_outlined,
        label: 'Kelembapan',
        value: '${current.relativeHumidity2m}%',
        color: Colors.lightBlue,
      ),
      _MetricItem(
        icon: Icons.air_rounded,
        label: 'Kecepatan Angin',
        value: '${current.windSpeed10m.toStringAsFixed(1)} km/j',
        color: Colors.teal,
      ),
      _MetricItem(
        icon: Icons.umbrella_rounded,
        label: 'Curah Hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
        color: Colors.indigo,
      ),
      _MetricItem(
        icon: Icons.cloudy_snowing,
        label: 'Peluang Hujan',
        value: '${todayForecast?.precipitationProbabilityMax ?? 0}%',
        color: Colors.blueAccent,
      ),
      _MetricItem(
        icon: Icons.thermostat_rounded,
        label: 'Terasa Seperti',
        value: '${current.apparentTemperature.toStringAsFixed(1)}°C',
        color: Colors.orange,
      ),
      if (todayForecast != null)
        _MetricItem(
          icon: Icons.swap_vert_rounded,
          label: 'Min / Maks Hari Ini',
          value:
              '${todayForecast!.temperature2mMin.toStringAsFixed(0)}° / ${todayForecast!.temperature2mMax.toStringAsFixed(0)}°',
          color: Colors.deepOrange,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth >= 600 ? 2.1 : 1.75,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 18, color: item.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.label,
                            style: Theme.of(context).textTheme.labelMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

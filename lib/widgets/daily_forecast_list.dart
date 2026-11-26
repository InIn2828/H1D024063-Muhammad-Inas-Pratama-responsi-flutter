import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/weather_model.dart';
import '../utils/weather_code_helper.dart';

/// Widget untuk menampilkan daftar prakiraan cuaca beberapa hari ke depan.
class DailyForecastList extends StatelessWidget {
  final List<DailyForecast> forecasts;

  const DailyForecastList({
    super.key,
    required this.forecasts,
  });

  String _formatDayLabel(DateTime date, int index) {
    if (index == 0) return 'Hari Ini';
    if (index == 1) return 'Besok';
    return DateFormat('EEE, d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: List.generate(forecasts.length, (index) {
            final item = forecasts[index];
            final condition = WeatherCodeHelper.getInfo(item.weatherCode);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDayLabel(item.date, index),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              condition.label,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              condition.icon,
                              color: condition.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.precipitationProbabilityMax}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.lightBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.temperature2mMin.toStringAsFixed(0)}° / ${item.temperature2mMax.toStringAsFixed(0)}°',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < forecasts.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.15),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

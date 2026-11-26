/// Model data cuaca terkini dari field `current` pada Open-Meteo API.
class CurrentWeather {
  final double temperature2m;
  final int relativeHumidity2m;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;
  final String time;

  const CurrentWeather({
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.time,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature2m: (json['temperature_2m'] as num).toDouble(),
      relativeHumidity2m: (json['relative_humidity_2m'] as num).toInt(),
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      windSpeed10m: (json['wind_speed_10m'] as num).toDouble(),
      time: json['time'] as String? ?? '',
    );
  }
}

/// Model data prakiraan cuaca harian dari field `daily` pada Open-Meteo API.
class DailyForecast {
  final DateTime date;
  final double temperature2mMax;
  final double temperature2mMin;
  final int precipitationProbabilityMax;
  final int weatherCode;

  const DailyForecast({
    required this.date,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationProbabilityMax,
    required this.weatherCode,
  });
}

/// Model respons lengkap dari Open-Meteo Weather Forecast API.
class WeatherResponse {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;

  const WeatherResponse({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    required this.daily,
  });

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;

    final times = (dailyJson['time'] as List<dynamic>).cast<String>();
    final maxTemps = (dailyJson['temperature_2m_max'] as List<dynamic>);
    final minTemps = (dailyJson['temperature_2m_min'] as List<dynamic>);
    final precipProbs =
        (dailyJson['precipitation_probability_max'] as List<dynamic>);
    final weatherCodes = (dailyJson['weather_code'] as List<dynamic>);

    final dailyList = <DailyForecast>[];
    for (int i = 0; i < times.length; i++) {
      dailyList.add(
        DailyForecast(
          date: DateTime.parse(times[i]),
          temperature2mMax: (maxTemps[i] as num).toDouble(),
          temperature2mMin: (minTemps[i] as num).toDouble(),
          precipitationProbabilityMax:
              (precipProbs[i] as num?)?.toInt() ?? 0,
          weatherCode: (weatherCodes[i] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return WeatherResponse(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'auto',
      current: CurrentWeather.fromJson(currentJson),
      daily: dailyList,
    );
  }
}

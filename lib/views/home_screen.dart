import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../utils/weather_code_helper.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/weather_detail_grid.dart';
import 'search_screen.dart';

/// Home / Weather Screen (View dalam arsitektur MVVM).
/// Menggunakan [StatelessWidget] yang mengamati perubahan state pada [WeatherViewModel].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSearchScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherViewModel>(
      builder: (context, viewModel, _) {
        final location = viewModel.selectedLocation;
        final isFav = viewModel.isFavorite(location);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name),
                Text(
                  location.displaySubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: isFav ? 'Hapus dari favorit' : 'Simpan ke favorit',
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFav ? Colors.amber : null,
                ),
                onPressed: () => viewModel.toggleFavorite(location),
              ),
              IconButton(
                tooltip: 'Ganti Tema',
                icon: Icon(
                  viewModel.themeMode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                onPressed: viewModel.toggleTheme,
              ),
              IconButton(
                tooltip: 'Cari Lokasi',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => _openSearchScreen(context),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: viewModel.fetchWeatherForCurrentLocation,
              child: _buildBody(context, viewModel),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WeatherViewModel viewModel) {
    switch (viewModel.status) {
      case WeatherStatus.initial:
      case WeatherStatus.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 16),
            Center(child: Text('Memuat data cuaca terkini...')),
          ],
        );

      case WeatherStatus.empty:
        return _StateMessageView(
          icon: Icons.cloud_off_rounded,
          title: 'Data Cuaca Kosong',
          message: 'Server tidak mengembalikan data prakiraan untuk lokasi ini.',
          onRetry: viewModel.fetchWeatherForCurrentLocation,
          onSearch: () => _openSearchScreen(context),
        );

      case WeatherStatus.error:
        return _StateMessageView(
          icon: Icons.wifi_off_rounded,
          title: 'Gagal Memuat Cuaca',
          message: viewModel.errorMessage ??
              'Terjadi kesalahan saat menghubungi Open-Meteo API.',
          onRetry: viewModel.fetchWeatherForCurrentLocation,
          onSearch: () => _openSearchScreen(context),
        );

      case WeatherStatus.loaded:
        final weather = viewModel.weather!;
        final current = weather.current;
        final condition = WeatherCodeHelper.getInfo(current.weatherCode);
        final todayForecast =
            weather.daily.isNotEmpty ? weather.daily.first : null;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (viewModel.favorites.isNotEmpty) ...[
                  _FavoriteQuickBar(
                    favorites: viewModel.favorites,
                    selectedLocation: viewModel.selectedLocation,
                    onSelect: viewModel.selectLocation,
                  ),
                  const SizedBox(height: 12),
                ],
                _CurrentWeatherHeroCard(
                  cityName: viewModel.selectedLocation.name,
                  condition: condition,
                  temperature: current.temperature2m,
                  apparentTemperature: current.apparentTemperature,
                  timezone: weather.timezone,
                ),
                const SizedBox(height: 20),
                Text(
                  'Detail Kondisi Saat Ini',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                WeatherDetailGrid(
                  current: current,
                  todayForecast: todayForecast,
                ),
                const SizedBox(height: 24),
                Text(
                  'Prakiraan Beberapa Hari Ke Depan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DailyForecastList(forecasts: weather.daily),
              ],
            ),
          ),
        );
    }
  }
}

class _FavoriteQuickBar extends StatelessWidget {
  final List<LocationModel> favorites;
  final LocationModel selectedLocation;
  final ValueChanged<LocationModel> onSelect;

  const _FavoriteQuickBar({
    required this.favorites,
    required this.selectedLocation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fav = favorites[index];
          final isSelected = fav.uniqueKey == selectedLocation.uniqueKey;
          return ChoiceChip(
            label: Text(fav.name),
            selected: isSelected,
            avatar: Icon(
              Icons.star_rounded,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.amber,
            ),
            onSelected: (_) => onSelect(fav),
          );
        },
      ),
    );
  }
}

class _CurrentWeatherHeroCard extends StatelessWidget {
  final String cityName;
  final WeatherConditionInfo condition;
  final double temperature;
  final double apparentTemperature;
  final String timezone;

  const _CurrentWeatherHeroCard({
    required this.cityName,
    required this.condition,
    required this.temperature,
    required this.apparentTemperature,
    required this.timezone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: condition.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: condition.gradientColors.first.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zona Waktu: $timezone',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                condition.icon,
                size: 56,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cityName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  Text(
                    'Terasa ${apparentTemperature.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSearch;

  const _StateMessageView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
            OutlinedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Cari Kota Lain'),
            ),
          ],
        ),
      ],
    );
  }
}

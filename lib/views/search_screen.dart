import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/search_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';

/// Search / Location Screen (View dalam arsitektur MVVM).
/// Menggunakan [StatefulWidget] untuk mengelola input pencarian kota,
/// debounce request API, serta menampilkan daftar favorit & riwayat pencarian.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().loadHistory();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<SearchViewModel>().searchCities(value);
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    context.read<SearchViewModel>().searchCities(value);
  }

  Future<void> _selectLocation(LocationModel location) async {
    final searchVm = context.read<SearchViewModel>();
    final weatherVm = context.read<WeatherViewModel>();

    await searchVm.addToHistory(location);
    if (!mounted) return;
    Navigator.of(context).pop();
    await weatherVm.selectLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari & Kelola Lokasi'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: _submitSearch,
                    decoration: InputDecoration(
                      hintText: 'Cari nama kota (contoh: Yogyakarta, Tokyo)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Bersihkan',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                context.read<SearchViewModel>().clearResults();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer2<SearchViewModel, WeatherViewModel>(
                    builder: (context, searchVm, weatherVm, _) {
                      if (_searchController.text.trim().isNotEmpty) {
                        return _buildSearchResults(searchVm, weatherVm);
                      }
                      return _buildSavedLocations(searchVm, weatherVm);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    SearchViewModel searchVm,
    WeatherViewModel weatherVm,
  ) {
    switch (searchVm.status) {
      case SearchStatus.idle:
      case SearchStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Mencari lokasi...'),
            ],
          ),
        );

      case SearchStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_rounded, size: 56),
                const SizedBox(height: 12),
                Text(
                  'Kota "${searchVm.lastQuery}" tidak ditemukan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Coba periksa ejaan atau gunakan nama kota lain.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );

      case SearchStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 12),
                Text(
                  searchVm.errorMessage ?? 'Gagal mencari kota.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => searchVm.searchCities(_searchController.text),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        );

      case SearchStatus.loaded:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: searchVm.results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final location = searchVm.results[index];
            final isFav = weatherVm.isFavorite(location);
            return _LocationTile(
              location: location,
              isFavorite: isFav,
              onTap: () => _selectLocation(location),
              onToggleFavorite: () => weatherVm.toggleFavorite(location),
            );
          },
        );
    }
  }

  Widget _buildSavedLocations(
    SearchViewModel searchVm,
    WeatherViewModel weatherVm,
  ) {
    final favorites = weatherVm.favorites;
    final history = searchVm.history;

    if (favorites.isEmpty && history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Belum Ada Lokasi Tersimpan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Cari nama kota di kolom atas untuk melihat cuaca atau menyimpannya sebagai favorit.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (favorites.isNotEmpty) ...[
          Text(
            'Lokasi Favorit',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...favorites.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LocationTile(
                location: loc,
                isFavorite: true,
                onTap: () => _selectLocation(loc),
                onToggleFavorite: () => weatherVm.toggleFavorite(loc),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pencarian',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: searchVm.clearHistory,
                child: const Text('Hapus Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...history.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LocationTile(
                location: loc,
                isFavorite: weatherVm.isFavorite(loc),
                leadingIcon: Icons.history_rounded,
                onTap: () => _selectLocation(loc),
                onToggleFavorite: () => weatherVm.toggleFavorite(loc),
                onDelete: () => searchVm.removeFromHistory(loc),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  final LocationModel location;
  final bool isFavorite;
  final IconData leadingIcon;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onDelete;

  const _LocationTile({
    required this.location,
    required this.isFavorite,
    this.leadingIcon = Icons.location_on_outlined,
    required this.onTap,
    required this.onToggleFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(
          leadingIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          location.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${location.displaySubtitle} • (${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)})',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isFavorite ? 'Hapus favorit' : 'Simpan favorit',
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFavorite ? Colors.amber : null,
              ),
              onPressed: onToggleFavorite,
            ),
            if (onDelete != null)
              IconButton(
                tooltip: 'Hapus dari riwayat',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

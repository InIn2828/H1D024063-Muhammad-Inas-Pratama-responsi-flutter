import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'services/local_storage_service.dart';
import 'services/weather_api_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/search_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = WeatherApiService();
    final storageService = LocalStorageService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherViewModel(
            apiService: apiService,
            storageService: storageService,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      ],
      child: Consumer<WeatherViewModel>(
        builder: (context, weatherVm, _) {
          return MaterialApp(
            title: 'CuacaKu - Open-Meteo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: weatherVm.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/location_service.dart';
import '../../data/weather_repository.dart';
import '../../domain/weather_state.dart';
import 'recommendation_provider.dart' show locationServiceProvider;

final weatherRepositoryProvider = Provider<WeatherRepository>(
  (_) => WeatherRepository(),
);

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>(
  (ref) => WeatherNotifier(
    ref.watch(locationServiceProvider),
    ref.watch(weatherRepositoryProvider),
  ),
);

class WeatherNotifier extends StateNotifier<WeatherState> {
  final LocationService _locationService;
  final WeatherRepository _repo;

  WeatherNotifier(this._locationService, this._repo)
    : super(const WeatherInitial());

  Future<void> fetchForCurrentLocation() async {
    state = const WeatherLoading();
    try {
      final position = await _locationService.getCurrentPosition();
      final data = await _repo.fetchCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      state = WeatherLoaded(data);
    } catch (e) {
      state = WeatherError(e.toString());
    }
  }
}

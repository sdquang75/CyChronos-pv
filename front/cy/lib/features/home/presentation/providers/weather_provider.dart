import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/location_service.dart';
import '../../data/weather_repository.dart';
import '../../domain/weather_data.dart';
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

  // アプリ起動時の0ms表示用キャッシュ(30分間有効)
  static WeatherData? _cachedWeather;
  static DateTime? _weatherFetchedAt;

  WeatherNotifier(this._locationService, this._repo)
    : super(_initialState());

  static WeatherState _initialState() {
    if (_cachedWeather != null && _weatherFetchedAt != null) {
      if (DateTime.now().difference(_weatherFetchedAt!) < const Duration(minutes: 30)) {
        return WeatherLoaded(_cachedWeather!);
      }
    }
    return const WeatherInitial();
  }

  Future<void> fetchForCurrentLocation() async {
    // 30分以内のキャッシュがあれば即座に返して通信を省く
    final cached = _cachedWeather;
    final fetchedAt = _weatherFetchedAt;
    if (cached != null && fetchedAt != null) {
      if (DateTime.now().difference(fetchedAt) < const Duration(minutes: 30)) {
        state = WeatherLoaded(cached);
        return;
      }
    }

    // キャッシュがある場合はまずそれを表示し、裏で最新情報を取得する(Stale-While-Revalidate)
    if (cached != null) {
      state = WeatherLoaded(cached);
    } else {
      state = const WeatherLoading();
    }

    try {
      // 天気予報は市街地レベルで十分なため、getFastPosition()で即座に位置を特定
      final position = await _locationService.getFastPosition();
      final data = await _repo.fetchCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      _cachedWeather = data;
      _weatherFetchedAt = DateTime.now();
      state = WeatherLoaded(data);
    } catch (e) {
      // 既にキャッシュが表示されている場合はエラー画面に切り替えず、表示を維持
      if (state is! WeatherLoaded) {
        state = WeatherError(e.toString());
      }
    }
  }
}

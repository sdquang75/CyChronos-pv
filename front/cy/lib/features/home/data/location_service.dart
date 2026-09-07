import 'package:geolocator/geolocator.dart';

class LocationServiceDisabledException implements Exception {}

class LocationPermissionDeniedException implements Exception {}

class LocationPermissionDeniedForeverException implements Exception {}

class LocationService {
  static Position? _lastCachedPosition;
  static DateTime? _cachedAt;

  /// 直近取得した位置情報(キャッシュ)を即座に返す。存在しない場合はnull
  Position? get cachedPosition => _lastCachedPosition;

  /// 直近のキャッシュ、またはOSのgetLastKnownPositionを返す(0〜50msの超高速取得)。
  /// 天気予報やルートの事前読み込み(Preload)など、超高精度GPS衛星ロックを待たずに
  /// すぐ位置が欲しい場面で使用する。
  Future<Position> getFastPosition({
    Duration maxAge = const Duration(minutes: 5),
  }) async {
    final cached = _lastCachedPosition;
    final cachedTime = _cachedAt;
    if (cached != null && cachedTime != null) {
      if (DateTime.now().difference(cachedTime) <= maxAge) {
        return cached;
      }
    }

    try {
      await _ensureLocationAvailable();
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastCachedPosition = lastKnown;
        _cachedAt = DateTime.now();
        return lastKnown;
      }
    } catch (_) {
      // 失敗時は通常のGPS取得にフォールバック
    }

    return getCurrentPosition();
  }

  Future<Position> getCurrentPosition() async {
    await _ensureLocationAvailable();

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
    _lastCachedPosition = pos;
    _cachedAt = DateTime.now();
    return pos;
  }

  Stream<Position> getPositionStream() async* {
    await _ensureLocationAvailable();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    );
  }

  Future<void> _ensureLocationAvailable() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException();
    }
    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }
  }
}

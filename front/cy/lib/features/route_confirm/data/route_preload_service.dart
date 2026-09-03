import 'route_repository.dart';

class _CachedRouteEntry {
  final Future<CyclingRoute> future;
  final DateTime createdAt;

  _CachedRouteEntry({
    required this.future,
    required this.createdAt,
  });
}

/// スポット詳細画面(DetilScreen)からルート確認画面(RouteConfirmScreen)への遷移を
/// 瞬時(0ms〜100ms)に行うための事前読み込み・キャッシュ管理サービス。
class RoutePreloadService {
  static final Map<String, _CachedRouteEntry> _cache = {};

  static String _cacheKey({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    // 緯度経度を小数第3位(約100mの精度)で丸めてキーにする
    final fLat = fromLat.toStringAsFixed(3);
    final fLng = fromLng.toStringAsFixed(3);
    final tLat = toLat.toStringAsFixed(3);
    final tLng = toLng.toStringAsFixed(3);
    return '$fLat,$fLng->$tLat,$tLng';
  }

  /// ルートの事前読み込みを開始する(DetilScreen表示時に呼ぶ)。
  /// 既に同じ区間の読み込み中またはキャッシュが存在する場合はそれを再利用する
  static Future<CyclingRoute> preloadRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    RouteRepository? repository,
  }) {
    final key = _cacheKey(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    final existing = _cache[key];
    if (existing != null) {
      if (DateTime.now().difference(existing.createdAt) < const Duration(minutes: 5)) {
        return existing.future;
      }
    }

    final repo = repository ?? RouteRepository();
    final future = repo.fetchCyclingRoute(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    _cache[key] = _CachedRouteEntry(
      future: future,
      createdAt: DateTime.now(),
    );

    return future;
  }

  /// キャッシュ済みのルートFutureがあれば取得する
  static Future<CyclingRoute>? getCachedRouteFuture({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final key = _cacheKey(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    final existing = _cache[key];
    if (existing != null) {
      if (DateTime.now().difference(existing.createdAt) < const Duration(minutes: 5)) {
        return existing.future;
      }
    }
    return null;
  }

  /// キャッシュをクリアする
  static void clear() {
    _cache.clear();
  }
}

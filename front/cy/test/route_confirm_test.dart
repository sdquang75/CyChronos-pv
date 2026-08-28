// ルート確認・案内画面(RouteConfirmScreen)のテスト。
// 位置情報・バックAPI・認証は全部フェイクに差し替えて、
// 「実ルート表示」「失敗時の概算値フォールバック」「案内開始/終了でのバー切り替えと記録API」を確認する。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cy/features/auth/data/auth_repository.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/home/data/location_service.dart';
import 'package:cy/features/route_confirm/data/route_repository.dart';
import 'package:cy/features/route_confirm/route_confirm.dart';

// テスト用の偽位置情報。東京駅の座標を即返す
class _FakeLocationService implements LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    return Position(
      longitude: 139.7673,
      latitude: 35.6812,
      timestamp: DateTime(2026, 7, 12),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    );
  }
}

// テスト用の偽リポジトリ。決め打ちのルートを返すか、わざと失敗させる
class _FakeRouteRepository implements RouteRepository {
  final bool shouldFail; // trueならルート取得を失敗させる
  int? startedUserId; // startTrip が呼ばれたときの記録
  String? startedPlaceId;
  int? endedTripId; // endTrip が呼ばれたときの記録

  _FakeRouteRepository({this.shouldFail = false});

  @override
  Future<CyclingRoute> fetchCyclingRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (shouldFail) throw Exception('テスト用の失敗');
    return const CyclingRoute(
      distanceM: 8500, // 8.5km
      durationSec: 2400, // 40分
      points: [
        [139.7673, 35.6812],
        [139.7700, 35.6900],
        [139.7800, 35.7000],
      ],
    );
  }

  @override
  Future<int> startTrip({
    required int userId,
    String? placeId,
    String? destinationName,
  }) async {
    startedUserId = userId;
    startedPlaceId = placeId;
    return 42; // 適当なtrip_id
  }

  @override
  Future<void> endTrip({
    required int userId,
    required int tripId,
  }) async {
    endedTripId = tripId;
  }
}

// テスト用の偽認証。指定した状態のまま動かない
class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

// /api/suggest の places 1件分と同じ形のテストデータ
final _destination = <String, dynamic>{
  'id': 'test-place-1',
  'name': 'テストカフェ',
  'lat': 35.7000,
  'lng': 139.7800,
  'address': '東京都千代田区丸の内1-1',
  'durationSec': 1800, // 概算値(フォールバック用): 30分
  'distanceM': 6000, // 概算値(フォールバック用): 6.0km
};

// 画面をテスト用の部品と一緒に組み立てるヘルパー
Widget _wrap({
  required AuthState authState,
  required _FakeRouteRepository repository,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
    ],
    child: MaterialApp(
      home: RouteConfirmScreen(
        destination: _destination,
        locationService: _FakeLocationService(),
        repository: repository,
        useMapTiles: false, // テストでは地図タイルの通信ができないので簡易描画にする
      ),
    ),
  );
}

void main() {
  testWidgets('ルートが取れたとき: 下部バーに実ルートの距離・所要時間とルートの絵が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      authState: const AuthUnauthenticated(),
      repository: _FakeRouteRepository(),
    ));
    await tester.pumpAndSettle(); // ルート取得(非同期)の完了待ち

    expect(find.text('テストカフェ'), findsOneWidget); // 目的地名
    expect(find.text('8.5km ・ 約40分'), findsOneWidget); // 実ルートの値(概算6.0kmではない)
    expect(find.text('案内開始'), findsOneWidget); // 開始ボタンがある
    expect(find.byType(CustomPaint), findsWidgets); // ルートの絵が描かれている
    expect(find.textContaining('取得できませんでした'), findsNothing); // エラー表示なし
  });

  testWidgets('ルート取得に失敗したとき: 概算値にフォールバックしてエラー文言を出す',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      authState: const AuthUnauthenticated(),
      repository: _FakeRouteRepository(shouldFail: true),
    ));
    await tester.pumpAndSettle();

    expect(find.text('6.0km ・ 約30分'), findsOneWidget); // 概算値が出る
    expect(find.textContaining('取得できませんでした'), findsOneWidget); // エラー文言
  });

  testWidgets('ログイン済みで案内開始→終了: バーが消えて全画面になり、開始/終了が記録される',
      (WidgetTester tester) async {
    final repository = _FakeRouteRepository();
    await tester.pumpWidget(_wrap(
      authState: const AuthAuthenticated(
        user: AuthUser(userId: 7, uid: 'u1', name: 'テスト', email: 't@example.com'),
      ),
      repository: repository,
    ));
    await tester.pumpAndSettle();

    // 案内開始 → バーが消えて案内モードへ
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();

    expect(repository.startedUserId, 7); // user_id が渡っている
    expect(repository.startedPlaceId, 'test-place-1'); // place_id が渡っている(訪問済み除外用)
    expect(find.text('案内開始'), findsNothing); // 下部バーは消えた(全画面)
    expect(find.text('テストカフェ'), findsNothing); // バーの中身ごと消えている
    expect(find.text('案内を終了'), findsOneWidget); // 終了ボタンが出る
    expect(find.text('8.5km ・ 約40分'), findsOneWidget); // 上部チップに残り距離・時間

    // 案内を終了 → バーが戻り、トリップ終了が記録される
    await tester.tap(find.text('案内を終了'));
    await tester.pumpAndSettle();

    expect(repository.endedTripId, 42); // 終了APIに開始時のtrip_idが渡っている
    expect(find.text('案内開始'), findsOneWidget); // バーが戻った
    expect(find.text('案内を終了'), findsNothing);
  });

  testWidgets('未ログインで案内開始: 記録APIは呼ばず、案内モードには入れる',
      (WidgetTester tester) async {
    final repository = _FakeRouteRepository();
    await tester.pumpWidget(_wrap(
      authState: const AuthUnauthenticated(),
      repository: repository,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('案内開始'));
    await tester.pump(); // SnackBar表示待ち

    expect(repository.startedUserId, isNull); // トリップ開始APIは呼ばれない
    expect(find.textContaining('走行記録なしで案内します'), findsOneWidget); // 案内文言
    await tester.pumpAndSettle();
    expect(find.text('案内を終了'), findsOneWidget); // 案内モード自体には入れる
  });
}

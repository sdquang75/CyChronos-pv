import 'dart:async';

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
import 'package:cy/features/history/data/history_repository.dart';
import 'package:cy/features/history/presentation/providers/history_provider.dart';
import 'package:cy/features/home/data/location_service.dart';
import 'package:cy/features/route_confirm/data/navigation_announcer.dart';
import 'package:cy/features/route_confirm/data/route_repository.dart';
import 'package:cy/features/route_confirm/route_confirm.dart';

Position _position({
  double latitude = 35.6812,
  double longitude = 139.7673,
  double accuracy = 1,
}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime(2026, 7, 12),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

// テスト用の偽履歴リポジトリ。トリップ終了時にhistoryProviderが叩く
// GET /api/tripsが実ネットワークに飛ばないようにするためだけの空実装
class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required int userId}) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required int userId,
    required int tripId,
  }) async {
    return null;
  }

  @override
  Future<void> deleteTrip({
    required int userId,
    required int tripId,
  }) async {}
}

// テスト用の偽位置情報。既定では東京駅の座標を返す
class _FakeLocationService implements LocationService {
  final List<Position> _currentPositions;
  final Stream<Position> positions;
  int _currentPositionIndex = 0;

  _FakeLocationService({
    Position? currentPosition,
    List<Position>? currentPositions,
    Stream<Position>? positions,
  }) : assert(currentPositions == null || currentPositions.isNotEmpty),
       _currentPositions = currentPositions ?? [currentPosition ?? _position()],
       positions = positions ?? const Stream.empty();

  @override
  Future<Position> getCurrentPosition() async {
    final index =
        _currentPositionIndex < _currentPositions.length
            ? _currentPositionIndex++
            : _currentPositions.length - 1;
    return _currentPositions[index];
  }

  @override
  Stream<Position> getPositionStream() => positions;
}

class _FakeNavigationAnnouncer implements NavigationAnnouncer {
  final spoken = <String>[];
  int stopCount = 0;
  int vibrationCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String message, {bool urgent = false}) async {
    spoken.add(message);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> vibrate() async {
    vibrationCount++;
  }
}

// テスト用の偽リポジトリ。決め打ちのルートを返すか、わざと失敗させる
class _FakeRouteRepository implements RouteRepository {
  final bool shouldFail; // trueならルート取得を失敗させる
  int? startedUserId; // startTrip が呼ばれたときの記録
  String? startedPlaceId;
  int? endedTripId; // endTrip が呼ばれたときの記録
  int routeFetchCount = 0;
  final routeRequests = <Map<String, double>>[];

  _FakeRouteRepository({this.shouldFail = false});

  static const route = CyclingRoute(
    distanceM: 8500, // 8.5km
    durationSec: 2400, // 40分
    points: [
      [139.7673, 35.6812],
      [139.7700, 35.6900],
      [139.7800, 35.7000],
    ],
    steps: [
      NavigationStep(
        instruction: '北へ進みます',
        roadName: '',
        maneuverType: 'depart',
        modifier: 'straight',
        distanceM: 4000,
        durationSec: 1200,
        maneuverPoint: [139.7673, 35.6812],
      ),
      NavigationStep(
        instruction: '右折します',
        roadName: 'テスト通り',
        maneuverType: 'turn',
        modifier: 'right',
        distanceM: 4500,
        durationSec: 1200,
        maneuverPoint: [139.7700, 35.6900],
      ),
      NavigationStep(
        instruction: '目的地に到着します',
        roadName: '',
        maneuverType: 'arrive',
        modifier: null,
        distanceM: 0,
        durationSec: 0,
        maneuverPoint: [139.7800, 35.7000],
      ),
    ],
  );

  @override
  Future<CyclingRoute> fetchCyclingRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    routeFetchCount++;
    routeRequests.add({
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
    });
    if (shouldFail) throw Exception('テスト用の失敗');
    return route;
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

  int? endedDistanceM;
  int? endedDurationSec;
  double? endedAverageSpeedKmh;
  final loggedLocations = <Map<String, dynamic>>[];

  @override
  Future<void> logLocation({
    required int userId,
    required int tripId,
    required double lat,
    required double lng,
  }) async {
    loggedLocations.add({
      'userId': userId,
      'tripId': tripId,
      'lat': lat,
      'lng': lng,
    });
  }

  @override
  Future<void> endTrip({
    required int userId,
    required int tripId,
    int? totalDistanceM,
    int? durationSec,
    double? averageSpeedKmh,
  }) async {
    endedTripId = tripId;
    endedDistanceM = totalDistanceM;
    endedDurationSec = durationSec;
    endedAverageSpeedKmh = averageSpeedKmh;
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
  LocationService? locationService,
  NavigationAnnouncer? announcer,
  Map<String, dynamic>? destination,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
      historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
    ],
    child: MaterialApp(
      home: RouteConfirmScreen(
        destination: destination ?? _destination,
        locationService: locationService ?? _FakeLocationService(),
        repository: repository,
        announcer: announcer,
        useMapTiles: false, // テストでは地図タイルの通信ができないので簡易描画にする
        keepScreenAwake: false,
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

    // 案内を終了 → トリップ終了が記録され、トースト通知の代わりに完了画面が出る
    await tester.tap(find.text('案内を終了'));
    await tester.pumpAndSettle();

    expect(repository.endedTripId, 42); // 終了APIに開始時のtrip_idが渡っている
    expect(find.text('お疲れさまでした!'), findsOneWidget); // 完了画面が表示される
    expect(find.text('8.5km'), findsOneWidget); // 走行距離(実ルートの値)が出る
    expect(find.text('完了'), findsOneWidget);

    // 「完了」を押すと元の画面(このテストではRouteConfirmScreenが最初の画面)まで戻る
    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();

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

  testWidgets('往復モードは往路案内→滞在→帰りのルート表示へ進める',
      (WidgetTester tester) async {
    final repository = _FakeRouteRepository();
    final roundTripDestination = <String, dynamic>{
      ..._destination,
      'tripMode': 'round_trip',
      'plannedStayMinutes': 15,
      'returnDurationSec': 2100,
      'returnDistanceM': 6500,
    };

    await tester.pumpWidget(_wrap(
      authState: const AuthUnauthenticated(),
      repository: repository,
      destination: roundTripDestination,
    ));
    await tester.pumpAndSettle();

    // 往路案内開始 → 往復モードなので「到着・滞在を開始」ボタンが出る
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();
    expect(find.text('到着・滞在を開始'), findsOneWidget);

    // 到着(手動)→ 滞在パネルへ
    await tester.tap(find.text('到着・滞在を開始'));
    await tester.pumpAndSettle();
    expect(find.text('滞在中'), findsOneWidget);
    expect(find.text('今すぐ折り返す'), findsOneWidget);

    // 今すぐ折り返す → 復路プレビュー(出発地点へ戻る)
    await tester.tap(find.text('今すぐ折り返す'));
    await tester.pumpAndSettle();
    expect(find.text('出発地点へ戻る'), findsOneWidget);
    expect(find.text('帰りの案内を開始'), findsOneWidget);

    // 帰りの案内を開始 → 上部チップに「復路」の実ルート値が出る
    await tester.tap(find.text('帰りの案内を開始'));
    await tester.pumpAndSettle();
    expect(find.textContaining('復路 ・ 8.5km'), findsOneWidget);
    expect(find.text('案内を終了'), findsOneWidget);
  });

  testWidgets('走行中の位置更新で次の曲がり案内と残距離を更新する', (WidgetTester tester) async {
    final positions = StreamController<Position>.broadcast(sync: true);
    addTearDown(positions.close);
    final announcer = _FakeNavigationAnnouncer();

    await tester.pumpWidget(
      _wrap(
        authState: const AuthUnauthenticated(),
        repository: _FakeRouteRepository(),
        locationService: _FakeLocationService(positions: positions.stream),
        announcer: announcer,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();

    positions.add(_position(latitude: 35.6880, longitude: 139.7694));
    await tester.pump();

    expect(find.text('右折します'), findsOneWidget);
    expect(find.byKey(const ValueKey('voice-toggle')), findsOneWidget);
    expect(find.text('8.5km ・ 約40分'), findsNothing);
    expect(announcer.spoken.first, contains('案内を開始します'));
  });

  testWidgets('音声をオフにしても曲がり角の振動通知は継続する', (WidgetTester tester) async {
    final positions = StreamController<Position>.broadcast(sync: true);
    addTearDown(positions.close);
    final announcer = _FakeNavigationAnnouncer();

    await tester.pumpWidget(
      _wrap(
        authState: const AuthUnauthenticated(),
        repository: _FakeRouteRepository(),
        locationService: _FakeLocationService(positions: positions.stream),
        announcer: announcer,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('voice-toggle')));
    await tester.pump();

    positions.add(_position(latitude: 35.6899, longitude: 139.76997));
    positions.add(_position(latitude: 35.68991, longitude: 139.76998));
    await tester.pump();

    expect(announcer.spoken, hasLength(1));
    expect(announcer.vibrationCount, 1);
  });

  testWidgets('目的地付近の位置を連続受信すると自動で到着完了になる', (WidgetTester tester) async {
    final positions = StreamController<Position>.broadcast(sync: true);
    addTearDown(positions.close);
    final repository = _FakeRouteRepository();

    await tester.pumpWidget(
      _wrap(
        authState: const AuthAuthenticated(
          user: AuthUser(
            userId: 7,
            uid: 'u1',
            name: 'テスト',
            email: 't@example.com',
          ),
        ),
        repository: repository,
        locationService: _FakeLocationService(positions: positions.stream),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();

    final arrival = _position(latitude: 35.7000, longitude: 139.7800);
    positions.add(arrival);
    positions.add(arrival);
    await tester.pumpAndSettle();

    expect(find.text('目的地に到着しました'), findsOneWidget);
    expect(find.text('完了'), findsOneWidget);
    expect(repository.endedTripId, 42);
  });

  testWidgets('精度のよい位置で3回連続してルートを外れると再検索する', (WidgetTester tester) async {
    final positions = StreamController<Position>.broadcast(sync: true);
    addTearDown(positions.close);
    final repository = _FakeRouteRepository();

    await tester.pumpWidget(
      _wrap(
        authState: const AuthUnauthenticated(),
        repository: repository,
        locationService: _FakeLocationService(positions: positions.stream),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();

    positions.add(_position(latitude: 35.6900, longitude: 139.8000));
    positions.add(_position(latitude: 35.6901, longitude: 139.8001));
    positions.add(_position(latitude: 35.6902, longitude: 139.8002));
    positions.add(_position(latitude: 35.6903, longitude: 139.8003));
    positions.add(_position(latitude: 35.6904, longitude: 139.8004));
    positions.add(_position(latitude: 35.6905, longitude: 139.8005));
    await tester.pumpAndSettle();

    expect(repository.routeFetchCount, 2);
    expect(find.text('新しいルートに更新しました。'), findsOneWidget);
  });

  testWidgets('往復の帰着地点にはプレビュー時でなく案内開始時の現在地を使う', (WidgetTester tester) async {
    final repository = _FakeRouteRepository();
    final previewPosition = _position();
    final actualStart = _position(latitude: 35.6825, longitude: 139.7688);
    final destinationPosition = _position(
      latitude: 35.7000,
      longitude: 139.7800,
    );
    final locationService = _FakeLocationService(
      currentPositions: [previewPosition, actualStart, destinationPosition],
    );
    final roundTripDestination = <String, dynamic>{
      ..._destination,
      'tripMode': 'round_trip',
      'plannedStayMinutes': 15,
    };

    await tester.pumpWidget(
      _wrap(
        authState: const AuthUnauthenticated(),
        repository: repository,
        destination: roundTripDestination,
        locationService: locationService,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('到着・滞在を開始'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今すぐ折り返す'));
    await tester.pumpAndSettle();

    expect(repository.routeFetchCount, 3);
    expect(
      repository.routeRequests.last['fromLat'],
      destinationPosition.latitude,
    );
    expect(
      repository.routeRequests.last['fromLng'],
      destinationPosition.longitude,
    );
    expect(repository.routeRequests.last['toLat'], actualStart.latitude);
    expect(repository.routeRequests.last['toLng'], actualStart.longitude);
  });

  testWidgets('ログイン中の走行位置更新でGPS座標がバックに送信され、終了時にメトリクスが送られる',
      (WidgetTester tester) async {
    final positions = StreamController<Position>.broadcast(sync: true);
    addTearDown(positions.close);
    final repository = _FakeRouteRepository();

    await tester.pumpWidget(
      _wrap(
        authState: const AuthAuthenticated(
          user: AuthUser(
            userId: 7,
            uid: 'u1',
            name: 'テスト',
            email: 't@example.com',
          ),
        ),
        repository: repository,
        locationService: _FakeLocationService(positions: positions.stream),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('案内開始'));
    await tester.pumpAndSettle();

    // 走行中位置を送信
    positions.add(_position(latitude: 35.6880, longitude: 139.7694));
    await tester.pump();

    expect(repository.loggedLocations, isNotEmpty);
    expect(repository.loggedLocations.first['userId'], 7);
    expect(repository.loggedLocations.first['tripId'], 42);

    // 案内終了
    await tester.tap(find.text('案内を終了'));
    await tester.pumpAndSettle();

    expect(repository.endedTripId, 42);
    expect(repository.endedDistanceM, 8500);
  });
}

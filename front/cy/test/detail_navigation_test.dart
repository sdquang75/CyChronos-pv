// 「ホーム → 目的地一覧 → 詳細 → ルート確認」の遷移テスト。
// 本物のルーター(routerProvider)とHomeScreen(IndexedStackシェル)+RideFlow
// (HOMEタブ専用の入れ子Navigator)を使い、検索結果からスポットのデータが
// 詳細画面・ルート確認画面へ正しく渡っていくかを確認する。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cy/core/router/app_router.dart';
import 'package:cy/features/auth/data/auth_repository.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/home/data/location_service.dart';
import 'package:cy/features/home/data/recommendation_repository.dart';
import 'package:cy/features/home/domain/recommendation_state.dart';
import 'package:cy/features/home/presentation/providers/recommendation_provider.dart';

// テスト用の偽認証。RideFlow(HOMEタブ)にはログイン必須なので認証済みにする
// (本物のAuthNotifierはFirebase初期化が必要でテストでは動かないため)
class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(
        const AuthAuthenticated(
          user: AuthUser(
            userId: 1,
            uid: 'test-uid',
            name: 'テストユーザー',
            email: 't@example.com',
          ),
        ),
      );

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

// テスト用の偽おすすめ通知。位置情報/バックエンドを叩かず、
// 渡されたplacesを即座にRecommendationLoadedとして返す
class _FakeRecommendationNotifier extends RecommendationNotifier {
  _FakeRecommendationNotifier(this._places)
    : super(LocationService(), RecommendationRepository());

  final List<Map<String, dynamic>> _places;

  @override
  Future<void> fetchForCurrentLocation({
    required int minutes,
    required String type,
    required String mode,
    required int stayMinutes,
  }) async {
    state = RecommendationLoaded({'places': _places});
  }
}

void main() {
  testWidgets('検索結果の「詳細を見る」を押すと、そのスポットのデータが詳細画面に表示される',
      (WidgetTester tester) async {
    // スマホサイズの画面にする(大画面だとPC用フレーム表示に切り替わるため)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // テスト環境には位置情報プラグインの実体がないので、
    // 「位置情報サービス無効」を即答するモックにする(ルート確認画面のフォールバック確認用)
    const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      geolocatorChannel,
      (call) async {
        if (call.method == 'isLocationServiceEnabled') return false;
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, null));

    // /api/suggest が返す places 1件分と同じ形のテストデータ
    final place = <String, dynamic>{
      'id': 'test-place-1',
      'name': 'テストカフェ',
      'lat': 35.68,
      'lng': 139.76,
      'address': '東京都千代田区丸の内1-1',
      'rating': 4.5,
      'genre': 'cafe',
      'durationSec': 1800,
      'durationMinutes': 30,
      'distanceM': 8800,
      'distanceKm': 8.8,
    };

    // 認証・おすすめ検索だけ偽物に差し替えて、本物のルーターでアプリを組み立てる
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        recommendationProvider.overrideWith(
          (ref) => _FakeRecommendationNotifier([place]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // スプラッシュの最低表示タイマー(3.5秒)を消化しておく
    // (認証済みなので自動で/homeへリダイレクトされる)
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 700)); // 画面切り替え待ち

    // HOMEタブ(RideFlow)の空き時間入力を「1時間30分」にして検索する
    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.enterText(find.byType(TextField).at(1), '30');
    await tester.tap(find.text('ルートを検索'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 一覧へのpush待ち

    // 一覧にスポット名・所要時間・空き時間が出ている
    expect(find.text('テストカフェ'), findsOneWidget);
    expect(find.text('約30分'), findsOneWidget);
    expect(find.text('1時間30分'), findsOneWidget); // 入力した空き時間がヘッダーに出る

    // 「詳細を見る」を押して詳細画面へ
    await tester.tap(find.text('詳細を見る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 画面切り替え待ち

    // 詳細画面に各項目が表示されている
    expect(find.text('テストカフェ'), findsOneWidget); // 名前
    expect(find.text('東京都千代田区丸の内1-1'), findsOneWidget); // 住所
    expect(find.text('カフェ'), findsOneWidget); // ジャンル(日本語)
    expect(find.text('4.5'), findsOneWidget); // 評価
    expect(find.text('8.8km'), findsOneWidget); // 距離(km)
    expect(find.text('30分'), findsOneWidget); // 所要時間(60分未満なので「0時間」は付かない)

    // さらに「ルートを見る」でルート確認画面へ。
    // テスト環境では位置情報が取れない=ルート取得は失敗するので、
    // 概算値へのフォールバックが効いて画面が壊れないことを確認する
    await tester.tap(find.text('ルートを見る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 画面切り替え待ち
    // pumpAndSettleは使わない: IndexedStackで裏に常駐しているHISTORY/SETTINGS
    // タブが実バックエンド無し環境でずっとローディング表示のままになり得るため、
    // ルート取得(失敗)が完了するのに十分な時間だけ進める
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('テストカフェ'), findsOneWidget); // 目的地名が引き継がれている
    expect(find.textContaining('8.8km'), findsOneWidget); // 概算の距離にフォールバック
    expect(find.textContaining('取得できませんでした'), findsOneWidget); // エラー文言が出る
    expect(find.text('案内開始'), findsOneWidget); // 開始ボタンがある
  });
}

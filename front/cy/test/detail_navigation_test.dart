// 「一覧画面 → 詳細画面」の遷移テスト。
// 本物のルーター(routerProvider)を使い、一覧のカードで「詳細を見る」を押すと
// そのスポットのデータが詳細画面に正しく渡って表示されるかを確認する。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cy/core/router/app_router.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';

// テスト用の偽認証。Firebaseを呼ばず「未ログイン」のままにする
// (本物のAuthNotifierはFirebase初期化が必要でテストでは動かないため)
class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthUnauthenticated());

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> registerWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('一覧の「詳細を見る」を押すと、そのスポットのデータが詳細画面に表示される',
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

    // 認証だけ偽物に差し替えて、本物のルーターでアプリを組み立てる
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier()),
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

    // スプラッシュを飛ばして一覧画面へ(ホーム画面が検索後にやるのと同じ渡し方)
    router.go('/destination', extra: {
      'places': [place],
      'minutes': 90, // ホームで入力した空き時間(1時間30分)
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 画面切り替え待ち

    // スプラッシュの最低表示タイマー(3.5秒)を消化しておく(テスト終了時のタイマー残りエラー防止)
    await tester.pump(const Duration(seconds: 4));

    // 一覧にスポット名・所要時間・空き時間が出ている
    expect(find.text('テストカフェ'), findsOneWidget);
    expect(find.text('約30分'), findsOneWidget);
    expect(find.text('1時間30分'), findsOneWidget); // 渡した空き時間がヘッダーに出る

    // 「詳細を見る」を押して詳細画面へ
    await tester.tap(find.text('詳細を見る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 画面切り替え待ち

    // 詳細画面に各項目が表示されている
    expect(find.text('テストカフェ'), findsOneWidget); // 名前
    expect(find.text('東京都千代田区丸の内1-1'), findsOneWidget); // 住所
    expect(find.text('カフェ'), findsOneWidget); // ジャンル(日本語)
    expect(find.text('4.5'), findsOneWidget); // 評価
    expect(find.text('8.8'), findsOneWidget); // 距離(km)
    expect(find.text('0'), findsOneWidget); // 所要時間の「時間」
    expect(find.text('30'), findsOneWidget); // 所要時間の「分」

    // さらに「ルートを見る」でルート確認画面へ。
    // テスト環境では位置情報が取れない=ルート取得は失敗するので、
    // 概算値へのフォールバックが効いて画面が壊れないことを確認する
    await tester.tap(find.text('ルートを見る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700)); // 画面切り替え待ち
    await tester.pumpAndSettle(); // ルート取得(失敗)の完了待ち

    expect(find.text('テストカフェ'), findsOneWidget); // 目的地名が引き継がれている
    expect(find.textContaining('8.8km'), findsOneWidget); // 概算の距離にフォールバック
    expect(find.textContaining('取得できませんでした'), findsOneWidget); // エラー文言が出る
    expect(find.text('案内開始'), findsOneWidget); // 開始ボタンがある
  });
}

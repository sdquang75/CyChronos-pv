import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cy/features/auth/data/auth_repository.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/settings/data/settings_service.dart';
import 'package:cy/features/settings/presentation/settings_screen.dart';

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

Widget _wrapSettings({
  AuthState authState = const AuthAuthenticated(
    user: AuthUser(
      userId: 1,
      uid: 'u1',
      name: 'テストライダー',
      email: 'rider@example.com',
    ),
  ),
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings_voice_guidance': true,
      'settings_keep_screen_awake': true,
      'settings_auto_reroute': true,
      'settings_map_type': 'normal',
    });
  });

  testWidgets('SettingsScreen renders navigation, map, and info sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapSettings());
    await tester.pumpAndSettle();

    // タイトルと各セクションヘッダーが表示されていること
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('ナビゲーション設定'), findsOneWidget);
    expect(find.text('地図表示設定'), findsOneWidget);
    expect(find.text('サポート & ストレージ'), findsOneWidget);
    expect(find.text('アプリ情報'), findsOneWidget);

    // ユーザー情報
    expect(find.text('テストライダー'), findsOneWidget);
    expect(find.text('rider@example.com'), findsOneWidget);

    // ナビゲーション設定の各項目
    expect(find.text('音声案内'), findsOneWidget);
    expect(find.text('画面の常時点灯'), findsOneWidget);
    expect(find.text('自動リルート'), findsOneWidget);

    // 地図タイプ
    expect(find.text('地図タイプ'), findsOneWidget);
    expect(find.text('標準'), findsOneWidget);
    expect(find.text('衛星写真'), findsOneWidget);
    expect(find.text('地形'), findsOneWidget);

    // ストレージ & サポート
    expect(find.text('お問い合わせ'), findsOneWidget);
    expect(find.text('キャッシュを削除'), findsOneWidget);

    // アプリ情報
    expect(find.text('オープンソースライセンス'), findsOneWidget);
    expect(find.text('利用規約 & プライバシー'), findsOneWidget);
    expect(find.text('バージョン'), findsOneWidget);
    expect(find.text('v1.0.0 (42)'), findsOneWidget);
  });

  testWidgets('Tapping map type chip updates the selected state',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapSettings());
    await tester.pumpAndSettle();

    // 衛星写真を画面内にスクロールしてタップ
    await tester.scrollUntilVisible(find.text('衛星写真'), 100);
    await tester.tap(find.text('衛星写真'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_map_type'), 'satellite');
  });

  testWidgets('Tapping clear cache opens confirmation dialog and clears cache',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapSettings());
    await tester.pumpAndSettle();

    // キャッシュを削除をタップ (SingleChildScrollView内にあるため確保)
    await tester.scrollUntilVisible(find.text('キャッシュを削除'), 100);
    await tester.tap(find.text('キャッシュを削除'));
    await tester.pumpAndSettle();

    // ダイアログが出ること
    expect(find.textContaining('一時保存された画像データを削除して'), findsOneWidget);

    // 「削除する」をタップ
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    // トーストが表示されること
    expect(find.textContaining('キャッシュを削除しました'), findsOneWidget);
  });
}

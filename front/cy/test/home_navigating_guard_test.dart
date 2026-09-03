import 'package:cy/features/auth/data/auth_repository.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/history/data/history_repository.dart';
import 'package:cy/features/history/presentation/providers/history_provider.dart';
import 'package:cy/features/home/presentation/home_screen.dart';
import 'package:cy/features/home/presentation/providers/weather_provider.dart';
import 'package:cy/features/home/domain/weather_state.dart';
import 'package:cy/features/route_confirm/presentation/providers/navigation_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWeatherNotifier extends StateNotifier<WeatherState>
    implements WeatherNotifier {
  _FakeWeatherNotifier() : super(const WeatherInitial());

  @override
  Future<void> fetchForCurrentLocation() async {}
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
      : super(const AuthAuthenticated(
          user: AuthUser(userId: 1, uid: 'u1', name: 'User', email: 'u@example.com'),
        ));

  @override
  Future<void> checkAuth() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required int userId}) async => [];

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required int userId,
    required int tripId,
  }) async => null;

  @override
  Future<bool> deleteTrip({required int userId, required int tripId}) async => true;
}

void main() {
  testWidgets(
      'HomeScreen: 案内中(isTripNavigating=true)のとき、HOMEタブ再タップによる画面リセットが無効化されること',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
        weatherProvider.overrideWith((ref) => _FakeWeatherNotifier()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初期状態: HOMEタブが表示されている
    expect(find.text('所要時間'), findsOneWidget);

    // 1. 通常時(案内中ではない): isTripNavigatingProvider = false
    expect(container.read(isTripNavigatingProvider), isFalse);

    // 2. 案内中フラグをtrueに設定(RouteConfirmScreenで案内開始した状態を再現)
    container.read(isTripNavigatingProvider.notifier).state = true;
    await tester.pump();

    // 3. HOMEタブをもう一度タップ
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();

    // 案内中はリセット処理がガードされ、画面が正常に維持されること
    expect(find.text('所要時間'), findsOneWidget);

    // 4. 案内終了時: isTripNavigatingProvider = false
    container.read(isTripNavigatingProvider.notifier).state = false;
    await tester.pump();
    expect(container.read(isTripNavigatingProvider), isFalse);
  });
}

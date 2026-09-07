import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cy/features/auth/data/auth_repository.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/history/data/history_repository.dart';
import 'package:cy/features/history/presentation/history_screen.dart';
import 'package:cy/features/history/presentation/providers/history_provider.dart';
import 'package:cy/features/history/presentation/trip_detail_screen.dart';

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

class _FakeHistoryRepository implements HistoryRepository {
  List<Map<String, dynamic>> trips;
  int? deletedTripId;

  _FakeHistoryRepository({required this.trips});

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required int userId}) async {
    return trips;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required int userId,
    required int tripId,
  }) async {
    return trips.firstWhere((t) => t['trip_id'] == tripId);
  }

  @override
  Future<void> deleteTrip({
    required int userId,
    required int tripId,
  }) async {
    deletedTripId = tripId;
    trips.removeWhere((t) => t['trip_id'] == tripId);
  }
}

Widget _wrapHistory({
  required _FakeHistoryRepository repository,
  AuthState authState = const AuthAuthenticated(
    user: AuthUser(userId: 1, uid: 'u1', name: 'User 1', email: 'u1@ex.com'),
  ),
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => _FakeAuthNotifier(authState)),
      historyRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      home: HistoryScreen(),
    ),
  );
}

void main() {
  testWidgets('HistoryScreen: 履歴カード一覧が正しく表示される', (WidgetTester tester) async {
    final repo = _FakeHistoryRepository(
      trips: [
        {
          'trip_id': 1,
          'destination_name': '大阪城公園',
          'total_distance_m': 12500,
          'duration_sec': 4800,
          'average_speed_kmh': 9.38,
          'start_time': '2026-06-26T10:00:00.000Z',
        },
      ],
    );

    await tester.pumpWidget(_wrapHistory(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('大阪城公園'), findsOneWidget);
    expect(find.text('12.5 km'), findsOneWidget);
    expect(find.text('1:20:00'), findsOneWidget);
    expect(find.text('9.4 km/h'), findsOneWidget);
  });

  testWidgets('HistoryScreen: カードをタップするとTripDetailScreenへ遷移する',
      (WidgetTester tester) async {
    final repo = _FakeHistoryRepository(
      trips: [
        {
          'trip_id': 1,
          'destination_name': 'テスト目的地',
          'total_distance_m': 5000,
          'duration_sec': 1200,
          'average_speed_kmh': 15.0,
          'start_time': '2026-06-26T10:00:00.000Z',
        },
      ],
    );

    await tester.pumpWidget(_wrapHistory(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('テスト目的地'));
    await tester.pumpAndSettle();

    expect(find.byType(TripDetailScreen), findsOneWidget);
  });

  testWidgets('HistoryScreen: カードを左にスワイプして確認すると削除される',
      (WidgetTester tester) async {
    final repo = _FakeHistoryRepository(
      trips: [
        {
          'trip_id': 99,
          'destination_name': '削除予定カフェ',
          'total_distance_m': 3000,
          'duration_sec': 600,
          'average_speed_kmh': 18.0,
          'start_time': '2026-06-26T10:00:00.000Z',
        },
      ],
    );

    await tester.pumpWidget(_wrapHistory(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('削除予定カフェ'), findsOneWidget);

    // 左へスワイプ
    await tester.drag(find.text('削除予定カフェ'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // 確認ダイアログが表示される
    expect(find.text('走行記録の削除'), findsOneWidget);
    expect(find.text('削除する'), findsOneWidget);

    // 削除するをタップ
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repo.deletedTripId, 99);
    expect(find.text('削除予定カフェ'), findsNothing);
  });

  testWidgets('HistoryScreen: 今週のアクティビティ概要カードが表示される',
      (WidgetTester tester) async {
    final nowIso = DateTime.now().toIso8601String();
    final repo = _FakeHistoryRepository(
      trips: [
        {
          'trip_id': 1,
          'destination_name': '今週のサイクリング',
          'total_distance_m': 25000,
          'duration_sec': 3600,
          'average_speed_kmh': 25.0,
          'start_time': nowIso,
        },
      ],
    );

    await tester.pumpWidget(_wrapHistory(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('今週のアクティビティ'), findsOneWidget);
    expect(find.text('25.0km'), findsOneWidget);
    expect(find.text('1回'), findsOneWidget);
    expect(find.text('1時間0分'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cy/features/auth/data/auth_repository.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/history/data/history_repository.dart';
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
  final Map<String, dynamic>? detailToReturn;
  int? deletedTripId;

  _FakeHistoryRepository({this.detailToReturn});

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required int userId}) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required int userId,
    required int tripId,
  }) async {
    return detailToReturn;
  }

  @override
  Future<void> deleteTrip({
    required int userId,
    required int tripId,
  }) async {
    deletedTripId = tripId;
  }
}

Widget _wrapDetail({
  required Map<String, dynamic> trip,
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
    child: MaterialApp(
      home: TripDetailScreen(
        trip: trip,
        historyRepository: repository,
        useMapTiles: false,
      ),
    ),
  );
}

void main() {
  testWidgets('TripDetailScreen: 詳細データとGPSログがある場合、ルート描画と数値が表示される',
      (WidgetTester tester) async {
    final repo = _FakeHistoryRepository(
      detailToReturn: {
        'trip_id': 10,
        'destination_name': '大阪城公園',
        'total_distance_m': 12500,
        'duration_sec': 4800,
        'average_speed_kmh': 9.38,
        'start_time': '2026-06-26T10:00:00.000Z',
        'end_time': '2026-06-26T11:20:00.000Z',
        'locations': [
          {'log_num': 1, 'lat': 34.6937, 'lng': 135.5023},
          {'log_num': 2, 'lat': 34.6941, 'lng': 135.5030},
        ],
      },
    );

    await tester.pumpWidget(_wrapDetail(
      trip: {'trip_id': 10, 'destination_name': '大阪城公園'},
      repository: repo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('大阪城公園'), findsWidgets);
    expect(find.text('12.5 km'), findsOneWidget);
    expect(find.text('9.4 km/h'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byKey(const ValueKey('bottom-delete-trip-button')), findsOneWidget);
  });

  testWidgets('TripDetailScreen: GPSログがない場合、プレースホルダーが表示される',
      (WidgetTester tester) async {
    final repo = _FakeHistoryRepository(
      detailToReturn: {
        'trip_id': 11,
        'destination_name': '空トリップ',
        'locations': [],
      },
    );

    await tester.pumpWidget(_wrapDetail(
      trip: {'trip_id': 11, 'destination_name': '空トリップ'},
      repository: repo,
    ));
    await tester.pumpAndSettle();

    expect(find.text('走行ログがありません'), findsOneWidget);
  });

  testWidgets('TripDetailScreen: 削除ボタンを押して確認するとdeleteTripが呼ばれる',
      (WidgetTester tester) async {
    final repo = _FakeHistoryRepository(
      detailToReturn: {
        'trip_id': 12,
        'destination_name': '削除対象カフェ',
        'locations': [],
      },
    );

    await tester.pumpWidget(_wrapDetail(
      trip: {'trip_id': 12, 'destination_name': '削除対象カフェ'},
      repository: repo,
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('bottom-delete-trip-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom-delete-trip-button')));
    await tester.pumpAndSettle();

    expect(find.text('走行記録の削除'), findsOneWidget);
    expect(find.text('削除する'), findsOneWidget);

    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repo.deletedTripId, 12);
  });
}

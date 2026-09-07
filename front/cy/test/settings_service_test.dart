import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cy/features/settings/data/settings_service.dart';

class _FakeSettingsAdapter implements HttpClientAdapter {
  Map<String, dynamic> userSettings = {
    'user_id': 1,
    'include_visited_places': true,
    'voice_guidance_enabled': false,
    'keep_screen_awake': true,
    'auto_reroute_enabled': false,
    'map_type': 'satellite',
  };

  Map<String, dynamic>? lastPutData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/api/settings') && options.method == 'GET') {
      return ResponseBody.fromString(
        '''
        {
          "user_id": ${userSettings['user_id']},
          "include_visited_places": ${userSettings['include_visited_places']},
          "voice_guidance_enabled": ${userSettings['voice_guidance_enabled']},
          "keep_screen_awake": ${userSettings['keep_screen_awake']},
          "auto_reroute_enabled": ${userSettings['auto_reroute_enabled']},
          "map_type": "${userSettings['map_type']}"
        }
        ''',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path.endsWith('/api/settings') && options.method == 'PUT') {
      lastPutData = options.data as Map<String, dynamic>?;
      return ResponseBody.fromString(
        '{}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{}', 404);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsNotifier per-user tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'user_1_include_visited_places': false,
        'user_2_include_visited_places': true,
      });
    });

    test('Loads settings independently for each user', () async {
      final dio = Dio()..httpClientAdapter = _FakeSettingsAdapter();

      // User 1
      final notifier1 = SettingsNotifier(dio: dio, userId: 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier1.state.includeVisitedPlaces, true); // Synced from backend

      // User 2
      final notifier2 = SettingsNotifier(dio: dio, userId: 2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Local cache of user 2 was true
      expect(notifier2.state.includeVisitedPlaces, true);
    });

    test('Updating setting saves with user-scoped key and syncs to backend',
        () async {
      final adapter = _FakeSettingsAdapter();
      final dio = Dio()..httpClientAdapter = adapter;

      final notifier = SettingsNotifier(dio: dio, userId: 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setIncludeVisitedPlaces(true);
      expect(notifier.state.includeVisitedPlaces, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('user_1_include_visited_places'), true);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(adapter.lastPutData?['include_visited_places'], true);
    });

    test('Guest settings are isolated from authenticated users', () async {
      final dio = Dio()..httpClientAdapter = _FakeSettingsAdapter();

      final guestNotifier = SettingsNotifier(dio: dio, userId: null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await guestNotifier.setIncludeVisitedPlaces(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('guest_include_visited_places'), true);
      // User 1 not affected
      expect(prefs.getBool('user_1_include_visited_places'), false);
    });
  });
}

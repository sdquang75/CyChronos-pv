import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cy/features/settings/data/settings_service.dart';

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

  test('SettingsState default values and mapType conversion', () {
    const defaultState = SettingsState();
    expect(defaultState.voiceGuidanceEnabled, true);
    expect(defaultState.keepScreenAwake, true);
    expect(defaultState.autoRerouteEnabled, true);
    expect(defaultState.mapTypeKey, 'normal');
    expect(defaultState.googleMapType, MapType.normal);

    final satelliteState = defaultState.copyWith(mapTypeKey: 'satellite');
    expect(satelliteState.googleMapType, MapType.satellite);

    final terrainState = defaultState.copyWith(mapTypeKey: 'terrain');
    expect(terrainState.googleMapType, MapType.terrain);
  });

  test('SettingsNotifier updates settings and persists to SharedPreferences',
      () async {
    final notifier = SettingsNotifier();
    await Future.delayed(const Duration(milliseconds: 50));

    await notifier.setVoiceGuidance(false);
    expect(notifier.state.voiceGuidanceEnabled, false);

    await notifier.setKeepScreenAwake(false);
    expect(notifier.state.keepScreenAwake, false);

    await notifier.setAutoReroute(false);
    expect(notifier.state.autoRerouteEnabled, false);

    await notifier.setMapType('satellite');
    expect(notifier.state.mapTypeKey, 'satellite');
    expect(notifier.state.googleMapType, MapType.satellite);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_voice_guidance'), false);
    expect(prefs.getBool('settings_keep_screen_awake'), false);
    expect(prefs.getBool('settings_auto_reroute'), false);
    expect(prefs.getString('settings_map_type'), 'satellite');
  });

  test('clearImageCache returns freed size in MB', () {
    final notifier = SettingsNotifier();
    final freedMb = notifier.clearImageCache();
    expect(freedMb, greaterThanOrEqualTo(1));
  });
}

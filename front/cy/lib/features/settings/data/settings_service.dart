import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ユーザー設定の状態
class SettingsState {
  final bool voiceGuidanceEnabled;
  final bool keepScreenAwake;
  final bool autoRerouteEnabled;
  final String mapTypeKey; // 'normal', 'satellite', 'terrain'
  final bool isLoaded;

  const SettingsState({
    this.voiceGuidanceEnabled = true,
    this.keepScreenAwake = true,
    this.autoRerouteEnabled = true,
    this.mapTypeKey = 'normal',
    this.isLoaded = false,
  });

  SettingsState copyWith({
    bool? voiceGuidanceEnabled,
    bool? keepScreenAwake,
    bool? autoRerouteEnabled,
    String? mapTypeKey,
    bool? isLoaded,
  }) {
    return SettingsState(
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      autoRerouteEnabled: autoRerouteEnabled ?? this.autoRerouteEnabled,
      mapTypeKey: mapTypeKey ?? this.mapTypeKey,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  /// GoogleMap widget用のMapTypeを返す
  MapType get googleMapType {
    switch (mapTypeKey) {
      case 'satellite':
        return MapType.satellite;
      case 'terrain':
        return MapType.terrain;
      case 'normal':
      default:
        return MapType.normal;
    }
  }
}

/// SharedPreferencesと同期してユーザー設定を管理するNotifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _keyVoiceGuidance = 'settings_voice_guidance';
  static const String _keyKeepScreenAwake = 'settings_keep_screen_awake';
  static const String _keyAutoReroute = 'settings_auto_reroute';
  static const String _keyMapType = 'settings_map_type';

  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        voiceGuidanceEnabled: prefs.getBool(_keyVoiceGuidance) ?? true,
        keepScreenAwake: prefs.getBool(_keyKeepScreenAwake) ?? true,
        autoRerouteEnabled: prefs.getBool(_keyAutoReroute) ?? true,
        mapTypeKey: prefs.getString(_keyMapType) ?? 'normal',
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  /// 音声案内の有効/無効を設定
  Future<void> setVoiceGuidance(bool enabled) async {
    state = state.copyWith(voiceGuidanceEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceGuidance, enabled);
  }

  /// 画面常時点灯の有効/無効を設定
  Future<void> setKeepScreenAwake(bool enabled) async {
    state = state.copyWith(keepScreenAwake: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepScreenAwake, enabled);
  }

  /// 自動リルートの有効/無効を設定
  Future<void> setAutoReroute(bool enabled) async {
    state = state.copyWith(autoRerouteEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoReroute, enabled);
  }

  /// 地図タイプを設定 ('normal', 'satellite', 'terrain')
  Future<void> setMapType(String mapTypeKey) async {
    state = state.copyWith(mapTypeKey: mapTypeKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMapType, mapTypeKey);
  }

  /// 画像キャッシュをクリアして推定解放サイズ(概算MB)を返す
  int clearImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    final currentSizeBytes = imageCache.currentSizeBytes;
    imageCache.clear();
    imageCache.clearLiveImages();
    // 最小1MB〜概算MB表示
    final mb = (currentSizeBytes / (1024 * 1024)).ceil();
    return mb < 1 ? 1 : mb;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

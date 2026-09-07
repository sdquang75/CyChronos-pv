import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// ユーザー設定の状態
class SettingsState {
  final bool voiceGuidanceEnabled;
  final bool keepScreenAwake;
  final bool autoRerouteEnabled;
  final bool includeVisitedPlaces;
  final String mapTypeKey; // 'normal', 'satellite', 'terrain'
  final bool isLoaded;

  const SettingsState({
    this.voiceGuidanceEnabled = true,
    this.keepScreenAwake = true,
    this.autoRerouteEnabled = true,
    this.includeVisitedPlaces = false,
    this.mapTypeKey = 'normal',
    this.isLoaded = false,
  });

  SettingsState copyWith({
    bool? voiceGuidanceEnabled,
    bool? keepScreenAwake,
    bool? autoRerouteEnabled,
    bool? includeVisitedPlaces,
    String? mapTypeKey,
    bool? isLoaded,
  }) {
    return SettingsState(
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      autoRerouteEnabled: autoRerouteEnabled ?? this.autoRerouteEnabled,
      includeVisitedPlaces: includeVisitedPlaces ?? this.includeVisitedPlaces,
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

/// ユーザー別(user_id)に設定を管理し、ローカル(SharedPreferences)とバックエンド(MySQL)を同期するNotifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _baseVoiceGuidance = 'voice_guidance';
  static const String _baseKeepScreenAwake = 'keep_screen_awake';
  static const String _baseAutoReroute = 'auto_reroute';
  static const String _baseIncludeVisitedPlaces = 'include_visited_places';
  static const String _baseMapType = 'map_type';

  final Dio _dio;
  final int? _userId;

  SettingsNotifier({Dio? dio, int? userId})
      : _dio = dio ?? ApiClient.instance,
        _userId = userId,
        super(const SettingsState()) {
    _init();
  }

  String _key(String base) {
    return _userId != null ? 'user_${_userId}_$base' : 'guest_$base';
  }

  Future<void> _init() async {
    await _loadFromLocal();
    if (_userId != null) {
      unawaited(_syncWithBackend());
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        voiceGuidanceEnabled: prefs.getBool(_key(_baseVoiceGuidance)) ?? true,
        keepScreenAwake: prefs.getBool(_key(_baseKeepScreenAwake)) ?? true,
        autoRerouteEnabled: prefs.getBool(_key(_baseAutoReroute)) ?? true,
        includeVisitedPlaces:
            prefs.getBool(_key(_baseIncludeVisitedPlaces)) ?? false,
        mapTypeKey: prefs.getString(_key(_baseMapType)) ?? 'normal',
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _syncWithBackend() async {
    if (_userId == null) return;
    try {
      final response = await _dio.get('/api/settings');
      final data = response.data;
      if (data is Map) {
        final serverVoice = data['voice_guidance_enabled'] as bool?;
        final serverKeepAwake = data['keep_screen_awake'] as bool?;
        final serverAutoReroute = data['auto_reroute_enabled'] as bool?;
        final serverIncludeVisited = data['include_visited_places'] as bool?;
        final serverMapType = data['map_type'] as String?;

        state = state.copyWith(
          voiceGuidanceEnabled: serverVoice ?? state.voiceGuidanceEnabled,
          keepScreenAwake: serverKeepAwake ?? state.keepScreenAwake,
          autoRerouteEnabled: serverAutoReroute ?? state.autoRerouteEnabled,
          includeVisitedPlaces:
              serverIncludeVisited ?? state.includeVisitedPlaces,
          mapTypeKey: serverMapType ?? state.mapTypeKey,
        );

        // ローカルキャッシュも最新化
        final prefs = await SharedPreferences.getInstance();
        if (serverVoice != null) {
          await prefs.setBool(_key(_baseVoiceGuidance), serverVoice);
        }
        if (serverKeepAwake != null) {
          await prefs.setBool(_key(_baseKeepScreenAwake), serverKeepAwake);
        }
        if (serverAutoReroute != null) {
          await prefs.setBool(_key(_baseAutoReroute), serverAutoReroute);
        }
        if (serverIncludeVisited != null) {
          await prefs.setBool(
              _key(_baseIncludeVisitedPlaces), serverIncludeVisited);
        }
        if (serverMapType != null) {
          await prefs.setString(_key(_baseMapType), serverMapType);
        }
      }
    } catch (e) {
      debugPrint('[settings] backend sync skipped: $e');
    }
  }

  Future<void> _updateBackend(Map<String, dynamic> updateData) async {
    if (_userId == null) return;
    try {
      await _dio.put('/api/settings', data: updateData);
    } catch (e) {
      debugPrint('[settings] update backend failed: $e');
    }
  }

  /// 訪問済みスポットの提案含める/含めないを設定
  Future<void> setIncludeVisitedPlaces(bool enabled) async {
    state = state.copyWith(includeVisitedPlaces: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_baseIncludeVisitedPlaces), enabled);
    unawaited(_updateBackend({'include_visited_places': enabled}));
  }

  /// 音声案内の有効/無効を設定
  Future<void> setVoiceGuidance(bool enabled) async {
    state = state.copyWith(voiceGuidanceEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_baseVoiceGuidance), enabled);
    unawaited(_updateBackend({'voice_guidance_enabled': enabled}));
  }

  /// 画面常時点灯の有効/無効を設定
  Future<void> setKeepScreenAwake(bool enabled) async {
    state = state.copyWith(keepScreenAwake: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_baseKeepScreenAwake), enabled);
    unawaited(_updateBackend({'keep_screen_awake': enabled}));
  }

  /// 自動リルートの有効/無効を設定
  Future<void> setAutoReroute(bool enabled) async {
    state = state.copyWith(autoRerouteEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(_baseAutoReroute), enabled);
    unawaited(_updateBackend({'auto_reroute_enabled': enabled}));
  }

  /// 地図タイプを設定 ('normal', 'satellite', 'terrain')
  Future<void> setMapType(String mapTypeKey) async {
    state = state.copyWith(mapTypeKey: mapTypeKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_baseMapType), mapTypeKey);
    unawaited(_updateBackend({'map_type': mapTypeKey}));
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
  final authState = ref.watch(authProvider);
  final userId =
      authState is AuthAuthenticated ? authState.user.userId : null;
  return SettingsNotifier(userId: userId);
});

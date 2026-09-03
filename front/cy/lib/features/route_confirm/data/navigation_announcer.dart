import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class NavigationAnnouncer {
  Future<void> initialize();
  Future<void> speak(String message, {bool urgent = false});
  Future<void> vibrate();
  Future<void> stop();
}

class DeviceNavigationAnnouncer implements NavigationAnnouncer {
  final FlutterTts _tts;
  bool _initialized = false;

  DeviceNavigationAnnouncer({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _tts.setAudioAttributesForNavigation();
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      await _tts.setSharedInstance(true);
    }
    _initialized = true;
  }

  @override
  Future<void> speak(String message, {bool urgent = false}) async {
    await initialize();
    // 古い案内を読み続けると曲がり角を過ぎるため、常に最新の内容へ置き換える。
    await _tts.stop();
    await _tts.speak(message, focus: true);
  }

  @override
  Future<void> vibrate() => HapticFeedback.mediumImpact();

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

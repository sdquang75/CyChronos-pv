import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;

class ApiClient {
  // back の既定ポートは 3000(back/.env の PORT)
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// 実機(Android/iOS)では "localhost" は端末自身を指すため PC のバックエンドに繋がらない。
  /// 実機で動かす場合は起動時に指定する(PCのLAN IPに置き換える):
  ///   flutter run --dart-define=API_BASE_URL=http://PCのLAN_IP:3000
  /// エミュレータ/シミュレータは自動判定されるため、指定があっても無視して
  /// ホストPC向けのアドレス(10.0.2.2 / localhost)を使う。
  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: _fallbackBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// 実機/エミュレータの判定前に使う暫定URL(init() 完了後に確定する)。
  static String get _fallbackBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000'; // Android エミュレータから見たホストPC
    }
    return 'http://localhost:3000'; // Web / iOS シミュレータはホストと localhost を共有
  }

  /// アプリ起動時(runApp より前)に一度呼ぶ。
  /// 実機かエミュレータかを実行時に判定して接続先を確定する。
  static Future<void> init() async {
    instance.options.baseUrl = await _resolveBaseUrl();
    debugPrint('ApiClient baseUrl: ${instance.options.baseUrl}');
  }

  static Future<String> _resolveBaseUrl() async {
    // Web はホストPC上で動くので localhost でよい(明示指定があればそちら)
    if (kIsWeb) {
      return _envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://localhost:3000';
    }

    final deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await deviceInfo.androidInfo;
      if (!info.isPhysicalDevice) {
        // エミュレータ: 10.0.2.2 がホストPCを指す(--dart-define より優先)
        return 'http://10.0.2.2:3000';
      }
      // 実機: LAN 経由で PC に接続する必要がある
      if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
      debugPrint(
        'ApiClient: Android実機では --dart-define=API_BASE_URL=http://PCのLAN_IP:3000 '
        'を指定しないとバックエンドに接続できません。',
      );
      return 'http://10.0.2.2:3000'; // 接続不可だが明示的なエラーになるよう既定値を返す
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await deviceInfo.iosInfo;
      if (!info.isPhysicalDevice) {
        // シミュレータ: ホストと localhost を共有
        return 'http://localhost:3000';
      }
      if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
      debugPrint(
        'ApiClient: iOS実機では --dart-define=API_BASE_URL=http://PCのLAN_IP:3000 '
        'を指定しないとバックエンドに接続できません。',
      );
      return 'http://localhost:3000';
    }

    // デスクトップ等はホスト上で動く
    return _envBaseUrl.isNotEmpty ? _envBaseUrl : 'http://localhost:3000';
  }
}

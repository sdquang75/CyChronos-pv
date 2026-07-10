import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiClient {
  // back の既定ポートは 3000(back/.env の PORT)
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// 実機(Android/iOS)では "localhost" は端末自身を指すため PC のバックエンドに繋がらない。
  /// 実機で動かす場合は起動時に必ず指定する(PCのLAN IPに置き換える):
  ///   flutter run --dart-define=API_BASE_URL=http://PCのLAN_IP:3000
  static String get _defaultBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000'; // Android エミュレータから見たホストPC
    }
    return 'http://localhost:3000'; // Web / iOS シミュレータはホストと localhost を共有
  }

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: _envBaseUrl.isNotEmpty ? _envBaseUrl : _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}

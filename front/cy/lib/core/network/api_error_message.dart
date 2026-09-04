import 'package:dio/dio.dart';

import 'api_client.dart';

/// API呼び出しの失敗理由を、ユーザーが次に何をすべきか分かる文言に変換する。
///
/// 失敗を一律に「通信環境を確認してください」と表示すると、
/// サーバー未起動・接続先の設定ミス・外部APIの障害まで電波の問題に見えてしまい、
/// 原因にたどり着けない。原因ごとに切り分けた文言を返す。
///
/// [fallback] は原因を特定できなかったときに使う、画面ごとの文言。
String describeApiError(Object error, {required String fallback}) {
  if (error is! DioException) return fallback;

  // レスポンスが無い = リクエストがサーバーまで届いていない。
  // 電波よりも「バックエンドが起動していない」「接続先が違う」ことが多い
  if (error.response == null) {
    final hint = ApiClient.configWarning ?? 'バックエンドが起動しているか確認してください。';

    switch (error.type) {
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'サーバーの応答がありませんでした。時間をおいてもう一度お試しください。';
      default:
        return 'サーバーに接続できませんでした。$hint';
    }
  }

  // サーバーは応答した。バックエンドが返した文言をそのまま見せるのが一番具体的
  final data = error.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }

  if (error.response?.statusCode == 401) {
    return 'ログインの有効期限が切れました。もう一度ログインしてください。';
  }

  return fallback;
}

import 'api_client.dart';

/// スポット写真のURLを組み立てる共通関数(一覧のサムネイルと詳細画面で使う)。
/// photoReference が無いスポットは null を返す(呼び出し側で仮画像を表示する)
String? placePhotoUrl(String? photoReference, {int maxwidth = 800}) {
  if (photoReference == null || photoReference.isEmpty) return null;

  // バックの写真プロキシ(/api/maps/photo)経由で取得する(APIキーはバック側で秘匿)
  return Uri.parse(ApiClient.instance.options.baseUrl)
      .replace(
        path: '/api/maps/photo',
        queryParameters: {
          'photoReference': photoReference,
          'maxwidth': '$maxwidth',
        },
      )
      .toString();
}

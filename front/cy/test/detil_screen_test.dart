// 目的地詳細画面(DetilScreen)の表示テスト。
// データが揃っているとき・欠けているときの両方で、画面が正しく表示されるかを確認する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cy/features/detil/detil.dart';

// テスト用にMaterialAppで包んで画面を組み立てるヘルパー
Widget _wrap(Widget screen) {
  return MaterialApp(home: screen);
}

void main() {
  testWidgets('データが全部あるとき: 名前・住所・ジャンル(日本語)・評価・距離・所要時間が表示される',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const DetilScreen(
      name: 'テストカフェ',
      address: '東京都千代田区丸の内1-1',
      genre: 'cafe',
      durationSec: 4500, // 1時間15分
      distanceMeter: 8800, // 8.8km
      rating: 4.2,
    )));

    expect(find.text('テストカフェ'), findsOneWidget); // 名前
    expect(find.text('東京都千代田区丸の内1-1'), findsOneWidget); // 住所
    expect(find.text('カフェ'), findsOneWidget); // 英語ジャンルが日本語になる
    expect(find.text('4.2'), findsOneWidget); // 評価
    expect(find.text('8.8km'), findsOneWidget); // 距離(km)
    expect(find.text('1時間15分'), findsOneWidget); // 所要時間
  });

  testWidgets('データが欠けているとき: 仮の文言や「--」で表示され、画面が壊れない',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const DetilScreen(
      name: '',
      address: '',
      genre: '',
      // durationSec / distanceMeter / rating / imageUrl は渡さない(=null)
    )));

    expect(find.text('観光地名'), findsOneWidget); // 名前なしは仮の名前
    expect(find.text('ジャンル'), findsOneWidget); // ジャンルなしは仮ラベル
    expect(find.text('評価なし'), findsOneWidget); // 評価なし表示
    expect(find.text('住所不明'), findsOneWidget); // 住所なしは仮の文言
    expect(find.text('--km'), findsOneWidget); // 距離不明
    expect(find.text('--'), findsOneWidget); // 所要時間不明

    // 写真URLが無いときは仮画像(アセット)が使われている
    final image = tester.widget<Image>(find.byType(Image).last);
    expect(image.image, isA<AssetImage>());
  });

  testWidgets('変換表に無いジャンルは英語のまま表示される', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const DetilScreen(
      name: 'テスト施設',
      address: '住所',
      genre: 'aquarium', // 変換表に無いジャンル
    )));

    expect(find.text('aquarium'), findsOneWidget);
  });

  testWidgets('距離の末尾の0は削られる(3000m → 3km)', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const DetilScreen(
      name: 'テスト',
      address: '住所',
      genre: 'park',
      distanceMeter: 3000,
    )));

    expect(find.text('3km'), findsOneWidget); // 「3.000km」ではなく「3km」
  });

  testWidgets('所要時間が60分未満のときは「0時間」を付けずに◯分だけになる(1800秒 → 30分)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const DetilScreen(
      name: 'テスト',
      address: '住所',
      genre: 'park',
      durationSec: 1800,
    )));

    expect(find.text('30分'), findsOneWidget);
  });
}

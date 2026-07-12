import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Google Placesの英語ジャンル(type) → 画面表示用の日本語ラベルの変換表
const Map<String, String> _genreLabels = {
  'cafe': 'カフェ',
  'restaurant': 'レストラン',
  'food': 'グルメ',
  'park': '公園',
  'museum': '美術館・博物館',
  'tourist_attraction': '観光名所',
  'place_of_worship': '寺社・教会',
  'store': 'ショップ',
  'point_of_interest': '観光スポット',
  'establishment': '施設',
};

class DetilScreen extends StatelessWidget {

  final String name;
  final String address;
  final String genre; // Google Placesの英語ジャンル(例: cafe)。表示時に日本語へ変換する
  final String? imageUrl; // スポット写真のURL(写真が無いときは null = 仮画像を表示)
  final int? durationSec; // 現在地からの所要時間(秒)。不明なら null
  final int? distanceMeter; // 現在地からの距離(m)。不明なら null
  final double? rating; // Googleの星評価(例: 4.2)。評価なしは null
  final Map<String, dynamic> destination; // 目的地1件分の元データ(ルート確認画面へそのまま引き継ぐ)


  const DetilScreen(
    {
      super.key,
      required this.name,
      required this.address,
      required this.genre,
      this.imageUrl, // 写真URLを受け取る(省略可)
      this.durationSec, // 所要時間を受け取る(省略可)
      this.distanceMeter, // 距離を受け取る(省略可)
      this.rating, // 評価を受け取る(省略可)
      this.destination = const {}, // 元データを受け取る(省略可)
    });

  // 英語ジャンルを日本語にして返す(変換表に無いものは英語のまま表示)
  String _genreLabel() {
    if (genre.isEmpty) return 'ジャンル';
    return _genreLabels[genre] ?? genre;
  }

  // 距離をkm表示用の文字列にする(小数3桁まで・末尾の0は削る)。不明なら「--」
  String _distanceText() {
    final meters = distanceMeter;
    if (meters == null) return '--';
    return (meters / 1000).toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  // 所要時間の「時間」部分の文字列。不明なら「--」
  String _durationHoursText() {
    final sec = durationSec;
    if (sec == null) return '--';
    return (sec ~/ 3600).toString();
  }

  // 所要時間の「分」部分の文字列。不明なら「--」
  String _durationMinutesText() {
    final sec = durationSec;
    if (sec == null) return '--';
    return ((sec % 3600) ~/ 60).toString();
  }

  // スポット写真を表示する。URLが無いとき・読み込みに失敗したときは仮画像に切り替える
  Widget _buildPhoto() {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return Image.asset('assets/testimage.png', fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      // 読み込み中はインジケーターを出す
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      // 通信失敗でも画面を壊さず仮画像を出す
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/testimage.png', fit: BoxFit.cover);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Image(
          image: AssetImage('assets/logo_long.png'),
          height: 40, // 高度制限
          fit: BoxFit.contain,
        ),
      ),
      body: SingleChildScrollView( // 縦に長い画面なので、小さい端末でもスクロールして全部見られるようにする
        child: Column(
          children: [
             SizedBox(
                width: double.infinity, // 横幅を画面いっぱいに広げる
                height: 10,
              ),
            /*Image(
              image: AssetImage('assets/testimage.png'),
              width: 500,
              height: 100, 
              fit: BoxFit.contain,
            ),*/
            Container(
              width: double.infinity, // 横幅を画面いっぱいに広げる
              height: 250,
              margin: EdgeInsets.all(8),
              clipBehavior: Clip.antiAlias, // 角丸から画像がはみ出さないよう切り抜く
              decoration: BoxDecoration(
                color: const Color(0xFFF1EBFF), // 画像読み込み中の背景色
                borderRadius: BorderRadius.circular(12), // 圓角
              ),
              child: _buildPhoto(), // スポット写真(URLなし・失敗時は仮画像)
            ),
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 70,
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 30,
                    padding: EdgeInsets.only(left: 16), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
                    ),
                    child:
                      Text(
                        name.isNotEmpty ? name : '観光地名',
                        maxLines: 1, // 長い名前は1行に収めて…で省略する
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 25, color: Colors.black), // 文字サイズと色
                      ),
                  ),
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 35,
                    padding: EdgeInsets.only(left: 20), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 12), // 左右の余白を追加(ジャンル名の長さに合わせて幅が伸びる)
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角]
                            border: Border.all(
                              color: const Color.fromARGB(255, 185, 185, 185), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _genreLabel(), // ジャンルを日本語で表示
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Googleの星評価。評価が無いスポットは「評価なし」と表示する
                        Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: const Color(0xFFFFB300), // 星は金色
                        ),
                        SizedBox(width: 4),
                        Text(
                          rating != null ? rating!.toStringAsFixed(1) : '評価なし',
                          style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 220, // 場所紹介の削除に合わせて 400 から詰めた
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 80,
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 25,
                          padding: EdgeInsets.symmetric(horizontal: 8 ), // 左右の余白を追加vertical: 1.5
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角]
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: 
                            Text(
                              '住所',
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 30,
                          padding: EdgeInsets.symmetric(horizontal: 8), // 左右の余白を追加
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child:
                            Text(
                              address.isNotEmpty ? address : '住所',
                              maxLines: 1, // 長い住所は1行に収めて…で省略する(枠からのはみ出し防止)
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 35,
                    padding: EdgeInsets.only(left: 20, right: 20), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 120,
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 8 ), // 左右の余白を追加vertical: 1.5
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角]
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: 
                            Text(
                              '距離',
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 8), // 左右の余白を追加
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          // 枠より中身が長くても、縮小して収める(はみ出し防止)
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 15,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                                Text(
                                  _distanceText(), // 距離をkmで表示(不明なら「--」)
                                  style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                                ),
                                SizedBox(width: 5), // アイコンとテキストの間にスペースを追加
                                Text(
                                  'km',
                                  style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 35,
                    padding: EdgeInsets.only(left: 20, right: 20), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: 120,
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 8 ), // 左右の余白を追加vertical: 1.5
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角]
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: 
                            Text(
                              '所要時間',
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                          ),
                        ),
                        Container(
                          width: 140,
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 8), // 左右の余白を追加
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          // 枠より中身が長くても、縮小して収める(はみ出し防止)
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 15,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                                Text(
                                  _durationHoursText(), // 所要時間の「時間」部分(不明なら「--」)
                                  style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '時間',
                                  style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                                ),
                                SizedBox(width: 5),
                                Text(
                                  _durationMinutesText(), // 所要時間の「分」部分(不明なら「--」)
                                  style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '分',
                                  style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 「場所紹介」はAPIから取得できるデータが無いため削除した(2026-07-12)
                ],
              ),
            ),
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 125, // ボタン2つ(55+50)が収まる高さにする(100だとはみ出す)
              margin: EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // 目的地データを丸ごと渡してルート確認画面へ(pushなので「戻る」でここに帰れる)
                      context.push('/route_confirm', extra: destination);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size( 250, 55), // 幅を50に設定
                      backgroundColor: const Color.fromARGB(255, 9, 31, 156), // 背景色
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 圓角
                        side: BorderSide(
                          color: const Color.fromARGB(255, 218, 218, 218), // 影の色
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Text(
                      'ルートを見る',
                      style: TextStyle(fontSize: 25, color: Colors.white), // 文字サイズと色
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // ボタンが押されたときの処理
                      /*Navigator.of(context).push(MaterialPageRoute(builder: (context) { 
                      return const RouteConfirmScreen(); 
                      }));*/
                      
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size( 250, 50), // 幅を50に設定
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // 背景色
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // 圓角
                        side: BorderSide(
                          color: const Color.fromARGB(255, 3, 11, 59), // 影の色
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Text(
                      'お気に入り登録',
                      style: TextStyle(fontSize: 25, color: Colors.black), // 文字サイズと色
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


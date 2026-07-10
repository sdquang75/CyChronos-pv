import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetilScreen extends StatelessWidget {

  final String name;
  final String address;
  final String genre;
  final String imagePath; // 画像のパスを指定
  final int durationSec;
  final int distanceMeter; // 距離をメートル単位で指定
  final String description; // 場所紹介のテキストを指定


  const DetilScreen(
    {
      super.key, 
      required this.name,
      required this.address,
      required this.genre,
      required this.imagePath, // 画像のパスを受け取る
      required this.durationSec,
      required this.distanceMeter, // 距離を受け取る
      required this.description, // 場所紹介のテキストを受け取る
    });

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
      body: Center(
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
              width: double.infinity, // 横幅を画面の半分に設定
              height: 250,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath.isNotEmpty ? 'assets/$imagePath' : 'assets/testimage.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12), // 圓角
              ),
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
                          width: 80,
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 8 ), // 左右の余白を追加vertical: 1.5
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
                              genre.isNotEmpty ? genre : 'ジャンル',
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 400,
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
                                (distanceMeter / 1000).toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), ''), // 距離を計算して表示（小数点以下3桁まで、末尾の0は削除） 
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
                                durationSec/3600 >= 1 ? (durationSec/3600).toStringAsFixed(0) : '0', // 時間を計算して表示
                                style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                              ),
                              SizedBox(width: 5),
                              Text(
                                '時間',
                                style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                              ),
                              SizedBox(width: 5),
                              Text(
                                (durationSec % 3600 / 60) >= 1 ? (durationSec % 3600 / 60).toStringAsFixed(0) : '0', // 分を計算して表示
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
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 160,
                    padding: EdgeInsets.only(left: 16), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),          // 背景色
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '場所紹介',
                          style: TextStyle(fontSize: 25, color: Colors.black), // 文字サイズと色
                        ),
                        SizedBox(height: 8), // 上下の余白を追加
                        Text(
                          description.isNotEmpty ? description : '場所の紹介テキスト', // 場所紹介のテキストを表示
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
              height: 100,
              margin: EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // ボタンが押されたときの処理
                      GoRouter.of(context).go('/route_confirm');
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


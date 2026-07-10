import 'package:flutter/material.dart';

class RouteConfirmScreen extends StatelessWidget {

  final int durationSec;
  final int distanceMeter;
  const RouteConfirmScreen({
    super.key, 
    required this.durationSec, 
    required this.distanceMeter
  });

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: const Image(
          image: AssetImage('assets/logo_long.png'),
          height: 40, // 高度制限
          fit: BoxFit.contain,
        ),
      ),*/
      body: Center(
        child: Column(
          children: [
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 600,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/testimage.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 330,
              margin: EdgeInsets.all(5),
              
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12), // 圓角          // 背景色
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 35,
                    padding: EdgeInsets.only(left: 20, right: 20), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255), 
                      borderRadius: BorderRadius.circular(12), // 圓角           // 背景色
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
                  SizedBox(height: 60),// ボタンの上にスペースを追加
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
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size( 260, 55), // 幅を50に設定
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
                              'ナビ開始',
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
                              'ルートを変更する',
                              style: TextStyle(fontSize: 25, color: Colors.black), // 文字サイズと色
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
}
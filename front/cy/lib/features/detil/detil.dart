import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetilScreen extends StatelessWidget {
  const DetilScreen({super.key});

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
                  image: AssetImage('assets/testimage.png'),
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
                        '場所名',
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
                              'tag1',
                              style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 35,
                          padding: EdgeInsets.symmetric(horizontal: 8), // 左右の余白を追加
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 圓角
                            border: Border.all(
                              color: const Color.fromARGB(255, 185, 185, 185), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'tag2',
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
                              'oo県oo市oo町oo番地',
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
                                '1.5',
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
                                '01',
                                style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                              ),
                              SizedBox(width: 5),
                              Text(
                                '時間',
                                style: TextStyle(fontSize: 15, color: Colors.black), // 文字サイズと色
                              ),
                              SizedBox(width: 5),
                              Text(
                                '30',
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
                          '00県00市00町00番地にある観光スポットです。美しい景色や歴史的な建造物が楽しめます。',
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


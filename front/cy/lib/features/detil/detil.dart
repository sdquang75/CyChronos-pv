import 'package:flutter/material.dart';

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
              child: Text('Hello'),
            ),
            Container(
              width: double.infinity, // 横幅を画面の半分に設定
              height: 70,
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 43, 78),          // 背景色
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 30,
                    padding: EdgeInsets.only(left: 16), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 100, 43, 78),          // 背景色
                    ),
                    child: 
                      Text(
                        '詳細画面1',
                        style: TextStyle(fontSize: 25, color: Colors.white), // 文字サイズと色
                      ),
                  ),
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 35,
                    padding: EdgeInsets.only(left: 20), // 上部の余白を追加
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 100, 43, 78),          // 背景色
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
                              color: const Color.fromARGB(255, 255, 130, 207), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: 
                            Text(
                              '詳細画面2',
                              style: TextStyle(fontSize: 15, color: Colors.white), // 文字サイズと色
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
                              color: const Color.fromARGB(255, 255, 130, 207), // 枠線の色
                              width: 1.0, // 枠線の太さ
                            ),
                          ),
                          child: 
                            Text(
                              '詳細画面3',
                              style: TextStyle(fontSize: 15, color: Colors.white), // 文字サイズと色
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '詳細画面',
              style: TextStyle(fontSize: 50),
            ),
            Text(
              'Detil Screen',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}


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
              height: 50,
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.blue,          // 背景色
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 水平方向の中央揃え
                children: [
                   Text(
                    '詳細画面',
                    style: TextStyle(fontSize: 25, color: Colors.white), // 文字サイズと色
                  ),
                  Container(
                    width: double.infinity, // 横幅を画面の半分に設定
                    height: 20,
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.blue,          // 背景色
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // 水平方向の中央揃え
                      children: [
                        Text(
                          '詳細画面',
                          style: TextStyle(fontSize: 5, color: Colors.white), // 文字サイズと色
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


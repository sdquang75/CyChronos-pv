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
            Text(
              'Detil Screen',
              style: TextStyle(fontSize: 24),
            ),
            Text(
              'Detil Screen',
              style: TextStyle(fontSize: 24),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 1.5, // 横幅を画面の半分に設定
              height: 500,
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,          // 背景色
                borderRadius: BorderRadius.circular(12), // 圓角
                border: Border.all(color: Colors.black), // 邊框
                boxShadow: [                 // 陰影
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Text('Hello'),
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


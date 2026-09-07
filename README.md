# CyChronos
3年チーム制作前期

## 起動手順


### 1. Google Maps APIキーの設定
Google Maps用のAPIキーを `front/cy/android/local.properties`に1行追加する:

```properties
MAPS_API_KEY=
```


### 2. バックエンドの起動
```bash
cd back
npm install
npm start
```


### 3. フロントエンドの起動
```bash
cd front/cy
flutter pub get
flutter run
```

実機またはLAN経由でバックエンドに接続する場合は `--dart-define=API_BASE_URL` を指定します:
```bash
flutter run --dart-define=API_BASE_URL=http://<PCのLAN_IP>:3000
```
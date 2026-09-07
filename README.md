# CyChronos
3年チーム制作前期

## 起動手順 (Quick Start)

バックエンド/DBのセットアップが済んでいる前提で、以下の手順で起動できます。

### 1. Google Maps APIキーの設定
Google Maps用のAPIキーを `front/cy/android/local.properties`(git管理外なので各自作成・追記が必要)に1行追加する:

```properties
MAPS_API_KEY=(チームで共有されているキーを貼る。分からなければ聞くこと)
```
※ `local.properties` に未設定のままビルドすると、Gradle が警告メッセージを表示します。

### 2. バックエンドの起動
```bash
cd back
npm install
npm start
```
※ サーバー起動時に必要なテーブル(`user_settings` 等)は自動的に初期化・マイグレーションされます。

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
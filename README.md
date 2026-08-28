# CyChronos
3年チーム制作前期

## 動作確認用: `feature/native-ux-polish` ブランチを試す(まだmainには未マージ)

UI/UX周りの修正をまとめたブランチ。他の人の作業とコンフリクトするのを避けたいので、動作確認が済むまでは意図的に `main` にマージしていない。触ってみたい人は以下だけでOK。バックエンド/DBのセットアップが済んでいる前提。

```bash
git fetch origin
git checkout feature/native-ux-polish
git pull origin feature/native-ux-polish
```

Google Maps用のAPIキーを `front/cy/android/local.properties`(git管理外なので各自作成・追記が必要)に1行追加する:

```
MAPS_API_KEY=(チームで共有されているキーを貼る。分からなければ聞くこと)
```

あとはいつも通り起動:

```bash
cd front/cy
flutter pub get
flutter run

 flutter run --dart-define=API_BASE_URL=http://<PCのIP>:3000

// flutter run -d 127.0.0.1:5555 --dart-define=API_BASE_URL=http://192.168.1.242:3000

```

`main` に戻りたいときは:

```bash
git checkout main
```
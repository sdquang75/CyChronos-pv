# CyChronos
3年チーム制作前期

## 動作確認用: `feature/native-ux-polish` ブランチを試す(まだmainには未マージ)

UI/UX周りの修正をまとめたブランチ。他の人の作業とコンフリクトするのを避けたいので、動作確認が済むまでは意図的に `main` にマージしていない。触ってみたい人は以下だけでOK(バックエンド/DBのセットアップが済んでいる前提。まだの人は下の「0. 事前準備」から)。

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

---

## 0. 事前準備(最初の1回だけ)

### 0-1. Docker Desktop をインストール・起動する

- https://www.docker.com/products/docker-desktop/ からダウンロードしてインストール
- インストール後、Docker Desktop を起動する
- タスクトレイ(画面右下)のクジラのアイコンが動いていなければ起動完了。アイコンにカーソルを合わせて「Docker Desktop is running」と出ればOK

### 0-2. リポジトリを取得する

```bash
git clone <このリポジトリのURL>
cd CyChronos
```

### 0-3. バックエンドの環境変数ファイルを作る

```bash
cd back
cp .env.example .env
```

`back/.env` をエディタで開いて、以下をチームで共有されている値に書き換える:
- `FIREBASE_PROJECT_ID`
- `MAPBOX_ACCESS_TOKEN`
- `GOOGLE_PLACES_API_KEY`

`PORT` と `DB_*` の項目はそのままでOK(Dockerの設定と最初から揃えてある)。

---

## 1. データベース(MySQL)をDockerで起動する

### 1-1. 事前チェック: パソコンに既にMySQLが入っていないか確認する

これを飛ばすと、後で「Dockerの中のMySQL」ではなく「パソコンに直接入っているMySQL」に間違って繋いでしまい、原因不明のエラーで詰まることがある。先に確認しておく。

コマンドプロンプト/PowerShell/Git Bashのどれでもいいので、以下を実行:

```bash
netstat -ano | findstr :3306
```

- **何も表示されない** → 3306番ポートは空いている。このあとの手順をそのまま進めてOK
- **何か表示される**(`LISTENING` という行がある) → 既に何かがMySQLの3306番ポートを使っている(WindowsにインストールしたMySQL、XAMPPなど)。この場合は [1-4](#1-4-3306番ポートが既に使われている場合) を先に読んでからDockerを起動すること

### 1-2. MySQLコンテナを起動する

リポジトリの一番上の階層(`docker-compose.yml` がある場所)で実行する:

```bash
docker compose up -d
```

- 初回はMySQLのイメージ(約130MB)のダウンロードが走るので1〜2分かかる
- ダウンロード後、`back/db/cydump.sql` の中身(テーブル定義+サンプルデータ)が自動で読み込まれる
- `-d` はバックグラウンドで起動するという意味(ターミナルが専有されない)

### 1-3. ちゃんと起動できたか確認する

```bash
docker compose ps
```

出力例:

```
NAME              IMAGE       STATUS                    PORTS
cychronos-mysql   mysql:8.4   Up 10 seconds (healthy)   0.0.0.0:3306->3306/tcp
```

チェックするポイント:
- `STATUS` が `(healthy)` になっている(`(health: starting)` の場合は数秒待ってもう一度実行する)
- `PORTS` に出ているポート番号(上の例では `3306`)が、`back/.env` の `DB_PORT` と**必ず同じ数字**になっていること

この2つが合っていれば、バックエンドは確実にDockerの中のMySQLに繋がる。

### 1-4. 3306番ポートが既に使われている場合

[1-1](#1-1-事前チェック-パソコンに既にmysqlが入っていないか確認する) で何か表示された場合、`docker compose up -d` を実行すると以下のようなエラーになる:

```
Error response from daemon: ports are not available: exposing port TCP 0.0.0.0:3306 -> ...
```

対処: リポジトリの一番上の階層に(`back/.env` とは別の場所)`.env` という名前のファイルを新しく作り、中身を以下にする:

```
MYSQL_HOST_PORT=3307
```

(3307が既に使われている場合は3308など、空いている番号にする)

その後、`back/.env` を開いて `DB_PORT` の値も同じ数字に変更する:

```
DB_PORT=3307
```

変更したら、もう一度 [1-2](#1-2-mysqlコンテナを起動する) からやり直す。

このルート直下の `.env` は自分のパソコン専用の設定なので、gitにはコミットされない(`.gitignore` 済み)。他の人の設定には影響しない。

### 1-5. 【重要】自分が今どのMySQLに繋がっているか確信が持てないとき

一番確実な方法は、パソコンに直接入っているmysqlコマンドを使わず、**必ずDockerコンテナの中に入ってmysqlを実行する**こと。この方法なら、パソコン側に何がインストールされていても関係なく、100%Docker側のMySQLに繋がる。

```bash
docker exec -it cychronos-mysql mysql -u cyuser -p123qwecc cychronos
```

- `docker exec -it cychronos-mysql` = 「`cychronos-mysql` という名前のコンテナの中に入って」という意味
- そのあとの `mysql -u cyuser -p123qwecc cychronos` はコンテナの中で実行されるコマンド

⚠️ 逆に、パソコンに直接インストールした `mysql` コマンドや、MySQL Workbenchなどのツールで `localhost` に接続する場合は要注意。特にWindowsでは `host=localhost` を指定すると、意図せずパソコンに元から入っているMySQLの方に繋がってしまうことがある(TCPではなく別経路で接続されるため)。ツールで繋ぐ場合は `localhost` ではなく `127.0.0.1` を指定し、ポート番号も [1-3](#1-3-ちゃんと起動できたか確認する) で確認した番号を必ず明示すること。迷ったら上記の `docker exec` の方法を使うのが一番安全。

---

## 2. バックエンドを起動する

```bash
cd back
npm install
npm run dev
```

正常に起動すると、ターミナルに以下のような行が出る:

```
Server running on port 3000
```

もし `Error: Plugin 'mysql_native_password' is not loaded` のようなエラーが出た場合、それはDockerのMySQLではなくパソコン側のMySQLに繋がろうとしている合図。[1-3](#1-3-ちゃんと起動できたか確認する) に戻って `back/.env` の `DB_PORT` を確認する。

起動確認: ブラウザで `http://localhost:3000` を開き、以下が表示されればOK

```json
{"message":"CyChronos API is running"}
```

さらに、DBに実際に繋がっているかもチェックしたい場合:

```bash
curl http://localhost:3000/api/trips?user_id=1
```

`cydump.sql` に入っているサンプルの走行データ(配列)が返ってくれば、DB接続まで含めて正常に動いている。

## 3. フロントエンドを起動する

```bash
cd front/cy
flutter pub get
flutter run
```

---

## Dockerコンテナ内のMySQLアカウント

| ユーザー | パスワード | 用途 |
|---|---|---|
| `root` | `123qwecc` | 管理者(ユーザー作成・権限変更など) |
| `cyuser` | `123qwecc` | バックエンドアプリが使う用(`back/.env` の `DB_USER`/`DB_PASSWORD`)。`cychronos` DBのみ権限あり |

管理者として接続する場合(必ずコンテナの中から):

```bash
docker exec -it cychronos-mysql mysql -u root -p123qwecc
```

## バックエンド担当者向け: DBスキーマを変更したとき

1. コンテナの中に入って、まず手元で `ALTER TABLE` などを試す(必ず `docker exec` 経由で。パソコン側の `mysql` コマンドは使わない)
   ```bash
   docker exec -it cychronos-mysql mysql -u cyuser -p123qwecc cychronos
   ```
2. 変更内容が固まったら、最新のスキーマ+サンプルデータでダンプファイルを上書きする
   ```bash
   docker exec cychronos-mysql mysqldump --no-tablespaces -u cyuser -p123qwecc cychronos > back/db/cydump.sql
   ```
   これも `docker exec` 経由なので、常にDocker側のMySQLの中身が書き出される(パソコン側のMySQLが混ざる心配はない)。
3. `back/db/DATABASE.md`(テーブル定義書)と `back/docs/API.md` も変更内容に合わせて更新する
4. `back/db/cydump.sql` と `back/db/DATABASE.md` を含めてcommit・push する

## 全員向け: 更新された `cydump.sql` を自分のDBに反映するとき

`cydump.sql` はコンテナの**初回起動時にしか読み込まれない**ため、`git pull` しただけではDBの中身は更新されない。以下のコマンドで一度作り直す必要がある。

```bash
git pull
docker compose down -v
docker compose up -d
```

各コマンドの意味:
- `docker compose down -v` = コンテナを止めて、データが入っているvolumeごと削除する(`-v` を付けないとデータが残ってしまい、古いままになる)
- `docker compose up -d` = コンテナを作り直す。volumeが空の状態から始まるので、`cydump.sql` が自動でもう一度読み込まれる

⚠️ `down -v` を実行すると、今ローカルにあるDBの中身(サンプルデータ含む)は全て消えて、最新の `cydump.sql` の内容で作り直される。自分で入れた大事なテストデータがある場合は事前に注意すること(通常は気にしなくてOK)。

実行後は [1-3](#1-3-ちゃんと起動できたか確認する) と同じ手順で `docker compose ps` で `healthy` になっているか確認する。

---

## トラブルシューティング

**`Error: Plugin 'mysql_native_password' is not loaded`**
→ ほぼ確実に、Docker側ではなくパソコンに直接インストールしたMySQL(バージョンが新しく、このプラグインが廃止されている)に接続している。
1. `docker compose ps` でDockerコンテナの `PORTS` を確認する
2. `back/.env` の `DB_HOST=localhost` / `DB_PORT` がその番号と一致しているか確認する
3. 一致していない場合は `back/.env` の `DB_PORT` を修正して `npm run dev` を再起動(`rs` と入力)

**`ports are not available: ... 3306`**
→ [1-4](#1-4-3306番ポートが既に使われている場合) を参照。

**`docker compose` コマンドが動かない・反応しない**
→ Docker Desktopが起動しているか確認する(タスクトレイのアイコン)。起動していてもエラーが出る場合はDocker Desktopを再起動する。

**DBに接続できない・データが古い / 他の人と自分でデータが違う**
→ 以下を順に確認する
1. `docker compose ps` でコンテナが `healthy` か
2. `back/.env` の `DB_PORT` がコンテナの `PORTS` と一致しているか
3. 最新の `cydump.sql` を取り込めているか([全員向けの手順](#全員向け-更新された-cydumpsql-を自分のdbに反映するとき)を実行したか)

**とにかく「今どっちのMySQLに繋がっているか」が分からず不安なとき**
→ [1-5](#1-5-重要自分が今どのmysqlに繋がっているか確信が持てないとき) の `docker exec -it cychronos-mysql mysql ...` を使う。この方法なら常に100%Docker側に繋がるので、パソコン側のMySQLと混同する心配が一切ない。

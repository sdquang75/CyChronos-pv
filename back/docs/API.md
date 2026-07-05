# CyChronos API 仕様書

サイクリングナビアプリのバックエンドAPI。走行中の座標ログの保存・取得・削除を提供する。

- ベースURL: `http://localhost:3000`(ポートは `.env` の `PORT` で変更可)
- データ形式: リクエスト・レスポンスともに JSON(`Content-Type: application/json`)
- DB: MySQL 8.4 / データベース `cychronos`

## エンドポイント一覧

| 機能 | メソッド | パス | 引数 |
|---|---|---|---|
| トリップ開始 | POST | `/api/trips/start` | user_id(ボディ) |
| トリップ終了 | POST | `/api/trips/{trip_id}/end` | user_id(ボディ), trip_id(パス) |
| 座標保存 | POST | `/api/locations` | user_id, trip_id, lat, lng(ボディ) |
| ログ全件取得 | GET | `/api/trips` | user_id(クエリ) |
| ログ単体取得 | GET | `/api/trips/{trip_id}` | user_id(クエリ), trip_id(パス) |
| ログ削除(論理削除) | DELETE | `/api/trips/{trip_id}` | user_id(クエリ), trip_id(パス) |

想定フロー: **トリップ開始**で `trip_id` を取得 → ナビ画面が一定間隔で**座標保存**を呼ぶ → 走行終了時に**トリップ終了** → 履歴画面で**取得**、不要になったら**削除**。

---

## 0-1. トリップ開始

新しいトリップ(`trip_history`)を作成し、採番された `trip_id` を返す。`status` は `active`、`start_time` はサーバー受信時刻で登録される。

```
POST /api/trips/start
```

### リクエストボディ

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| user_id | integer | ○ | ユーザーID |
| destination_name | string | - | 目的地名(省略時は空文字) |
| destination_url | string | - | 目的地URL(省略時は null) |

```json
{ "user_id": 1 }
```

### レスポンス(201 Created)

```json
{ "trip_id": 4 }
```

| ステータス | 内容 |
|---|---|
| 201 Created | 作成成功。作成された trip_id を返す |
| 400 Bad Request | user_id 不正 |
| 404 Not Found | ユーザーが存在しない |

---

## 0-2. トリップ終了

トリップの `status` を `active` から `completed` に変更し、`end_time` にサーバー受信時刻を登録する。

```
POST /api/trips/{trip_id}/end
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| trip_id | パス | ○ | 終了するトリップID |
| user_id | ボディ | ○ | ユーザーID(所有者チェック) |

```json
{ "user_id": 1 }
```

### レスポンス(200 OK)

更新後のトリップを返す。

```json
{
  "trip_id": 4,
  "user_id": 1,
  "destination_name": "",
  "destination_url": null,
  "start_time": "2026-07-03T02:52:22.000Z",
  "end_time": "2026-07-03T02:52:32.000Z",
  "total_distance_m": null,
  "duration_sec": null,
  "average_speed_kmh": null,
  "status": "completed",
  "created_at": "2026-07-03T02:52:22.000Z",
  "updated_at": "2026-07-03T02:52:32.000Z"
}
```

| ステータス | 内容 |
|---|---|
| 200 OK | 終了成功。更新後のトリップを返す |
| 400 Bad Request | 引数不正 |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |
| 409 Conflict | トリップが active でない(すでに completed / cancelled) |

---

## 1. 座標保存

サイクリング中にナビ画面が一定間隔で送信する座標を `location_log` テーブルに保存する。

```
POST /api/locations
```

### リクエストボディ

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| user_id | integer | ○ | ユーザーID(トリップの所有者チェックに使用) |
| trip_id | integer | ○ | 保存先のトリップID |
| lat | number | ○ | 緯度(-90〜90) |
| lng | number | ○ | 経度(-180〜180) |

```json
{ "user_id": 1, "trip_id": 1, "lat": 34.6941, "lng": 135.5030 }
```

### 挙動

- `log_num`(トリップ内の連番)はサーバー側で自動採番する
- `recorded_at`(記録日時)はサーバー受信時刻(`NOW()`)を保存する
- トリップが `user_id` のものでない場合・論理削除済みの場合は保存しない

### レスポンス

| ステータス | 内容 |
|---|---|
| 204 No Content | 保存成功(**戻り値なし**) |
| 400 Bad Request | 引数不正 `{"error": "..."}` |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |

---

## 2. ログ全件取得

指定ユーザーのトリップ(走行履歴)一覧を返す。論理削除済みのトリップは含まない。

```
GET /api/trips?user_id={user_id}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| user_id | クエリ | ○ | ユーザーID |

### レスポンス(200 OK)

`start_time` の降順の配列。座標ログは含まない(単体取得で返す)。

```json
[
  {
    "trip_id": 1,
    "user_id": 1,
    "destination_name": "大阪城公園",
    "destination_url": "https://www.osakacastle.net/",
    "start_time": "2026-06-26T01:00:00.000Z",
    "end_time": "2026-06-26T02:20:00.000Z",
    "total_distance_m": 12500,
    "duration_sec": 4800,
    "average_speed_kmh": 9.38,
    "status": "completed",
    "created_at": "2026-06-26T02:51:57.000Z",
    "updated_at": "2026-06-26T02:51:57.000Z"
  }
]
```

該当トリップがない場合は空配列 `[]` を返す。

| ステータス | 内容 |
|---|---|
| 200 OK | トリップ一覧 |
| 400 Bad Request | user_id 不正 |

---

## 3. ログ単体取得

トリップ1件の詳細と、そのトリップの座標ログ一覧(`log_num` 昇順)を返す。

```
GET /api/trips/{trip_id}?user_id={user_id}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| trip_id | パス | ○ | トリップID |
| user_id | クエリ | ○ | ユーザーID(所有者チェック) |

### レスポンス(200 OK)

```json
{
  "trip_id": 1,
  "user_id": 1,
  "destination_name": "大阪城公園",
  "destination_url": "https://www.osakacastle.net/",
  "start_time": "2026-06-26T01:00:00.000Z",
  "end_time": "2026-06-26T02:20:00.000Z",
  "total_distance_m": 12500,
  "duration_sec": 4800,
  "average_speed_kmh": 9.38,
  "status": "completed",
  "created_at": "2026-06-26T02:51:57.000Z",
  "updated_at": "2026-06-26T02:51:57.000Z",
  "locations": [
    {
      "log_id": 1,
      "log_num": 1,
      "lat": 34.6937,
      "lng": 135.5023,
      "recorded_at": "2026-06-26T01:00:10.000Z",
      "speed_kmh": 0,
      "accuracy_m": 5.2
    }
  ]
}
```

| ステータス | 内容 |
|---|---|
| 200 OK | トリップ詳細+座標ログ |
| 400 Bad Request | 引数不正 |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |

---

## 4. ログ削除(論理削除)

トリップを論理削除する。`trip_history.deleted_at` に現在時刻をセットするのみで、レコードは物理削除しない(`location_log` は変更しない)。削除後は取得系APIの結果に含まれなくなる。

```
DELETE /api/trips/{trip_id}?user_id={user_id}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| trip_id | パス | ○ | トリップID |
| user_id | クエリ | ○ | ユーザーID(所有者チェック) |

### レスポンス

| ステータス | 内容 |
|---|---|
| 204 No Content | 削除成功(戻り値なし) |
| 400 Bad Request | 引数不正 |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |

---

## 共通エラー

| ステータス | 発生条件 |
|---|---|
| 404 Not Found | 未定義のパスへのアクセス `{"error": "Not Found"}` |
| 500 Internal Server Error | DB接続失敗などサーバー内部エラー `{"error": "Internal Server Error"}` |

## 関連ファイル

| ファイル | 内容 |
|---|---|
| `src/app.js` | Expressアプリ本体・ルーターのマウント |
| `src/routes/locations.js` | 座標保存API |
| `src/routes/trips.js` | ログ取得・削除API |
| `src/db.js` | MySQL接続プール(接続情報は `.env`) |
| `db/cydump.sql` | DBダンプ(スキーマ+サンプルデータ) |

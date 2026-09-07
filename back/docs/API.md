# CyChronos API 仕様書

## はじめに

認証はフロントでGoogleサインインし、Firebase IDトークンを取得して行う。

### 認証が必要なAPI

| 区分 | 対象 | Authorization ヘッダー |
|---|---|---|
| 必須 | `/api/trips/*`、`/api/locations` | **必須**。無い/無効なら 401 |
| 任意 | `/api/suggest` | 付ければ訪問済みスポットを除外。無くても提案は返る |
| 個別 | `/api/auth/*` | 各APIの記載どおり必須 |
| 不要 | `/api/maps/*` | — |

⚠️ **走行データ系API(トリップ・座標)は `user_id` を引数で受け取らない。** どのユーザーのデータかは検証済みIDトークンから決まる。`user_id` は連番なので、クライアントから渡せる形にすると他人のIDを指定して他人の走行履歴や座標を読み書きできてしまうため。

## エンドポイント一覧

| 機能 | メソッド | パス | 引数 |
|---|---|---|---|
| アカウント作成 | POST | `/api/auth/register` | IDトークン(Authorizationヘッダー) |
| ログイン | POST | `/api/auth/login` | IDトークン(Authorizationヘッダー) |
| トリップ開始 | POST | `/api/trips/start` | (認証のみ) |
| トリップ終了 | POST | `/api/trips/{trip_id}/end` | trip_id(パス) |
| 座標保存 | POST | `/api/locations` | trip_id と lat/lng または points[](ボディ) |
| ログ全件取得 | GET | `/api/trips` | (認証のみ) |
| ログ単体取得 | GET | `/api/trips/{trip_id}` | trip_id(パス) |
| ログ削除(論理削除) | DELETE | `/api/trips/{trip_id}` | trip_id(パス) |
| 到達圏取得 | GET | `/api/maps/isochrone` | lng, lat, minutes(クエリ) |
| 自転車ルート取得 | GET | `/api/maps/route` | fromLng, fromLat, toLng, toLat(クエリ) |
| 周辺スポット検索 | GET | `/api/maps/places` | lng, lat, radius, type(クエリ) |
| スポット提案 | GET | `/api/suggest` | lng, lat, minutes, type, include_visited(クエリ) |
| ユーザー設定取得 | GET | `/api/settings` | (認証のみ) |
| ユーザー設定更新 | PUT | `/api/settings` | 設定オブジェクト(ボディ) |

認証系の想定フロー: フロントでGoogleサインイン(Firebase Auth)→ 初回のみ**アカウント作成**で `users` に登録 → 2回目以降はアプリ起動時に**ログイン**でプロフィールを取得 → 以降のAPIは毎回 IDトークンを `Authorization` ヘッダーに付けて呼び出す。

想定フロー: **トリップ開始**で `trip_id` を取得 → ナビ画面が走行中の座標をためて**座標保存**でまとめて送る → 走行終了時に**トリップ終了**(このタイミングでサーバーが距離・所要時間・平均速度を集計する)→ 履歴画面で**取得**、不要になったら**削除**。

⚠️ 座標を送りきる前に**トリップ終了**を呼ぶと、集計から漏れた分だけ走行距離が短くなる。フロントは終了APIの前に未送信の座標を送りきること。

地図系の想定フロー: 出発前に**スポット提案**(または**到達圏取得**+**周辺スポット検索**)で行き先候補を表示 → 行き先決定後に**自転車ルート取得**で経路を描画。

※ 地図・スポット提案系(5〜8)は仮バージョン。レスポンス形式は今後変更の可能性あり。

---

## 0-1. トリップ開始

新しいトリップ(`trip_history`)を作成し、採番された `trip_id` を返す。`status` は `active`、`start_time` はサーバー受信時刻で登録される。

```
POST /api/trips/start
```

### リクエストボディ

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| destination_name | string | - | 目的地名(省略時は空文字) |
| destination_place_id | string | - | 目的地のGoogle Place ID(省略時は null)。「8. スポット提案」の `places[].id` をそのまま渡す。保存しておくと次回以降の提案からそのスポットが除外される |
| destination_url | string | - | 目的地URL(省略時は null) |

```json
{ "destination_place_id": "ChIJxxxxxxxxxxxxxxxx" }
```

※ どのユーザーのトリップになるかは IDトークンから決まる(`user_id` は送らない)。

### レスポンス(201 Created)

```json
{ "trip_id": 4 }
```

| ステータス | 内容 |
|---|---|
| 201 Created | 作成成功。作成された trip_id を返す |
| 400 Bad Request | destination_place_id が255文字以内の文字列でない |
| 401 Unauthorized | IDトークンが無い/検証に失敗した |
| 404 Not Found | アカウントが未登録 |

---

## 0-2. トリップ終了

トリップの `status` を `active` から `completed` に変更し、`end_time` にサーバー受信時刻を登録する。
あわせて**走行実績(距離・所要時間・平均速度)を集計**して `trip_history` に書き込む。

```
POST /api/trips/{trip_id}/end
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| trip_id | パス | ○ | 終了するトリップID |

リクエストボディ: なし(所有者チェックはIDトークンで行う)

### 走行実績の集計

| 項目 | 算出方法 |
|---|---|
| `duration_sec` | `end_time - start_time`(秒)。**座標ログが無くても必ず入る** |
| `total_distance_m` | `location_log` の連続する2点間の距離(Haversine法)の合計(m、四捨五入) |
| `average_speed_kmh` | `total_distance_m` ÷ `duration_sec` を km/h に換算(小数2桁) |

座標ログが2点未満のトリップは、距離と平均速度を `null` のままにする。0を入れてしまうと
「本当に0km走った」のか「記録できていなかった」のか区別できなくなるため。

### レスポンス(200 OK)

更新後のトリップを返す(集計済みの値が入る)。

```json
{
  "trip_id": 4,
  "user_id": 1,
  "destination_name": "",
  "destination_place_id": null,
  "destination_url": null,
  "start_time": "2026-07-03T02:52:22.000Z",
  "end_time": "2026-07-03T02:52:32.000Z",
  "total_distance_m": 12480,
  "duration_sec": 4800,
  "average_speed_kmh": 9.36,
  "status": "completed",
  "created_at": "2026-07-03T02:52:22.000Z",
  "updated_at": "2026-07-03T02:52:32.000Z"
}
```

| ステータス | 内容 |
|---|---|
| 200 OK | 終了成功。更新後のトリップを返す |
| 400 Bad Request | trip_id 不正 |
| 401 Unauthorized | IDトークンが無い/検証に失敗した |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |
| 409 Conflict | トリップが active でない(すでに completed / cancelled) |

---

## 1. 座標保存

サイクリング中の座標を `location_log` テーブルに保存する。
1点ずつでも、端末側でためた複数点をまとめてでも送れる。**1点ずつ送ると1時間の走行で数百リクエストになるため、まとめ送りを推奨**。

```
POST /api/locations
```

### リクエストボディ

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| trip_id | integer | ○ | 保存先のトリップID |
| lat | number | △ | 緯度(-90〜90)。単発で送る場合は必須 |
| lng | number | △ | 経度(-180〜180)。単発で送る場合は必須 |
| points | array | △ | まとめ送りする座標の配列(1〜500件)。指定時は lat/lng より優先 |

`points[]` の各要素:

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| lat / lng | number | ○ | 座標 |
| recorded_at | string | - | 実際に記録した日時(ISO8601)。省略時はサーバー受信時刻 |
| speed_kmh | number | - | そのときの速度(km/h、0〜999.99) |
| accuracy_m | number | - | 位置精度(m、0〜9999.99) |

単発で送る場合:

```json
{ "trip_id": 1, "lat": 34.6941, "lng": 135.5030 }
```

まとめて送る場合:

```json
{
  "trip_id": 1,
  "points": [
    { "lat": 34.6941, "lng": 135.5030, "recorded_at": "2026-07-03T02:52:30.000Z", "speed_kmh": 18.4, "accuracy_m": 5.2 },
    { "lat": 34.6945, "lng": 135.5036, "recorded_at": "2026-07-03T02:52:35.000Z", "speed_kmh": 19.1, "accuracy_m": 4.8 }
  ]
}
```

### 挙動

- `log_num`(トリップ内の連番)はサーバー側で自動採番する。まとめ送りでも配列の順に1つずつ振る
- `recorded_at` を省略した場合はサーバー受信時刻を保存する
- 範囲外・数値でない `speed_kmh` / `accuracy_m` は `null` として保存する
- ログイン中ユーザーのトリップでない場合・論理削除済みの場合は保存しない
- 1リクエストの上限は500件。超える場合は分割して送る

### レスポンス

| ステータス | 内容 |
|---|---|
| 204 No Content | 保存成功(**戻り値なし**) |
| 400 Bad Request | 引数不正、points が空/501件以上 `{"error": "..."}` |
| 401 Unauthorized | IDトークンが無い/検証に失敗した |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |

---

## 2. ログ全件取得

ログイン中ユーザーのトリップ(走行履歴)一覧を返す。論理削除済みのトリップは含まない。

```
GET /api/trips
```

### 引数

なし(どのユーザーの履歴かは IDトークンから決まる)

### レスポンス(200 OK)

`start_time` の降順の配列。座標ログは含まない(単体取得で返す)。

```json
[
  {
    "trip_id": 1,
    "user_id": 1,
    "destination_name": "大阪城公園",
    "destination_place_id": null,
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
| 401 Unauthorized | IDトークンが無い/検証に失敗した |

---

## 3. ログ単体取得

トリップ1件の詳細と、そのトリップの座標ログ一覧(`log_num` 昇順)を返す。

```
GET /api/trips/{trip_id}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| trip_id | パス | ○ | トリップID |

### レスポンス(200 OK)

```json
{
  "trip_id": 1,
  "user_id": 1,
  "destination_name": "大阪城公園",
  "destination_place_id": null,
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
| 400 Bad Request | trip_id 不正 |
| 401 Unauthorized | IDトークンが無い/検証に失敗した |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |
基本的な利用順は次のとおり。

1. ログインまたはアカウント作成で `user_id` を取得
2. スポット提案で目的地候補を取得
3. ルート取得後、トリップを開始
4. 走行中の座標を保存
5. トリップを終了し、履歴として取得

## 4. ログ削除(論理削除)

トリップを論理削除する。`trip_history.deleted_at` に現在時刻をセットするのみで、レコードは物理削除しない(`location_log` は変更しない)。削除後は取得系APIの結果に含まれなくなる。

```
DELETE /api/trips/{trip_id}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| trip_id | パス | ○ | トリップID |

### レスポンス

| ステータス | 内容 |
|---|---|
| 204 No Content | 削除成功(戻り値なし) |
| 400 Bad Request | trip_id 不正 |
| 401 Unauthorized | IDトークンが無い/検証に失敗した |
| 404 Not Found | トリップが存在しない/他ユーザーのトリップ/削除済み |

---

## 5. 到達圏取得(仮)

指定地点から自転車で `minutes` 分以内に行ける範囲(到達圏)を GeoJSON ポリゴンで返す。Mapbox Isochrone API のレスポンスをそのまま返す。

```
GET /api/maps/isochrone?lng={lng}&lat={lat}&minutes={minutes}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| lng | クエリ | ○ | 中心の経度 |
| lat | クエリ | ○ | 中心の緯度 |
| minutes | クエリ | ○ | 移動可能時間(分)。1以上 |

### 挙動

- `minutes` が60以下: Mapbox の `contours_minutes` をそのまま使用
- `minutes` が60超: 1分=250mで距離に換算し `contours_meters` で近似(上限100km)

### レスポンス(200 OK)

Mapbox Isochrone API の GeoJSON(FeatureCollection)をそのまま返す。

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": { "contour": 15, "color": "#4286f4", ... },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[135.49, 34.70], [135.50, 34.71], ...]]
      }
    }
  ]
}
```

| ステータス | 内容 |
|---|---|
| 200 OK | 到達圏の GeoJSON |
| 400 Bad Request | lng / lat / minutes が数値でない、minutes が1未満 |
| 502 Bad Gateway | Mapbox APIの呼び出しに失敗 `{"error": "Mapbox APIの呼び出しに失敗しました"}` |

---

## 6. 自転車ルート取得(仮)

出発地から目的地までの自転車ルート(経路・距離・所要時間)を返す。Mapbox Directions API(cycling, `geometries=geojson`)のレスポンスをそのまま返す。

```
GET /api/maps/route?fromLng={fromLng}&fromLat={fromLat}&toLng={toLng}&toLat={toLat}
```
## エンドポイント一覧

「接続済み」は現在のFlutterアプリから呼び出しているAPI。

| 機能 | メソッド | パス | Flutter |
|---|---|---|---|
| 稼働確認 | GET | `/` | - |
| アカウント作成 | POST | `/api/auth/register` | 接続済み |
| ログイン | POST | `/api/auth/login` | 接続済み |
| スポット提案 | GET | `/api/suggest` | 接続済み |
| 自転車ルート取得 | GET | `/api/maps/route` | 接続済み |
| スポット写真取得 | GET | `/api/maps/photo` | 接続済み |
| 到達圏取得 | GET | `/api/maps/isochrone` | - |
| 周辺スポット検索 | GET | `/api/maps/places` | - |
| トリップ開始 | POST | `/api/trips/start` | 接続済み |
| トリップ終了 | POST | `/api/trips/{trip_id}/end` | 接続済み |
| 履歴一覧取得 | GET | `/api/trips` | 接続済み |
| 履歴詳細取得 | GET | `/api/trips/{trip_id}` | - |
| 履歴削除 | DELETE | `/api/trips/{trip_id}` | - |
| 座標保存 | POST | `/api/locations` | - |


## 共通のレスポンス形式

### User

認証APIが返すユーザー情報。

| 項目 | 型 | 内容 |
|---|---|---|
| `user_id` | integer | CyChronos内のユーザーID |
| `firebase_uid` | string | FirebaseのUID |
| `email` | string \| null | メールアドレス |
| `display_name` | string \| null | 表示名 |
| `photo_url` | string \| null | プロフィール画像URL |
| `created_at` / `updated_at` | string | 作成・更新日時 |

### Trip

トリップ終了・履歴取得APIが返す走行履歴。

| 項目 | 型 | 内容 |
|---|---|---|
| `trip_id` / `user_id` | integer | トリップID / 所有ユーザーID |
| `destination_name` | string | 目的地名 |
| `destination_place_id` | string \| null | Google Place ID |
| `destination_url` | string \| null | 目的地URL |
| `start_time` / `end_time` | string \| null | 開始・終了日時 |
| `total_distance_m` | number \| null | 総走行距離（m） |
| `duration_sec` | number \| null | 走行時間（秒） |
| `average_speed_kmh` | number \| null | 平均速度（km/h） |
| `status` | string | `active` / `completed` / `cancelled` |
| `created_at` / `updated_at` | string | 作成・更新日時 |

### Place

周辺検索・スポット提案APIが返す施設情報。

| 項目 | 型 | 内容 |
|---|---|---|
| `id` | string | Google Place ID |
| `name` | string | 施設名 |
| `lat` / `lng` | number | 緯度 / 経度 |
| `address` | string | 住所。取得できない場合は空文字 |
| `rating` | number \| null | Googleの評価 |
| `photoReference` | string \| null | 写真取得APIに渡す参照値 |
| `genre` | string \| null | Google Placesの施設種別 |

## 認証

### POST `/api/auth/register`

Firebase IDトークンのユーザーをDBに登録する。
| 入力 | 成功 | 主なエラー |
|---|---|---|
| `Authorization: Bearer <IDトークン>` | `201 User`。論理削除済みアカウントの再有効化は `200 User` | `401` トークンなし・不正、`409` 登録済み |

### POST `/api/auth/login`

登録済みユーザーを取得し、Google側の最新プロフィールをDBへ反映する。

| 入力 | 成功 | 主なエラー |
|---|---|---|
| `Authorization: Bearer <IDトークン>` | `200 User` | `401` トークンなし・不正、`404` 未登録・削除済み |

**IDトークンを付けて呼ぶと**、そのユーザーが過去に訪問したスポットを提案から除外する。未訪問だけで10件に満たない場合は訪問済みから補充する(候補ゼロにはならない)。トークンなしでも呼べるが、その場合は除外なし。

```
GET /api/suggest?lng={lng}&lat={lat}&minutes={minutes}&type={type}
```
## スポット・地図

### GET `/api/suggest`

指定時間に近い所要時間で到達できるスポットを、最大10件ランダムに返す。`minutes` は片道時間として扱い、実際の候補は `minutes ± 10分` の範囲に絞る。

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| lng | クエリ | ○ | 現在地の経度 |
| lat | クエリ | ○ | 現在地の緯度 |
| minutes | クエリ | ○ | 移動可能時間(分)。1以上 |
| type | クエリ | - | 施設の種類(省略時は `cafe`) |

※ 訪問済み除外の対象ユーザーは `Authorization` ヘッダーのIDトークンから決まる(`user_id` クエリは廃止)。
| クエリ | 必須 | 内容 |
|---|---|---|
| `lng` / `lat` | ○ | 現在地の経度 / 緯度 |
| `minutes` | ○ | 希望する片道時間（分、1以上） |
| `type` | - | 施設種別。省略時は `cafe`。`all` は種別指定なし |
| `user_id` | - | 正の整数。指定時は未訪問スポットを優先 |

`user_id` を指定した場合でも、未訪問候補が10件未満なら訪問済み候補で補充する。

```json
{
  "searchArea": {
    "bbox": {
      "minLng": 135.45,
      "maxLng": 135.55,
      "minLat": 34.65,
      "maxLat": 34.74
    },
    "centerLng": 135.5,
    "centerLat": 34.695,
    "radius": 6000,
    "searchPoints": [
      { "lng": 135.48, "lat": 34.7 }
    ]
  },
  "places": [
    {
      "id": "ChIJxxxxxxxx",
      "name": "カフェ○○",
      "lat": 34.6941,
      "lng": 135.503,
      "address": "大阪市中央区…",
      "rating": 4.2,
      "photoReference": "photo-reference",
      "genre": "cafe",
      "durationSec": 1116.1,
      "durationMinutes": 19,
      "distanceM": 3620.5,
      "distanceKm": 3.6
    }
  ]
}
```

- `searchArea.radius` は到達圏を囲む大きさの目安（m、最大50km）。各地点で実際に行うPlaces検索の半径とは異なる
- `durationSec` / `durationMinutes` は自転車での所要時間
- `distanceM` / `distanceKm` は自転車ルート上の距離
- 外部APIまたは所要時間取得に失敗した場合は `502`
- 引数不正は `400`

| ステータス | 内容 |
|---|---|
| 200 OK | 検索範囲と提案スポット一覧 |
| 400 Bad Request | lng / lat / minutes が数値でない、minutes が1未満 |
| 502 Bad Gateway | 外部APIの呼び出しに失敗。`{"error": "Mapbox APIの呼び出しに失敗しました"}` または `{"error": "Google Maps APIの呼び出しに失敗しました"}` |
### GET `/api/maps/route`

Mapboxの自転車ルートをそのまま返す。ルート形状に加え、日本語の曲がり案内も取得する。

| クエリ | 必須 | 内容 |
|---|---|---|
| `fromLng` / `fromLat` | ○ | 出発地の経度 / 緯度 |
| `toLng` / `toLat` | ○ | 目的地の経度 / 緯度 |

成功時は `200`。主に使用する値は `routes[0].geometry`（GeoJSON LineString）、`routes[0].distance`（m）、`routes[0].duration`（秒）、`routes[0].legs[].steps[]`（日本語の案内手順）。引数不正は `400`、Mapbox失敗は `502`。

### GET `/api/maps/photo`

`Place.photoReference` に対応する写真をGoogle Places経由で返す。JSONではなく画像データを返し、`Content-Type` は `image/jpeg` など実画像の形式になる。

| クエリ | 必須 | 内容 |
|---|---|---|
| `photoReference` | ○ | `Place.photoReference` の値 |
| `maxwidth` | ○ | 最大画像幅（px）。Flutterでは `800` を使用 |

`photoReference` 未指定は `400`、Google Places失敗は `502`。

### GET `/api/maps/isochrone`

指定地点から自転車で移動できる範囲をMapboxのGeoJSON FeatureCollectionで返す。

| クエリ | 必須 | 内容 |
|---|---|---|
| `lng` / `lat` | ○ | 中心の経度 / 緯度 |
| `minutes` | ○ | 移動時間（分、1以上） |

`minutes` が60以下なら時間で計算し、60を超える場合は1分250mで距離に換算する（上限100km）。成功は `200`、引数不正は `400`、Mapbox失敗は `502`。

### GET `/api/maps/places`

指定範囲の施設をGoogle Placesで検索し、`Place[]` を返す。

| クエリ | 必須 | 内容 |
|---|---|---|
| `lng` / `lat` | ○ | 中心の経度 / 緯度 |
| `radius` | ○ | 検索半径（m） |
| `type` | - | 施設種別。`all` は種別指定なし |

目的地に向かない生活インフラ・事業所・行政区域などは除外される。該当なしは `[]`。引数不正は `400`、Google Places失敗は `502`。

## トリップ・履歴

### POST `/api/trips/start`

トリップを `active` 状態で作成する。

```json
{
  "user_id": 1,
  "destination_name": "大阪城公園",
  "destination_place_id": "ChIJxxxxxxxx",
  "destination_url": "https://example.com"
}
```

| 項目 | 必須 | 内容 |
|---|---|---|
| `user_id` | ○ | 正の整数 |
| `destination_name` | - | 目的地名。省略時は空文字 |
| `destination_place_id` | - | `Place.id`。255文字以内 |
| `destination_url` | - | 目的地URL |

成功時は `201 {"trip_id": 4}`。引数不正は `400`、ユーザーが存在しない場合は `404`。

### POST `/api/trips/{trip_id}/end`

`active` なトリップを `completed` にし、終了時刻を記録する。

```json
{ "user_id": 1 }
```

成功時は `200 Trip`。引数不正は `400`、該当トリップなし・他ユーザー・削除済みは `404`、すでに終了済みなど `active` でない場合は `409`。

### GET `/api/trips?user_id={user_id}`

指定ユーザーの削除されていない履歴を、開始日時の新しい順で `Trip[]` として返す。該当なしは `[]`。`user_id` 不正は `400`。

### GET `/api/trips/{trip_id}?user_id={user_id}`

`Trip` に、次の `locations` 配列を加えて返す。座標は `log_num` の昇順。

| 項目 | 型 | 内容 |
|---|---|---|
| `log_id` / `log_num` | integer | ログID / トリップ内連番 |
| `lat` / `lng` | number | 緯度 / 経度 |
| `recorded_at` | string | 記録日時 |
| `speed_kmh` | number \| null | 記録時の速度 |
| `accuracy_m` | number \| null | GPS精度 |

成功は `200`、引数不正は `400`、該当トリップなし・他ユーザー・削除済みは `404`。

### DELETE `/api/trips/{trip_id}?user_id={user_id}`

トリップを論理削除する。成功時は `204 No Content`。引数不正は `400`、該当トリップなし・他ユーザー・削除済みは `404`。

## 座標ログ

### POST `/api/locations`

走行中の座標を保存する。`log_num` と記録日時はサーバー側で設定する。

```json
{
  "user_id": 1,
  "trip_id": 4,
  "lat": 34.6941,
  "lng": 135.503
}
```

| 項目 | 必須 | 内容 |
|---|---|---|
| `user_id` / `trip_id` | ○ | 正の整数 |
| `lat` | ○ | 緯度（-90〜90） |
| `lng` | ○ | 経度（-180〜180） |

成功時は `204 No Content`。引数不正は `400`、該当トリップなし・他ユーザー・削除済みは `404`。

## 共通エラー

| ステータス | 発生条件 |
|---|---|
| 401 Unauthorized | 認証が必要なAPIで Authorization ヘッダーが無い、またはIDトークンの検証に失敗した |
| 404 Not Found | 未定義のパスへのアクセス `{"error": "Not Found"}` |
| 500 Internal Server Error | DB接続失敗などサーバー内部エラー `{"error": "Internal Server Error"}` |

## 関連ファイル
エラーは原則として `{"error": "メッセージ"}` のJSONで返す。

| ステータス | 内容 |
|---|---|
| `src/app.js` | Expressアプリ本体・ルーターのマウント |
| `src/routes/auth.js` | アカウント作成・ログインAPI |
| `src/middleware/auth.js` | 認証ミドルウェア(`verifyFirebaseToken` / `requireAppUser` / `optionalAppUser`) |
| `src/services/firebase.js` | firebase-admin 初期化 |
| `src/routes/locations.js` | 座標保存API |
| `src/routes/trips.js` | ログ取得・削除API |
| `src/routes/maps.js` | 地図系API(到達圏・ルート・周辺スポット検索) |
| `src/routes/suggest.js` | スポット提案API |
| `src/services/mapbox.js` | Mapbox API呼び出し(Isochrone / Directions) |
| `src/services/place.js` | Google Places API呼び出し・レスポンス整形 |
| `src/db.js` | MySQL接続プール(接続情報は `.env`) |
| `db/cydump.sql` | DBダンプ(スキーマ+サンプルデータ) |
| `400 Bad Request` | 引数不正 |
| `401 Unauthorized` | Firebase認証失敗 |
| `404 Not Found` | 対象データまたはパスが存在しない |
| `409 Conflict` | 現在の状態では処理できない |
| `500 Internal Server Error` | DB接続失敗などの内部エラー |
| `502 Bad Gateway` | Mapbox / Google Placesの呼び出し失敗 |

# CyChronos API 仕様書

サイクリングナビアプリのバックエンドAPI。走行中の座標ログの保存・取得・削除と、地図・スポット提案(到達圏、自転車ルート、周辺スポット検索)を提供する。

- ベースURL: `http://localhost:3000`(ポートは `.env` の `PORT` で変更可)
- データ形式: リクエスト・レスポンスともに JSON(`Content-Type: application/json`)
- DB: MySQL 8.4 / データベース `cychronos`
- 外部API: Mapbox(`.env` の `MAPBOX_ACCESS_TOKEN`)、Google Places(`.env` の `GOOGLE_PLACES_API_KEY`)
- 認証: Googleアカウント(Firebase Authentication)。フロントでGoogleサインインして取得した **IDトークン** を `Authorization: Bearer <IDトークン>` ヘッダーで送信し、バックエンドが `firebase-admin` で検証する(`.env` の `FIREBASE_PROJECT_ID`)

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
| スポット提案 | GET | `/api/suggest` | lng, lat, minutes, type(クエリ) |

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

---

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

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| fromLng | クエリ | ○ | 出発地の経度 |
| fromLat | クエリ | ○ | 出発地の緯度 |
| toLng | クエリ | ○ | 目的地の経度 |
| toLat | クエリ | ○ | 目的地の緯度 |

### レスポンス(200 OK)

Mapbox Directions API のレスポンスをそのまま返す。主に使うのは `routes[0]` の `geometry`(GeoJSON LineString)・`distance`(m)・`duration`(秒)。

```json
{
  "routes": [
    {
      "geometry": { "type": "LineString", "coordinates": [[135.50, 34.69], ...] },
      "distance": 3521.4,
      "duration": 845.2,
      "legs": [ ... ]
    }
  ],
  "waypoints": [ ... ],
  "code": "Ok"
}
```

| ステータス | 内容 |
|---|---|
| 200 OK | ルート情報 |
| 400 Bad Request | 座標のいずれかが数値でない |
| 502 Bad Gateway | Mapbox APIの呼び出しに失敗 `{"error": "Mapbox APIの呼び出しに失敗しました"}` |

---

## 7. 周辺スポット検索(仮)

中心座標と半径を指定して周辺スポットを検索する。Google Places Nearby Search の結果を、フロントで使いやすい形に整形して返す。

```
GET /api/maps/places?lng={lng}&lat={lat}&radius={radius}&type={type}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| lng | クエリ | ○ | 中心の経度 |
| lat | クエリ | ○ | 中心の緯度 |
| radius | クエリ | ○ | 検索半径(m) |
| type | クエリ | - | 施設の種類(Google Places の type。例: `cafe`, `park`) |

### 挙動

- サイクリングの目的地に向かないカテゴリ(lodging, hotel, parking, gas_station, atm, bank, hospital, doctor, pharmacy, school, university, police, fire_station, post_office, local_government_office)は結果から除外する
- `id` / `name` / 座標が欠けているスポットも除外する

### レスポンス(200 OK)

整形済みスポットの配列。該当なしの場合は空配列 `[]`。

```json
[
  {
    "id": "ChIJxxxxxxxxxxxxxxxx",
    "name": "カフェ○○",
    "lat": 34.6941,
    "lng": 135.5030,
    "address": "大阪市中央区…",
    "rating": 4.2,
    "genre": "cafe"
  }
]
```

| 項目 | 型 | 説明 |
|---|---|---|
| id | string | Google Places の place_id |
| name | string | スポット名 |
| lat / lng | number | 座標 |
| address | string | 住所(取得できない場合は空文字) |
| rating | number \| null | 評価(なければ null) |
| genre | string \| null | 種類(Google Places の types の先頭。なければ null) |

| ステータス | 内容 |
|---|---|
| 200 OK | スポット一覧 |
| 400 Bad Request | lng / lat / radius が数値でない |
| 502 Bad Gateway | Google Maps APIの呼び出しに失敗 `{"error": "Google Maps APIの呼び出しに失敗しました"}` |

---

## 8. スポット提案(仮)

「今いる場所から `minutes` 分で行ける範囲にあるスポット」を提案する。内部で **到達圏取得(Mapbox)** → 到達圏を四角形(bbox)で囲んで検索範囲を算出 → **周辺スポット検索(Google Places)** → **所要時間の一括取得(Mapbox Matrix)** の順に実行する。

各候補には現在地から自転車での所要時間(`durationMinutes`)が付く。所要時間が `minutes` を超える候補・自転車で到達できない候補は除外される(※`minutes` は片道扱い)。

**IDトークンを付けて呼ぶと**、そのユーザーが過去に訪問したスポットを提案から除外する。未訪問だけで10件に満たない場合は訪問済みから補充する(候補ゼロにはならない)。トークンなしでも呼べるが、その場合は除外なし。

```
GET /api/suggest?lng={lng}&lat={lat}&minutes={minutes}&type={type}
```

### 引数

| 項目 | 渡し方 | 必須 | 説明 |
|---|---|---|---|
| lng | クエリ | ○ | 現在地の経度 |
| lat | クエリ | ○ | 現在地の緯度 |
| minutes | クエリ | ○ | 移動可能時間(分)。1以上 |
| type | クエリ | - | 施設の種類(省略時は `cafe`) |

※ 訪問済み除外の対象ユーザーは `Authorization` ヘッダーのIDトークンから決まる(`user_id` クエリは廃止)。

### レスポンス(200 OK)

```json
{
  "searchArea": {
    "bbox": {
      "minLng": 135.45,
      "maxLng": 135.55,
      "minLat": 34.65,
      "maxLat": 34.74
    },
    "centerLng": 135.50,
    "centerLat": 34.695,
    "radius": 6000
  },
  "places": [
    {
      "id": "ChIJxxxxxxxxxxxxxxxx",
      "name": "カフェ○○",
      "lat": 34.6941,
      "lng": 135.5030,
      "address": "大阪市中央区…",
      "rating": 4.2,
      "genre": "cafe",
      "durationSec": 1116.1,
      "durationMinutes": 19,
      "distanceM": 3620.5,
      "distanceKm": 3.6
    }
  ]
}
```

- `searchArea`: 到達圏から算出した検索範囲。`bbox` は到達圏を囲む四角形、`centerLng`/`centerLat` はその中心、`radius` は Places 検索に使った半径(m、上限50km)
- `places`: 「7. 周辺スポット検索」の形式に所要時間を足した配列
- `durationMinutes`: 現在地からそのスポットまで自転車で走った場合の所要時間(分、四捨五入)。**表示にはこちらを使う**。`durationSec` は元の秒数
- `distanceKm`: 現在地からの走行距離(km、小数1桁)。**数値型**なので `6` は「6.0km」の意味(フロントで `toStringAsFixed(1)` 等で整形)。`distanceM` は元のメートル値
- ⚠️ 所要時間の取得(Mapbox Matrix)が失敗した場合も提案自体は返るが、そのときは `durationMinutes` が `null` になり、時間超過の除外も行われない。フロントは `null` のとき「約◯分」表示をスキップすること

| ステータス | 内容 |
|---|---|
| 200 OK | 検索範囲と提案スポット一覧 |
| 400 Bad Request | lng / lat / minutes が数値でない、minutes が1未満 |
| 502 Bad Gateway | 外部APIの呼び出しに失敗。`{"error": "Mapbox APIの呼び出しに失敗しました"}` または `{"error": "Google Maps APIの呼び出しに失敗しました"}` |

---

## 9. アカウント作成(Googleアカウント)

Googleサインイン(Firebase Authentication)で取得したIDトークンを検証し、ユーザーを `users` テーブルに登録する。email・表示名・プロフィール画像はIDトークンのクレームから取得するため、リクエストボディは不要。

論理削除済み(`deleted_at` あり)の同一アカウントが存在する場合は再有効化して返す。

```
POST /api/auth/register
```

### リクエストヘッダー

| 項目 | 必須 | 説明 |
|---|---|---|
| Authorization | ○ | `Bearer <Firebase IDトークン>` |

リクエストボディ: なし

### レスポンス(201 Created)

```json
{
  "user_id": 1,
  "firebase_uid": "AbCdEfGh1234567890",
  "email": "taro@gmail.com",
  "display_name": "山田 太郎",
  "photo_url": "https://lh3.googleusercontent.com/a/xxxx",
  "created_at": "2026-07-07T02:00:00.000Z",
  "updated_at": "2026-07-07T02:00:00.000Z"
}
```

| ステータス | 内容 |
|---|---|
| 201 Created | 登録成功。作成されたユーザー情報を返す |
| 200 OK | 論理削除済みアカウントを再有効化した場合。ユーザー情報を返す |
| 401 Unauthorized | Authorizationヘッダー未指定、またはIDトークンの検証失敗 |
| 409 Conflict | 同じGoogleアカウントで登録済み `{"error": "このアカウントは登録済みです"}` |

---

## 10. ログイン(Googleアカウント)

IDトークンを検証し、登録済みユーザーの情報を返す。あわせてGoogle側の最新プロフィール(email・表示名・画像)を `users` に反映する。未登録の場合は404を返すので、フロントは**アカウント作成**(9)を呼ぶこと。

```
POST /api/auth/login
```

### リクエストヘッダー

| 項目 | 必須 | 説明 |
|---|---|---|
| Authorization | ○ | `Bearer <Firebase IDトークン>` |

リクエストボディ: なし

### レスポンス(200 OK)

```json
{
  "user_id": 1,
  "firebase_uid": "AbCdEfGh1234567890",
  "email": "taro@gmail.com",
  "display_name": "山田 太郎",
  "photo_url": "https://lh3.googleusercontent.com/a/xxxx",
  "created_at": "2026-07-07T02:00:00.000Z",
  "updated_at": "2026-07-07T03:10:00.000Z"
}
```

| ステータス | 内容 |
|---|---|
| 200 OK | 認証成功。ユーザー情報を返す |
| 401 Unauthorized | Authorizationヘッダー未指定、またはIDトークンの検証失敗 |
| 404 Not Found | ユーザー未登録 `{"error": "アカウントが未登録です。先にアカウント作成を行ってください"}` |

---

## 共通エラー

| ステータス | 発生条件 |
|---|---|
| 401 Unauthorized | 認証が必要なAPIで Authorization ヘッダーが無い、またはIDトークンの検証に失敗した |
| 404 Not Found | 未定義のパスへのアクセス `{"error": "Not Found"}` |
| 500 Internal Server Error | DB接続失敗などサーバー内部エラー `{"error": "Internal Server Error"}` |

## 関連ファイル

| ファイル | 内容 |
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

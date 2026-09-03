# CyChronos API 仕様書

## はじめに

認証はフロントでGoogleサインインし、Firebase IDトークンを取得して行う。

基本的な利用順は次のとおり。

1. ログインまたはアカウント作成で `user_id` を取得
2. スポット提案で目的地候補を取得
3. ルート取得後、トリップを開始
4. 走行中の座標を保存
5. トリップを終了し、履歴として取得

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

## スポット・地図

### GET `/api/suggest`

指定時間に近い所要時間で到達できるスポットを、最大10件ランダムに返す。`minutes` は片道時間として扱い、実際の候補は `minutes ± 10分` の範囲に絞る。

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

エラーは原則として `{"error": "メッセージ"}` のJSONで返す。

| ステータス | 内容 |
|---|---|
| `400 Bad Request` | 引数不正 |
| `401 Unauthorized` | Firebase認証失敗 |
| `404 Not Found` | 対象データまたはパスが存在しない |
| `409 Conflict` | 現在の状態では処理できない |
| `500 Internal Server Error` | DB接続失敗などの内部エラー |
| `502 Bad Gateway` | Mapbox / Google Placesの呼び出し失敗 |

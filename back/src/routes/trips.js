const express = require("express");
const pool = require("../db");
const geo = require("../services/geo");

const router = express.Router();

function parseId(value, name, res) {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    res.status(400).json({ error: `${name} は正の整数で指定してください` });
    return null;
  }
  return id;
}

const TRIP_COLUMNS =
  "trip_id, user_id, destination_name, destination_place_id, destination_url, start_time, end_time, " +
  "total_distance_m, duration_sec, average_speed_kmh, status, created_at, updated_at";

// mysql2 は DECIMAL 型を文字列で返す。そのまま返すとフロントの数値判定
// (Dart側の `is num`)を通らず「--」表示になるため、ここで数値に直しておく
function toNumberOrNull(value) {
  if (value === null || value === undefined) return null;
  const num = Number(value);
  return Number.isFinite(num) ? num : null;
}

function normalizeTrip(trip) {
  return {
    ...trip,
    total_distance_m: toNumberOrNull(trip.total_distance_m),
    duration_sec: toNumberOrNull(trip.duration_sec),
    average_speed_kmh: toNumberOrNull(trip.average_speed_kmh),
  };
}

function normalizeLocation(location) {
  return {
    ...location,
    lat: toNumberOrNull(location.lat),
    lng: toNumberOrNull(location.lng),
    speed_kmh: toNumberOrNull(location.speed_kmh),
    accuracy_m: toNumberOrNull(location.accuracy_m),
  };
}

// 走行実績(距離・所要時間・平均速度)を集計して trip_history に書き戻す。
//
// 所要時間は start_time / end_time から必ず出せるが、距離と平均速度は座標ログが
// 2点以上ないと出せない。ログが無いトリップに 0km を入れると「本当に0km走った」のか
// 「記録できていない」のか区別がつかなくなるため、その場合は NULL のままにする
async function summarizeTrip(tripId) {
  const [[trip]] = await pool.query(
    "SELECT TIMESTAMPDIFF(SECOND, start_time, end_time) AS durationSec FROM trip_history WHERE trip_id = ?",
    [tripId]
  );

  // 時計のずれ等で負になったら0に丸める(duration_sec は int unsigned)
  const durationSec = Math.max(0, Math.round(Number(trip?.durationSec ?? 0)));

  const [rows] = await pool.query(
    "SELECT lat, lng FROM location_log WHERE trip_id = ? ORDER BY log_num",
    [tripId]
  );

  const points = rows
    .map((row) => ({ lat: Number(row.lat), lng: Number(row.lng) }))
    .filter((point) => Number.isFinite(point.lat) && Number.isFinite(point.lng));

  if (points.length < 2) {
    await pool.query("UPDATE trip_history SET duration_sec = ? WHERE trip_id = ?", [
      durationSec,
      tripId,
    ]);
    return;
  }

  const totalDistanceM = geo.totalDistanceMeters(points);

  // 平均速度は decimal(5,2) なので上限999.99。0秒割りを避けつつ、
  // 異常値でカラム定義を超えないように丸めてから収める
  let averageSpeedKmh = null;
  if (durationSec > 0) {
    const raw = totalDistanceM / 1000 / (durationSec / 3600);
    averageSpeedKmh = Math.min(Math.round(raw * 100) / 100, 999.99);
  }

  await pool.query(
    "UPDATE trip_history SET total_distance_m = ?, duration_sec = ?, average_speed_kmh = ? WHERE trip_id = ?",
    [Math.round(totalDistanceM), durationSec, averageSpeedKmh, tripId]
  );
}

// トリップ開始: 新しい trip_history を作成し trip_id を返す
// 引数: destination_place_id(省略可)。user_id は認証トークンから引く
router.post("/start", async (req, res) => {
  const body = req.body ?? {};
  const userId = req.appUser.user_id;

  // 目的地のGoogle Place ID(/api/suggest の places[].id)。訪問済み除外に使うので、あれば保存する
  const destinationPlaceId = body.destination_place_id ?? null;
  if (destinationPlaceId !== null && (typeof destinationPlaceId !== "string" || destinationPlaceId.length > 255)) {
    return res.status(400).json({ error: "destination_place_id は255文字以内の文字列で指定してください" });
  }

  const [result] = await pool.query(
    "INSERT INTO trip_history (user_id, destination_name, destination_place_id, destination_url, start_time, status) " +
      "VALUES (?, ?, ?, ?, NOW(), 'active')",
    [userId, body.destination_name ?? "", destinationPlaceId, body.destination_url ?? null]
  );

  res.status(201).json({ trip_id: result.insertId });
});

// トリップ終了: status を completed にし、end_time を登録したうえで走行実績を集計する
// 引数: trip_id。user_id は認証トークンから引く
router.post("/:tripId/end", async (req, res) => {
  const userId = req.appUser.user_id;
  const tripId = parseId(req.params.tripId, "trip_id", res);
  if (tripId === null) return;

  const [result] = await pool.query(
    "UPDATE trip_history SET status = 'completed', end_time = NOW() " +
      "WHERE trip_id = ? AND user_id = ? AND status = 'active' AND deleted_at IS NULL",
    [tripId, userId]
  );

  if (result.affectedRows === 0) {
    const [trips] = await pool.query(
      "SELECT status FROM trip_history WHERE trip_id = ? AND user_id = ? AND deleted_at IS NULL",
      [tripId, userId]
    );
    if (trips.length === 0) {
      return res.status(404).json({ error: "指定されたトリップが存在しません" });
    }
    return res.status(409).json({ error: `トリップは active ではありません(現在: ${trips[0].status})` });
  }

  // 座標ログから距離・所要時間・平均速度を確定させる(履歴画面はこの値を表示する)
  await summarizeTrip(tripId);

  const [trips] = await pool.query(
    `SELECT ${TRIP_COLUMNS} FROM trip_history WHERE trip_id = ?`,
    [tripId]
  );
  res.json(normalizeTrip(trips[0]));
});

// ログ全件取得: ログイン中ユーザーのトリップ一覧(論理削除済みは除外)
router.get("/", async (req, res) => {
  const userId = req.appUser.user_id;

  const [trips] = await pool.query(
    `SELECT ${TRIP_COLUMNS} FROM trip_history WHERE user_id = ? AND deleted_at IS NULL ORDER BY start_time DESC`,
    [userId]
  );
  res.json(trips.map(normalizeTrip));
});

// ログ単体取得: トリップ詳細+座標ログ一覧
// 引数: trip_id。user_id は認証トークンから引く
router.get("/:tripId", async (req, res) => {
  const userId = req.appUser.user_id;
  const tripId = parseId(req.params.tripId, "trip_id", res);
  if (tripId === null) return;

  const [trips] = await pool.query(
    `SELECT ${TRIP_COLUMNS} FROM trip_history WHERE trip_id = ? AND user_id = ? AND deleted_at IS NULL`,
    [tripId, userId]
  );
  if (trips.length === 0) {
    return res.status(404).json({ error: "指定されたトリップが存在しません" });
  }

  const [locations] = await pool.query(
    "SELECT log_id, log_num, lat, lng, recorded_at, speed_kmh, accuracy_m " +
      "FROM location_log WHERE trip_id = ? ORDER BY log_num",
    [tripId]
  );

  res.json({ ...normalizeTrip(trips[0]), locations: locations.map(normalizeLocation) });
});

// ログ削除: 論理削除(trip_history の deleted_at をセット)
// 引数: trip_id。user_id は認証トークンから引く
router.delete("/:tripId", async (req, res) => {
  const userId = req.appUser.user_id;
  const tripId = parseId(req.params.tripId, "trip_id", res);
  if (tripId === null) return;

  const [result] = await pool.query(
    "UPDATE trip_history SET deleted_at = NOW() WHERE trip_id = ? AND user_id = ? AND deleted_at IS NULL",
    [tripId, userId]
  );
  if (result.affectedRows === 0) {
    return res.status(404).json({ error: "指定されたトリップが存在しません" });
  }

  res.status(204).end();
});

module.exports = router;

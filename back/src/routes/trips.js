const express = require("express");
const pool = require("../db");

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

// トリップ開始: 新しい trip_history を作成し trip_id を返す
// 引数: user_id, destination_place_id(省略可)
router.post("/start", async (req, res) => {
  const body = req.body ?? {};
  const userId = parseId(body.user_id, "user_id", res);
  if (userId === null) return;

  // 目的地のGoogle Place ID(/api/suggest の places[].id)。訪問済み除外に使うので、あれば保存する
  const destinationPlaceId = body.destination_place_id ?? null;
  if (destinationPlaceId !== null && (typeof destinationPlaceId !== "string" || destinationPlaceId.length > 255)) {
    return res.status(400).json({ error: "destination_place_id は255文字以内の文字列で指定してください" });
  }

  const [users] = await pool.query(
    "SELECT user_id FROM users WHERE user_id = ? AND deleted_at IS NULL",
    [userId]
  );
  if (users.length === 0) {
    return res.status(404).json({ error: "指定されたユーザーが存在しません" });
  }

  const [result] = await pool.query(
    "INSERT INTO trip_history (user_id, destination_name, destination_place_id, destination_url, start_time, status) " +
      "VALUES (?, ?, ?, ?, NOW(), 'active')",
    [userId, body.destination_name ?? "", destinationPlaceId, body.destination_url ?? null]
  );

  res.status(201).json({ trip_id: result.insertId });
});

// トリップ終了: status を active から completed に変更し end_time に現在時刻を登録
// 引数: user_id, trip_id, total_distance_m(任意), duration_sec(任意), average_speed_kmh(任意)
router.post("/:tripId/end", async (req, res) => {
  const body = req.body ?? {};
  const userId = parseId(body.user_id, "user_id", res);
  if (userId === null) return;
  const tripId = parseId(req.params.tripId, "trip_id", res);
  if (tripId === null) return;

  const totalDistanceM =
    body.total_distance_m != null && Number.isFinite(Number(body.total_distance_m))
      ? Math.max(0, Math.round(Number(body.total_distance_m)))
      : null;
  const durationSec =
    body.duration_sec != null && Number.isFinite(Number(body.duration_sec))
      ? Math.max(0, Math.round(Number(body.duration_sec)))
      : null;
  const averageSpeedKmh =
    body.average_speed_kmh != null && Number.isFinite(Number(body.average_speed_kmh))
      ? Math.max(0, Number(Number(body.average_speed_kmh).toFixed(2)))
      : null;

  const [result] = await pool.query(
    "UPDATE trip_history SET status = 'completed', end_time = NOW(), " +
      "total_distance_m = COALESCE(?, total_distance_m), " +
      "duration_sec = COALESCE(?, duration_sec), " +
      "average_speed_kmh = COALESCE(?, average_speed_kmh) " +
      "WHERE trip_id = ? AND user_id = ? AND status = 'active' AND deleted_at IS NULL",
    [totalDistanceM, durationSec, averageSpeedKmh, tripId, userId]
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

  const [trips] = await pool.query(
    `SELECT ${TRIP_COLUMNS} FROM trip_history WHERE trip_id = ?`,
    [tripId]
  );
  res.json(trips[0]);
});

// ログ全件取得: 指定ユーザーのトリップ一覧(論理削除済みは除外)
// 引数: user_id
router.get("/", async (req, res) => {
  const userId = parseId(req.query.user_id, "user_id", res);
  if (userId === null) return;

  const [trips] = await pool.query(
    `SELECT ${TRIP_COLUMNS} FROM trip_history WHERE user_id = ? AND deleted_at IS NULL ORDER BY start_time DESC`,
    [userId]
  );
  res.json(trips);
});

// ログ単体取得: トリップ詳細+座標ログ一覧
// 引数: user_id, trip_id
router.get("/:tripId", async (req, res) => {
  const userId = parseId(req.query.user_id, "user_id", res);
  if (userId === null) return;
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

  res.json({ ...trips[0], locations });
});

// ログ削除: 論理削除(trip_history の deleted_at をセット)
// 引数: user_id, trip_id
router.delete("/:tripId", async (req, res) => {
  const userId = parseId(req.query.user_id, "user_id", res);
  if (userId === null) return;
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

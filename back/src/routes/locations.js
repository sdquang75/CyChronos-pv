const express = require("express");
const pool = require("../db");

const router = express.Router();

// 座標保存: ナビ画面から一定間隔で送信される座標を保存する(戻り値なし)
// 引数: user_id, trip_id, lat, lng
router.post("/", async (req, res) => {
  const body = req.body ?? {};
  const userId = Number(body.user_id);
  const tripId = Number(body.trip_id);
  const lat = Number(body.lat);
  const lng = Number(body.lng);

  if (!Number.isInteger(userId) || userId <= 0) {
    return res.status(400).json({ error: "user_id は正の整数で指定してください" });
  }
  if (!Number.isInteger(tripId) || tripId <= 0) {
    return res.status(400).json({ error: "trip_id は正の整数で指定してください" });
  }
  if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
    return res.status(400).json({ error: "lat は -90〜90 の数値で指定してください" });
  }
  if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
    return res.status(400).json({ error: "lng は -180〜180 の数値で指定してください" });
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [trips] = await conn.query(
      "SELECT trip_id FROM trip_history WHERE trip_id = ? AND user_id = ? AND deleted_at IS NULL FOR UPDATE",
      [tripId, userId]
    );
    if (trips.length === 0) {
      await conn.rollback();
      return res.status(404).json({ error: "指定されたトリップが存在しません" });
    }

    const [[{ nextNum }]] = await conn.query(
      "SELECT COALESCE(MAX(log_num), 0) + 1 AS nextNum FROM location_log WHERE trip_id = ?",
      [tripId]
    );

    await conn.query(
      "INSERT INTO location_log (trip_id, log_num, lat, lng, recorded_at) VALUES (?, ?, ?, ?, NOW())",
      [tripId, nextNum, lat, lng]
    );

    await conn.commit();
    res.status(204).end();
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
});

module.exports = router;

const express = require("express");
const pool = require("../db");

const router = express.Router();

// 1リクエストで受け取れる座標の上限。
// 端末が長時間オフラインだった後のまとめ送りが巨大になりすぎるのを防ぐ
const MAX_POINTS_PER_REQUEST = 500;

// decimal カラムに収まる範囲に丸める(範囲外・数値でないものは null にして記録しない)
function clampDecimal(value, max) {
  const num = Number(value);
  if (!Number.isFinite(num) || num < 0 || num > max) return null;
  return Math.round(num * 100) / 100;
}

// ボディを座標の配列に正規化する。
// 単発 { lat, lng } と まとめ送り { points: [...] } の両方を受け付ける
// (走行中は数十点をまとめて送れるようにして、リクエスト数を抑えられるようにしている)
function normalizePoints(body) {
  const raw = Array.isArray(body.points) ? body.points : [body];

  if (raw.length === 0) {
    return { error: "points が空です" };
  }
  if (raw.length > MAX_POINTS_PER_REQUEST) {
    return { error: `points は一度に${MAX_POINTS_PER_REQUEST}件までです` };
  }

  const points = [];
  for (const item of raw) {
    const lat = Number((item ?? {}).lat);
    const lng = Number((item ?? {}).lng);

    if (!Number.isFinite(lat) || lat < -90 || lat > 90) {
      return { error: "lat は -90〜90 の数値で指定してください" };
    }
    if (!Number.isFinite(lng) || lng < -180 || lng > 180) {
      return { error: "lng は -180〜180 の数値で指定してください" };
    }

    // 端末側でバッファしてから送る場合、実際に記録した時刻を渡してもらう。
    // 無効・未指定ならサーバー受信時刻を使う(mysql2 が Date をサーバーのタイムゾーンで保存するので
    // NOW() で入れた既存行と揃う)
    const recordedAt = new Date((item ?? {}).recorded_at ?? NaN);

    points.push({
      lat,
      lng,
      speedKmh: clampDecimal((item ?? {}).speed_kmh, 999.99),
      accuracyM: clampDecimal((item ?? {}).accuracy_m, 9999.99),
      recordedAt: Number.isNaN(recordedAt.getTime()) ? null : recordedAt,
    });
  }

  return { points };
}

// 座標保存: ナビ画面から送信される座標を保存する(戻り値なし)
// 引数: trip_id と、lat/lng または points[]。user_id は認証トークンから引く
router.post("/", async (req, res) => {
  const body = req.body ?? {};
  const userId = req.appUser.user_id;
  const tripId = Number(body.trip_id);

  if (!Number.isInteger(tripId) || tripId <= 0) {
    return res.status(400).json({ error: "trip_id は正の整数で指定してください" });
  }

  const normalized = normalizePoints(body);
  if (normalized.error) {
    return res.status(400).json({ error: normalized.error });
  }
  const { points } = normalized;

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

    // log_num は連番。まとめ送りでも1件ずつ採番して (trip_id, log_num) の一意制約を守る
    const values = points.map((point, index) => [
      tripId,
      nextNum + index,
      point.lat,
      point.lng,
      point.recordedAt ?? new Date(),
      point.speedKmh,
      point.accuracyM,
    ]);

    await conn.query(
      "INSERT INTO location_log (trip_id, log_num, lat, lng, recorded_at, speed_kmh, accuracy_m) VALUES ?",
      [values]
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

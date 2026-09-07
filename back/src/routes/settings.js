const express = require("express");
const pool = require("../db");

const router = express.Router();

function normalizeSettings(row) {
  if (!row) return null;
  return {
    user_id: row.user_id,
    include_visited_places: Boolean(row.include_visited_places),
    voice_guidance_enabled: Boolean(row.voice_guidance_enabled),
    keep_screen_awake: Boolean(row.keep_screen_awake),
    auto_reroute_enabled: Boolean(row.auto_reroute_enabled),
    map_type: row.map_type || "normal",
    updated_at: row.updated_at,
  };
}

// ユーザー設定の取得: 未作成なら初期値を登録して返す
router.get("/", async (req, res) => {
  const userId = req.appUser.user_id;

  const [rows] = await pool.query(
    "SELECT * FROM user_settings WHERE user_id = ?",
    [userId]
  );

  if (rows.length > 0) {
    return res.json(normalizeSettings(rows[0]));
  }

  // 初期値で登録
  await pool.query(
    "INSERT INTO user_settings (user_id) VALUES (?)",
    [userId]
  );

  const [created] = await pool.query(
    "SELECT * FROM user_settings WHERE user_id = ?",
    [userId]
  );
  res.json(normalizeSettings(created[0]));
});

// ユーザー設定の更新: 指定されたフィールドのみ更新
router.put("/", async (req, res) => {
  const userId = req.appUser.user_id;
  const body = req.body ?? {};

  const fields = [];
  const values = [];

  if (body.include_visited_places !== undefined) {
    fields.push("include_visited_places = ?");
    values.push(body.include_visited_places ? 1 : 0);
  }
  if (body.voice_guidance_enabled !== undefined) {
    fields.push("voice_guidance_enabled = ?");
    values.push(body.voice_guidance_enabled ? 1 : 0);
  }
  if (body.keep_screen_awake !== undefined) {
    fields.push("keep_screen_awake = ?");
    values.push(body.keep_screen_awake ? 1 : 0);
  }
  if (body.auto_reroute_enabled !== undefined) {
    fields.push("auto_reroute_enabled = ?");
    values.push(body.auto_reroute_enabled ? 1 : 0);
  }
  if (body.map_type !== undefined) {
    const validMapTypes = ["normal", "satellite", "terrain"];
    const mapType = validMapTypes.includes(body.map_type) ? body.map_type : "normal";
    fields.push("map_type = ?");
    values.push(mapType);
  }

  // レコードが存在しなければ初期作成
  const [existing] = await pool.query(
    "SELECT user_id FROM user_settings WHERE user_id = ?",
    [userId]
  );
  if (existing.length === 0) {
    await pool.query(
      "INSERT INTO user_settings (user_id) VALUES (?)",
      [userId]
    );
  }

  if (fields.length > 0) {
    values.push(userId);
    await pool.query(
      `UPDATE user_settings SET ${fields.join(", ")} WHERE user_id = ?`,
      values
    );
  }

  const [updated] = await pool.query(
    "SELECT * FROM user_settings WHERE user_id = ?",
    [userId]
  );
  res.json(normalizeSettings(updated[0]));
});

module.exports = router;

const express = require("express");
const pool = require("../db");
const { verifyFirebaseToken } = require("../middleware/auth");

const router = express.Router();

const USER_COLUMNS =
  "user_id, firebase_uid, email, display_name, photo_url, created_at, updated_at";

async function findUserById(userId) {
  const [users] = await pool.query(
    `SELECT ${USER_COLUMNS} FROM users WHERE user_id = ?`,
    [userId]
  );
  return users[0];
}

// アカウント作成: Googleサインインで取得した IDトークンを検証し users に登録
// 引数: Authorization ヘッダー(Bearer <IDトークン>)のみ。プロフィールはトークンから取得
router.post("/register", verifyFirebaseToken, async (req, res) => {
  const { uid, email, name, picture } = req.firebaseUser;

  const [existing] = await pool.query(
    "SELECT user_id, deleted_at FROM users WHERE firebase_uid = ?",
    [uid]
  );

  if (existing.length > 0) {
    if (existing[0].deleted_at === null) {
      return res.status(409).json({ error: "このアカウントは登録済みです" });
    }
    // 論理削除済みアカウントは再有効化して返す
    await pool.query(
      "UPDATE users SET email = ?, display_name = ?, photo_url = ?, deleted_at = NULL WHERE user_id = ?",
      [email ?? null, name ?? null, picture ?? null, existing[0].user_id]
    );
    return res.json(await findUserById(existing[0].user_id));
  }

  const [result] = await pool.query(
    "INSERT INTO users (firebase_uid, email, display_name, photo_url) VALUES (?, ?, ?, ?)",
    [uid, email ?? null, name ?? null, picture ?? null]
  );
  res.status(201).json(await findUserById(result.insertId));
});

// ログイン: IDトークンを検証し、登録済みユーザー情報を返す
// Google側の最新プロフィール(email, 表示名, 画像)を users に反映する
router.post("/login", verifyFirebaseToken, async (req, res) => {
  const { uid, email, name, picture } = req.firebaseUser;

  const [users] = await pool.query(
    "SELECT user_id FROM users WHERE firebase_uid = ? AND deleted_at IS NULL",
    [uid]
  );
  if (users.length === 0) {
    return res
      .status(404)
      .json({ error: "アカウントが未登録です。先にアカウント作成を行ってください" });
  }

  await pool.query(
    "UPDATE users SET email = ?, display_name = ?, photo_url = ? WHERE user_id = ?",
    [email ?? null, name ?? null, picture ?? null, users[0].user_id]
  );
  res.json(await findUserById(users[0].user_id));
});

module.exports = router;

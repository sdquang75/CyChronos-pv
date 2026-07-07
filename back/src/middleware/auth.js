const admin = require("../services/firebase");

// Authorization: Bearer <Firebase IDトークン> を検証し、
// デコード結果(uid, email, name, picture など)を req.firebaseUser に格納する
async function verifyFirebaseToken(req, res, next) {
  const header = req.headers.authorization ?? "";
  const match = header.match(/^Bearer (.+)$/);
  if (!match) {
    return res
      .status(401)
      .json({ error: "Authorization ヘッダーに Bearer トークンを指定してください" });
  }

  try {
    req.firebaseUser = await admin.auth().verifyIdToken(match[1]);
  } catch (err) {
    return res.status(401).json({ error: "IDトークンの検証に失敗しました" });
  }

  next();
}

module.exports = verifyFirebaseToken;

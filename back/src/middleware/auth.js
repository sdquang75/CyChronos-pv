const admin = require("../services/firebase");
const pool = require("../db");

// Authorization: Bearer <トークン> からトークン部分だけを取り出す(無ければ null)
function extractBearerToken(req) {
  const header = req.headers.authorization ?? "";
  const match = header.match(/^Bearer (.+)$/);
  return match ? match[1] : null;
}

// firebase_uid から users の行を引く(未登録・論理削除済みは null)
async function findAppUserByUid(uid) {
  const [users] = await pool.query(
    "SELECT user_id FROM users WHERE firebase_uid = ? AND deleted_at IS NULL",
    [uid]
  );
  return users[0] ?? null;
}

// IDトークンを検証し、デコード結果(uid, email, name, picture など)を req.firebaseUser に格納する。
// users 未登録でも通るので、アカウント作成(POST /api/auth/register)で使う
async function verifyFirebaseToken(req, res, next) {
  const token = extractBearerToken(req);
  if (!token) {
    return res
      .status(401)
      .json({ error: "Authorization ヘッダーに Bearer トークンを指定してください" });
  }

  try {
    req.firebaseUser = await admin.auth().verifyIdToken(token);
  } catch (err) {
    return res.status(401).json({ error: "IDトークンの検証に失敗しました" });
  }

  next();
}

// 認証必須。IDトークンを検証したうえで users の行まで引き、req.appUser に格納する。
//
// これを通したルートでは、クエリやボディの user_id を認可に使ってはいけない。
// user_id は連番なので、クライアントが他人のIDを書けば他人のデータを読み書きできてしまう。
// 「誰のリクエストか」は req.appUser.user_id(= 検証済みトークン由来)だけを信用する
async function requireAppUser(req, res, next) {
  const token = extractBearerToken(req);
  if (!token) {
    return res
      .status(401)
      .json({ error: "Authorization ヘッダーに Bearer トークンを指定してください" });
  }

  try {
    req.firebaseUser = await admin.auth().verifyIdToken(token);
  } catch (err) {
    return res.status(401).json({ error: "IDトークンの検証に失敗しました" });
  }

  const appUser = await findAppUserByUid(req.firebaseUser.uid);
  if (!appUser) {
    return res
      .status(404)
      .json({ error: "アカウントが未登録です。先にアカウント作成を行ってください" });
  }

  req.appUser = appUser;
  next();
}

// 認証は任意。トークンがあれば req.appUser を入れ、無い・無効なときは null のまま通す。
// スポット提案のように「ログインしていれば訪問済みを除外する」程度の用途で使う
async function optionalAppUser(req, res, next) {
  req.appUser = null;

  const token = extractBearerToken(req);
  if (token) {
    try {
      req.firebaseUser = await admin.auth().verifyIdToken(token);
      req.appUser = await findAppUserByUid(req.firebaseUser.uid);
    } catch (err) {
      // 無効なトークンでも提案自体は返す(訪問済み除外が効かないだけ)
      req.appUser = null;
    }
  }

  next();
}

module.exports = { verifyFirebaseToken, requireAppUser, optionalAppUser };

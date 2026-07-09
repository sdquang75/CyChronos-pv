// 訪問済みスポットの取得係。提案(/api/suggest)から「もう行った場所」を除外するために使う

const pool = require("../db");

// 指定ユーザーが過去に訪問した目的地の place_id 一覧を返す(重複なし)
// ※将来Firestoreへ移行する場合も、この関数の中身だけ差し替えれば呼び出し側は変更不要
async function getVisitedPlaceIds(userId) {
  // 論理削除済みトリップは「行っていない」扱い。place_id未記録(NULL)の古いトリップは対象外
  const [rows] = await pool.query(
    "SELECT DISTINCT destination_place_id FROM trip_history " +
      "WHERE user_id = ? AND destination_place_id IS NOT NULL AND deleted_at IS NULL",
    [userId]
  );
  return rows.map((row) => row.destination_place_id);
}

module.exports = { getVisitedPlaceIds };

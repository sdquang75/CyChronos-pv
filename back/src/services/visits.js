// 訪問済みスポットの取得係。提案(/api/suggest)から「もう行った場所」を除外するために使う

// ⚠️ 仮実装: DB設計の確定待ち(最終的にはFirestore予定)。確定したらこの関数の中身だけ差し替える。
// 呼び出し側(routes/suggest.js)は「place_idの配列が返る」ことしか知らないので変更不要。
async function getVisitedPlaceIds(userId) {
  // 動作確認したいときは、/api/suggest を一度叩いて返ってきた places[].id をここに貼る
  // (2026-07-09 に東京駅×cafe の10件を貼って、除外されることを確認済み)
  const stubVisitedPlaceIds = [];

  return stubVisitedPlaceIds;
}

module.exports = { getVisitedPlaceIds };

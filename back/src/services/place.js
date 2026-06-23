//スポットだすやつにょー

const BASE_URL = "https://maps.googleapis.com"; // Google Maps APIのベースURL   

/**
 * 指定範囲からいけそうなスポットを取得する
 * @param {number} radius 半径(m)
 * @param {string} type スポットの種類
 * @param {number} lng 経度
 * @param {number} lat 緯度
 */
async function getNearbyPlaces(lng, lat, radius, type) {

    // .env に置いた Google Places のAPIキーを読み込む
    const token = process.env.GOOGLE_PLACES_API_KEY;

    // Nearby Search のURLを組み立てる。location は「緯度,経度」の順（Mapboxと逆なので注意）
    const url = new URL(`${BASE_URL}/maps/api/place/nearbysearch/json`);
    url.searchParams.set("location", `${lat},${lng}`); // 検索の中心座標
    url.searchParams.set("radius", radius);            // 検索半径(m)
    url.searchParams.set("type", type);                // 施設の種類(例: cafe)
    url.searchParams.set("key", token);                // APIキー

    // Google に問い合わせ。HTTP自体が失敗ならthrow
    // ※注意: キー不正などでも 200 が返ることがあり、本当の成否は data.status に入る
    const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Google Maps API error: ${response.status} ${response.statusText}`);
  }
  const data = await response.json();
  return data;
}

module.exports = { getNearbyPlaces };
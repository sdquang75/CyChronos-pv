// Mapbox API を呼ぶ処理をここに集める。
// ルーター(routes/)からは「関数を呼ぶだけ」にする

const BASE_URL = "https://api.mapbox.com";

/**
 * 指定地点から自転車で minutes 分以内に行ける範囲(GeoJSONポリゴン)を取得する
 * @param {number} lng 経度
 * @param {number} lat 緯度
 * @param {number} minutes 移動可能時間(分)
 */

async function getIsochrone(lng, lat, minutes) {

  const token = process.env.MAPBOX_ACCESS_TOKEN;

  const url = new URL(`${BASE_URL}/isochrone/v1/mapbox/cycling/${lng},${lat}`);
  // 1未満はルーター側で弾いている前提（contours_minutes の有効範囲は1〜60）
  if (minutes <= 60) {
    url.searchParams.set("contours_minutes", minutes);      
  } else {
    // 60分を超えるときは距離で近似する
    let metre = minutes * 250; // 1分250mで換算

    if (metre > 100000) {
      metre = 100000; // 最大100kmまで
    }
    url.searchParams.set("contours_meters", metre);
  }
  url.searchParams.set("polygons", true);
  url.searchParams.set("access_token", token);

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Mapbox API error: ${response.status} ${response.statusText}`);
  }
  const data = await response.json();
  return data;
}

/**
 * 2地点間の自転車ルート(経路・距離・所要時間)を取得する
 * @param {{lng: number, lat: number}} from 出発地
 * @param {{lng: number, lat: number}} to 目的地
 */
async function getCyclingRoute(from, to) {

  const token = process.env.MAPBOX_ACCESS_TOKEN;

  const url = new URL(`${BASE_URL}/directions/v5/mapbox/cycling/${from.lng},${from.lat};${to.lng},${to.lat}`);
  url.searchParams.set("geometries", "geojson");
  url.searchParams.set("access_token", token);

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Mapbox API error: ${response.status} ${response.statusText}`);
  }
  const data = await response.json();
  return data;
}

/**
 * 目的地までの移動時間を取得する
 * @param {{lng: number, lat: number}} from 出発地
 * @param {Array<{lng: number, lat: number}>} destinations 目的地の配列
 */
async function getTravelTimes(from, destinations) {
  const token = process.env.MAPBOX_ACCESS_TOKEN;

  const coords = [from, ...destinations].map((point) => `${point.lng},${point.lat}`).join(";");
  const url = new URL(`${BASE_URL}/directions-matrix/v1/mapbox/cycling/${coords}`);
  url.searchParams.set("access_token", token);
  url.searchParams.set("sources", "0");
  url.searchParams.set("annotations", "duration");

  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Mapbox API error: ${response.status} ${response.statusText}`);
  }
  const data = await response.json();
  const durations = data.durations?.[0];
  if (!Array.isArray(durations)) {
    throw new Error("Mapbox API error: durations が取得できませんでした");
  }

  // durations[0] の先頭は「出発地→出発地」の0秒なので取り除く。
  // これで戻り値のインデックスが destinations と1対1で揃う
  const destinationDurations = durations.slice(1);
  if (destinationDurations.length !== destinations.length) {
    throw new Error("Mapbox API error: durations の件数が目的地の数と一致しません");
  }
  return destinationDurations;
}

module.exports = { getIsochrone, getCyclingRoute, getTravelTimes };

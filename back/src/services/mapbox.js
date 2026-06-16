// Mapbox API を呼ぶ処理をここに集める。
// ルーター(routes/)からは「関数を呼ぶだけ」にして、URL組み立てやfetchはこの層に閉じ込める。

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
  url.searchParams.set("contours_minutes", minutes);
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

module.exports = { getIsochrone, getCyclingRoute };

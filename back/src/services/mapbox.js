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
  // TODO: Isochrone API を fetch して結果の JSON を return する
  // エンドポイント: /isochrone/v1/mapbox/cycling/{lng},{lat}
  // クエリ: contours_minutes, polygons=true, access_token
}

/**
 * 2地点間の自転車ルート(経路・距離・所要時間)を取得する
 * @param {{lng: number, lat: number}} from 出発地
 * @param {{lng: number, lat: number}} to 目的地
 */
async function getCyclingRoute(from, to) {
  // TODO: Directions API を fetch して結果の JSON を return する
  // エンドポイント: /directions/v5/mapbox/cycling/{lng},{lat};{lng},{lat}
  // クエリ: geometries=geojson, access_token
}

module.exports = { getIsochrone, getCyclingRoute };

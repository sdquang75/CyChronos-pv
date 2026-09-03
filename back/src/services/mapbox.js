// Mapbox API を呼ぶ処理をここに集める。
// ルーター(routes/)からは「関数を呼ぶだけ」にする

const BASE_URL = "https://api.mapbox.com";
// Matrix APIは出発地を含めて最大25座標なので、1回に渡せる目的地は24件。
const MAX_MATRIX_DESTINATIONS = 24;

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
  url.searchParams.set("overview", "full");
  // 端末側で曲がり案内を組み立てられるよう、日本語の案内手順も同時に取得する。
  url.searchParams.set("steps", "true");
  url.searchParams.set("language", "ja");
  url.searchParams.set("roundabout_exits", "true");
  url.searchParams.set("access_token", token);

  // 案内開始を待たせ続けないよう、外部APIが応答しなければ10秒で失敗させる。
  const response = await fetch(url, { signal: AbortSignal.timeout(10000) });
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
async function getTravelTimesBatch(from, destinations) {
  const token = process.env.MAPBOX_ACCESS_TOKEN;

  const coords = [from, ...destinations].map((point) => `${point.lng},${point.lat}`).join(";");
  const url = new URL(`${BASE_URL}/directions-matrix/v1/mapbox/cycling/${coords}`);
  url.searchParams.set("access_token", token);
  url.searchParams.set("sources", "0");
  url.searchParams.set("annotations", "duration,distance");


  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Mapbox API error: ${response.status} ${response.statusText}`);
  }
  const data = await response.json();
  const distance = data.distances?.[0];
  if (!Array.isArray(distance)) {
    throw new Error("Mapbox API error: distances が取得できませんでした");
  }
  const durations = data.durations?.[0];
  if (!Array.isArray(durations)) {
    throw new Error("Mapbox API error: durations が取得できませんでした");
  }

  // durations[0] の先頭は「出発地→出発地」の0秒なので取り除く。
  // これで戻り値のインデックスが destinations と1対1で揃う
  const destinationDurations = durations.slice(1);
  const destinationDistances = distance.slice(1);
  if (destinationDurations.length !== destinations.length) {
    throw new Error("Mapbox API error: durations の件数が目的地の数と一致しません");
  }
  return { durations: destinationDurations, distances: destinationDistances };
}

async function getReturnTravelTimesBatch(from, destinations) {
  const token = process.env.MAPBOX_ACCESS_TOKEN;
  const coords = [from, ...destinations].map((point) => `${point.lng},${point.lat}`).join(";");
  const url = new URL(`${BASE_URL}/directions-matrix/v1/mapbox/cycling/${coords}`);
  url.searchParams.set("access_token", token);
  url.searchParams.set("sources", destinations.map((_, index) => index + 1).join(";"));
  url.searchParams.set("destinations", "0");
  url.searchParams.set("annotations", "duration,distance");

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Mapbox API error: ${response.status} ${response.statusText}`);
  }

  const data = await response.json();
  const durations = data.durations?.map((row) => row?.[0]);
  const distances = data.distances?.map((row) => row?.[0]);
  if (!Array.isArray(durations) || !Array.isArray(distances)) {
    throw new Error("Mapbox API error: 復路のMatrixが取得できませんでした");
  }
  if (durations.length !== destinations.length || distances.length !== destinations.length) {
    throw new Error("Mapbox API error: 復路の件数が目的地の数と一致しません");
  }

  return { durations, distances };
}

// 候補が24件を超えても切り捨てず、Matrixの上限ごとに分割して全件の時間を調べる。
async function getTravelTimes(from, destinations) {
  if (!Array.isArray(destinations)) {
    throw new TypeError("destinations は配列で指定してください");
  }
  if (destinations.length === 0) {
    return { durations: [], distances: [] };
  }

  const batches = [];
  for (let index = 0; index < destinations.length; index += MAX_MATRIX_DESTINATIONS) {
    batches.push(destinations.slice(index, index + MAX_MATRIX_DESTINATIONS));
  }

  const results = await Promise.all(
    batches.map((batch) => getTravelTimesBatch(from, batch))
  );
  return {
    durations: results.flatMap((result) => result.durations),
    distances: results.flatMap((result) => result.distances),
  };
}

async function getRoundTripTravelTimes(from, destinations) {
  if (!Array.isArray(destinations)) {
    throw new TypeError("destinations は配列で指定してください");
  }
  if (destinations.length === 0) {
    return {
      outboundDurations: [],
      outboundDistances: [],
      returnDurations: [],
      returnDistances: [],
    };
  }

  const batches = [];
  for (let index = 0; index < destinations.length; index += MAX_MATRIX_DESTINATIONS) {
    batches.push(destinations.slice(index, index + MAX_MATRIX_DESTINATIONS));
  }

  // 復路は向きで時間が変わるため別計算。
  const results = await Promise.all(
    batches.map(async (batch) => {
      const [outbound, returning] = await Promise.all([
        getTravelTimesBatch(from, batch),
        getReturnTravelTimesBatch(from, batch),
      ]);
      return { outbound, returning };
    })
  );

  return {
    outboundDurations: results.flatMap((result) => result.outbound.durations),
    outboundDistances: results.flatMap((result) => result.outbound.distances),
    returnDurations: results.flatMap((result) => result.returning.durations),
    returnDistances: results.flatMap((result) => result.returning.distances),
  };
}

module.exports = { getIsochrone, getCyclingRoute, getTravelTimes, getRoundTripTravelTimes };

const express = require("express");
const mapbox = require("../services/mapbox");
const places = require("../services/place");

const router = express.Router();

// 1回の提案で返す最大件数。母集団(最大40件)からランダムに抜くことで毎回顔ぶれが変わる
const MAX_SUGGESTIONS = 10;

router.get("/", async (req, res) => {
  // クエリは文字列で来るので parseFloat / parseInt で数値に変換
  const lng = parseFloat(req.query.lng);
  const lat = parseFloat(req.query.lat);
  const minutes = parseInt(req.query.minutes, 10);
  const type = req.query.type || "cafe";
  // 数値でないものが混ざっていたら 400 で返す
  if (!Number.isFinite(lng) || !Number.isFinite(lat) || !Number.isFinite(minutes)) {
    return res.status(400).json({ error: "lng, lat, minutes は数値で指定してください" });
  }
  // 0分やマイナスはMapboxに渡す前にここで弾く
  if (minutes < 1) {
    return res.status(400).json({ error: "minutes は1以上で指定してください" });
  }

  // ここから先でやりたいこと:
  // 1. Mapboxで「この時間で行ける範囲」を取る
  // 2. その範囲をざっくり四角形(bbox)で囲む
  // 3. bboxを使って、あとでGoogle Placesの検索範囲を決める
  try {
    const isochroneData = await mapbox.getIsochrone(lng, lat, minutes);
    const searchArea = getSearchAreaFromIsochrone(isochroneData);

    const placesData = await places.getNearbyPlaces(
      searchArea.centerLng,
      searchArea.centerLat,
      searchArea.radius,
      type
    );
    const normalizedPlaces = places.normalizePlacesResponse(placesData);

    // フロントで使う名前をそろえる。
    // 全件返すと毎回同じ顔ぶれになるので、シャッフルしてから先頭N件だけ返す
    res.json({
      searchArea,
      places: places.shufflePlaces(normalizedPlaces).slice(0, MAX_SUGGESTIONS),
    });
  } catch (error) {
    // どのAPIで失敗したか確認しやすくする
    console.error(error);

    const message = error.message?.includes("Google Maps API error")
      ? "Google Maps APIの呼び出しに失敗しました"
      : "Mapbox APIの呼び出しに失敗しました";

    res.status(502).json({ error: message });
  }

});

function getSearchAreaFromIsochrone(isochroneData) {
  const coordinates = isochroneData.features?.[0]?.geometry?.coordinates?.[0];

  // 範囲が取れないときはここで止める
  if (!Array.isArray(coordinates) || coordinates.length === 0) {
    throw new Error("Mapbox API error: isochrone の座標が取得できませんでした");
  }

  // bbox用に、最初の座標を仮の最小・最大として置いておく
  let minLng = coordinates[0][0];
  let maxLng = coordinates[0][0];
  let minLat = coordinates[0][1];
  let maxLat = coordinates[0][1];

  // 全ての座標を見て、左端・右端・下端・上端を探す
  for (const coordinate of coordinates) {
    const pointLng = coordinate[0];
    const pointLat = coordinate[1];

    if (pointLng < minLng) minLng = pointLng;
    if (pointLng > maxLng) maxLng = pointLng;
    if (pointLat < minLat) minLat = pointLat;
    if (pointLat > maxLat) maxLat = pointLat;
  }

  const bbox = { minLng, maxLng, minLat, maxLat };
  const centerLng = (minLng + maxLng) / 2;
  const centerLat = (minLat + maxLat) / 2;

  // 緯度経度の差をざっくりメートルに直して、Places検索用の半径を作る
  const latMeters = (maxLat - minLat) * 111000;
  const lngMeters = (maxLng - minLng) * 111000 * Math.cos(centerLat * Math.PI / 180);
  const radius = Math.min(Math.ceil(Math.max(latMeters, lngMeters) / 2 * 1.2), 50000);

  return { bbox, centerLng, centerLat, radius };
}

module.exports = router;

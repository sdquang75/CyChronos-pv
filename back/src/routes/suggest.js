const express = require("express");
const mapbox = require("../services/mapbox");
const places = require("../services/place");
const visits = require("../services/visits");
const cache = require("../services/cache");

const router = express.Router();

// 1回の提案で返す最大件数。Matrixで時間判定した母集団からランダムに抜くことで毎回顔ぶれが変わる
const MAX_SUGGESTIONS = 10;
const MAX_MATRIX_DESTINATIONS = 24;
const SEARCH_POINT_COUNT = 4;

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

  // user_id は省略可。指定があれば訪問済みスポットを提案から除外する(trips系と同じくクエリで受ける)
  let userId = null;
  if (req.query.user_id !== undefined) {
    userId = Number(req.query.user_id);
    if (!Number.isInteger(userId) || userId <= 0) {
      return res.status(400).json({ error: "user_id は正の整数で指定してください" });
    }
  }

  // ここから先でやりたいこと:
  // 1. Mapboxで「この時間で行ける範囲」を取る
  // 2. その範囲をざっくり四角形(bbox)で囲む
  // 3. bboxを使って、あとでGoogle Placesの検索範囲を決める
  try {
    // 同じ場所・同じ条件の検索は数分間キャッシュを使い回す(Mapbox+Google課金と2秒待ちの節約)。
    // 座標は小数3桁(約100m)に丸め、GPSの微妙なブレでも同じキーに当たるようにする。
    // キャッシュするのは母集団まで。除外・シャッフルは毎回やるので提案の顔ぶれは変わる
    const cacheKey = `suggest:${lng.toFixed(3)},${lat.toFixed(3)},${minutes},${type}`;
    let candidates = cache.get(cacheKey);

    if (!candidates) {
      const isochroneData = await mapbox.getIsochrone(lng, lat, minutes + 10); //±10分
      const searchArea = getSearchAreaFromIsochrone(isochroneData);


      // 中心1点だけを検索すると、レストラン等が現在地付近に偏り、±10分帯の候補が消える。
      // 到達圏の外周を分散検索し、各方向の候補を均等に集めてから実所要時間を計算する。
      const searchPoints = searchArea.searchPoints;
      const placeSearchRadius = Math.min(
        Math.max(Math.ceil(searchArea.radius * 0.25), 1500),
        5000
      );
      const effectiveSearchPoints = searchPoints.length > 0
        ? searchPoints
        : [{ lng: searchArea.centerLng, lat: searchArea.centerLat }];
      const placesDataList = await Promise.all(
        effectiveSearchPoints.map((point) => places.getNearbyPlaces(
          point.lng,
          point.lat,
          placeSearchRadius,
          type,
          { includeNextPage: false }
        ))
      );
      const normalizedGroups = placesDataList.map(places.normalizePlacesResponse);
      let normalizedPlaces = places.mergeNormalizedPlaceGroups(
        normalizedGroups,
        MAX_MATRIX_DESTINATIONS
      );
      try {
        if (normalizedPlaces.length === 0) {
          throw new Error("検索条件に合う施設候補がありません");
        }
        // 候補から座標だけの配列を作る
        const coordsList = normalizedPlaces.map((place) => ({ lng: place.lng, lat: place.lat }));
        // 現在地から各候補への所要時間(秒)と距離(m)を取る
        const { durations, distances } = await mapbox.getTravelTimes({ lng, lat }, coordsList);
        //  候補に所要時間と距離を貼り付けた結果で置き換える
        normalizedPlaces = places.attachDurations(normalizedPlaces, durations, distances);
      }
      catch (error) {
        console.error(error);
      }
      candidates = {
        searchArea,
        normalizedPlaces,
      };

      cache.set(cacheKey, candidates);
    }


    // user_id があれば訪問済みの place_id を取得(なければ除外なし=空配列)
    const visitedPlaceIds = userId === null ? [] : await visits.getVisitedPlaceIds(userId);

    const filterdPlaces = places.filterWithinMinutes(candidates.normalizedPlaces, minutes); //±10分

    // 訪問済みを除外し、シャッフルして先頭N件だけ返す(足りなければ訪問済みで補充)

    // 選抜した候補に、フロント表示用の「約◯分」を付けて返す
    const picked = places.pickSuggestions(filterdPlaces, visitedPlaceIds, MAX_SUGGESTIONS);

    res.json({
      searchArea: candidates.searchArea,
      places: picked.map((place) => ({
        ...place,
        durationMinutes: place.durationSec == null ? null : Math.round(place.durationSec / 60),
        // kmの小数1桁(例: 6316m -> 6.3)。/1000してからtoFixedだと文字列になるので、100で割って丸めて10で割る
        distanceKm: place.distanceM == null ? null : Math.round(place.distanceM / 100) / 10,
      })),
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

  const searchPoints = places.getBoundarySearchPoints(coordinates, SEARCH_POINT_COUNT);
  return { bbox, centerLng, centerLat, radius, searchPoints };
}

module.exports = router;

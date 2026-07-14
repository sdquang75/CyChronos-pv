// 地図系APIのルーター。リクエストの受け取り・バリデーション・レスポンス整形だけを担当し、
// 外部APIの呼び出しは services/ 配下（mapbox.js / place.js）に任せる。

const express = require("express");
const mapbox = require("../services/mapbox");
const places = require("../services/place");

const router = express.Router();

router.get("/isochrone", async (req, res) => {
  // parseFloat / parseInt で数値に変換
  const lng = parseFloat(req.query.lng);
  const lat = parseFloat(req.query.lat);
  const minutes = parseInt(req.query.minutes, 10);

  // 数値でないものが混ざっていたら 400 で返す
  if (!Number.isFinite(lng) || !Number.isFinite(lat) || !Number.isFinite(minutes)) {
    return res.status(400).json({ error: "lng, lat, minutes は数値で指定してください" });
  }
  // 0分やマイナスはMapboxに渡す前にここで弾く
  if (minutes < 1) {
    return res.status(400).json({ error: "minutes は1以上で指定してください" });
  }

  // Mapbox に問い合わせて結果をそのまま返す
  try {
    const data = await mapbox.getIsochrone(lng, lat, minutes);
    res.json(data);
  } catch (error) {
    // 失敗の原因(HTTPステータスやMapboxのエラー文)をサーバーログに残す
    console.error(error);
    res.status(502).json({ error: "Mapbox APIの呼び出しに失敗しました" });
  }
});

router.get("/route", async (req, res) => {
  // 出発地と目的地、合わせて4つの座標をクエリから取得
  const fromLng = parseFloat(req.query.fromLng);
  const fromLat = parseFloat(req.query.fromLat);
  const toLng = parseFloat(req.query.toLng);
  const toLat = parseFloat(req.query.toLat);

  // どれか数値でなければ 400 で返す
  if (!Number.isFinite(fromLng) || !Number.isFinite(fromLat) || !Number.isFinite(toLng) || !Number.isFinite(toLat)) {
    return res.status(400).json({ error: "数値で指定してください" });
  }

  // from/to を { lng, lat } の形に包んで Mapbox に渡す
  try {
    const cyRoute = await mapbox.getCyclingRoute({ lng: fromLng, lat: fromLat }, { lng: toLng, lat: toLat });
    res.json(cyRoute);
  } catch (error) {
    // 失敗の原因をサーバーログに残す
    console.error(error);
    res.status(502).json({ error: "Mapbox APIの呼び出しに失敗しました" });
  }
});


router.get("/places", async (req, res) => {
  // 中心座標と検索条件をクエリから取得
  const lng = parseFloat(req.query.lng);
  const lat = parseFloat(req.query.lat);
  const radius = parseInt(req.query.radius, 10);
  const type = req.query.type;

  // 座標・半径が数値でなければ 400 で返す
  if (!Number.isFinite(lng) || !Number.isFinite(lat) || !Number.isFinite(radius)) {
    return res.status(400).json({ error: "lng, lat, radius は数値で指定してください" });
  }

  // Google Places に問い合わせて、フロントで使いやすい形に整形して返す
  try {
    const data = await places.getNearbyPlaces(lng, lat, radius, type);
    const normalizedPlaces = places.normalizePlacesResponse(data);
    res.json(normalizedPlaces);
  } catch (error) {
    // 失敗の原因をサーバーログに残す
    console.error(error);
    res.status(502).json({ error: "Google Maps APIの呼び出しに失敗しました" });
  }
});

router.get("/photo", async (req, res) => {
  // photoReferenceとmaxWidthをクエリから取得
  const photoReference = req.query.photoReference;
  const maxWidth = parseInt(req.query.maxwidth, 10);

  // photoReferenceが指定されていない場合は400で返す
  if (req.query.photoReference == null || req.query.photoReference == undefined) {
    return res.status(400).json({ error: "photoReferenceは必須です" });
  }

  try {
    const photoResponse = await places.getPlacePhoto(photoReference, maxWidth);
    res.set("Content-Type", photoResponse.contentType);
    res.send(photoResponse.buffer);
  } catch (error) {
    // 失敗の原因をサーバーログに残す
    console.error(error);
    res.status(502).json({ error: "Google Maps APIの呼び出しに失敗しました" });
  }
});

module.exports = router;

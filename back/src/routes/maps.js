// 地図系APIのルーター。リクエストの受け取り・バリデーション・レスポンス整形だけを担当し、
// 外部APIの呼び出しは services/mapbox.js に任せる。

const express = require("express");
const mapbox = require("../services/mapbox");

const router = express.Router();

// GET /api/maps/isochrone?lng=139.76&lat=35.68&minutes=45
router.get("/isochrone", async (req, res) => {
  // TODO:
  // 1. req.query から lng, lat, minutes を取り出す
  // 2. 値が無い/数値でない場合は 400 を返す
  // 3. mapbox.getIsochrone(...) を呼んで結果を res.json で返す
  const lng = parseFloat(req.query.lng);
  const lat = parseFloat(req.query.lat);
  const minutes = parseInt(req.query.minutes);

  if (!Number.isFinite(lng) || !Number.isFinite(lat) || !Number.isFinite(minutes)) {
    return res.status(400).json({ error: "すげえエラー" });
  }

  try {
    const data = await mapbox.getIsochrone(lng, lat, minutes);
    res.json(data);
  } catch (error) {
    res.status(502).json({ error: "すごくすごいエラー" });
  }
});


// GET /api/maps/route?fromLng=..&fromLat=..&toLng=..&toLat=..
router.get("/route", async (req, res) => {
  // TODO: isochrone と同じ流れで mapbox.getCyclingRoute(...) を使う
  res.status(501).json({ error: "すごくすごいエラー" });
});

module.exports = router;

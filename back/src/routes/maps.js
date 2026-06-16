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
  res.status(501).json({ error: "not implemented" });
});

// GET /api/maps/route?fromLng=..&fromLat=..&toLng=..&toLat=..
router.get("/route", async (req, res) => {
  // TODO: isochrone と同じ流れで mapbox.getCyclingRoute(...) を使う
  res.status(501).json({ error: "not implemented" });
});

module.exports = router;

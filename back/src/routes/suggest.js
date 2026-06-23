

const express = require("express");
const mapbox = require("../services/mapbox");
const places = require("../services/place");

const router = express.Router();

router.get("/", async (req, res) => {
   res.json([
  {
    "id": "ChIJ_____sample1",
    "name": "サザコーヒー 本店",
    "lat": 35.6815,
    "lng": 139.7673,
    "address": "東京都千代田区丸の内1-9-1",
    "rating": 4.3,
    "genre": "cafe"
  },
  {
    "id": "ChIJ_____sample2",
    "name": "猿田彦珈琲 恵比寿本店",
    "lat": 35.6465,
    "lng": 139.7100,
    "address": "東京都渋谷区恵比寿1-6-6",
    "rating": 4.1,
    "genre": "cafe"
  },
  {
    "id": "ChIJ_____sample3",
    "name": "ブルーボトルコーヒー 清澄白河",
    "lat": 35.6819,
    "lng": 139.7995,
    "address": "東京都江東区平野1-4-8",
    "rating": 4.0,
    "genre": "cafe"
  }
    ]);
});

module.exports = router;
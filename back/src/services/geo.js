// 座標まわりの計算をまとめる。走行実績の集計(trip_history の total_distance_m)で使う

// 2点間の距離(m)。地球を半径6,371kmの球とみなすHaversine法。
// 数km〜数十kmのサイクリング用途なら誤差は無視できる
function distanceMeters(from, to) {
  const EARTH_RADIUS_M = 6371000;
  const toRadians = (degrees) => (degrees * Math.PI) / 180;

  const lat1 = toRadians(from.lat);
  const lat2 = toRadians(to.lat);
  const deltaLat = toRadians(to.lat - from.lat);
  const deltaLng = toRadians(to.lng - from.lng);

  const a =
    Math.sin(deltaLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) ** 2;

  return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(a));
}

// 座標の並びを順にたどった総距離(m)。2点未満なら 0
function totalDistanceMeters(points) {
  let total = 0;
  for (let i = 1; i < points.length; i += 1) {
    total += distanceMeters(points[i - 1], points[i]);
  }
  return total;
}

module.exports = { distanceMeters, totalDistanceMeters };

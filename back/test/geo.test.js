const test = require("node:test");
const assert = require("node:assert");

const geo = require("../src/services/geo");

// 実測に近い基準点。大阪駅→大阪城公園は直線で約3.5km
const OSAKA_STATION = { lat: 34.7025, lng: 135.4959 };
const OSAKA_CASTLE = { lat: 34.6873, lng: 135.5259 };

test("distanceMeters: 同じ地点は0m", () => {
  assert.strictEqual(geo.distanceMeters(OSAKA_STATION, OSAKA_STATION), 0);
});

test("distanceMeters: 大阪駅→大阪城が実距離(約3.4km)に収まる", () => {
  const meters = geo.distanceMeters(OSAKA_STATION, OSAKA_CASTLE);
  assert.ok(meters > 3200 && meters < 3600, `想定外の距離: ${meters}m`);
});

test("distanceMeters: 向きを逆にしても同じ距離になる", () => {
  const forward = geo.distanceMeters(OSAKA_STATION, OSAKA_CASTLE);
  const backward = geo.distanceMeters(OSAKA_CASTLE, OSAKA_STATION);
  assert.ok(Math.abs(forward - backward) < 0.001);
});

test("distanceMeters: 緯度1度の差はおよそ111km", () => {
  const meters = geo.distanceMeters({ lat: 34, lng: 135 }, { lat: 35, lng: 135 });
  assert.ok(meters > 110000 && meters < 112000, `想定外の距離: ${meters}m`);
});

test("totalDistanceMeters: 2点未満は0m(座標ログが無いトリップ)", () => {
  assert.strictEqual(geo.totalDistanceMeters([]), 0);
  assert.strictEqual(geo.totalDistanceMeters([OSAKA_STATION]), 0);
});

test("totalDistanceMeters: 経由地を挟むと各区間の合計になる", () => {
  const waypoint = { lat: 34.6950, lng: 135.5100 };
  const legs =
    geo.distanceMeters(OSAKA_STATION, waypoint) +
    geo.distanceMeters(waypoint, OSAKA_CASTLE);

  const total = geo.totalDistanceMeters([OSAKA_STATION, waypoint, OSAKA_CASTLE]);
  assert.ok(Math.abs(total - legs) < 0.001);
});

test("totalDistanceMeters: 経由すると直線距離より長くなる", () => {
  const waypoint = { lat: 34.7200, lng: 135.5100 }; // 北へ迂回する
  const direct = geo.distanceMeters(OSAKA_STATION, OSAKA_CASTLE);
  const detour = geo.totalDistanceMeters([OSAKA_STATION, waypoint, OSAKA_CASTLE]);
  assert.ok(detour > direct, "迂回したのに直線距離以下になっている");
});

// pickSuggestions(訪問済み除外+補充)などのテスト。外部API不要で `node --test` で実行できる
const test = require("node:test");
const assert = require("node:assert");
const { applyPlaceSearchFilter, mergeNormalizedPlaceGroups, getBoundarySearchPoints, pickSuggestions, attachDurations, filterWithinMinutes } = require("../src/services/place");

// テスト用のダミー候補を n 件作る(idは p1, p2, ...)
function makePlaces(n) {
  return Array.from({ length: n }, (_, i) => ({ id: `p${i + 1}`, name: `スポット${i + 1}` }));
}

test("訪問済みの place_id が候補から除外される", () => {
  const picked = pickSuggestions(makePlaces(20), ["p1", "p2"], 10);
  const ids = picked.map((p) => p.id);
  assert.ok(!ids.includes("p1"));
  assert.ok(!ids.includes("p2"));
  assert.strictEqual(picked.length, 10);
});

test("訪問済みが空なら全候補が対象になる", () => {
  const picked = pickSuggestions(makePlaces(5), [], 10);
  assert.strictEqual(picked.length, 5);
});

test("未訪問だけで足りないときは訪問済みから補充される", () => {
  // 候補12件中8件が訪問済み → 未訪問4件+訪問済み6件で10件になる
  const visited = ["p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8"];
  const picked = pickSuggestions(makePlaces(12), visited, 10);
  assert.strictEqual(picked.length, 10);

  // 未訪問4件(p9〜p12)は必ず全部入っている
  const ids = picked.map((p) => p.id);
  for (const id of ["p9", "p10", "p11", "p12"]) {
    assert.ok(ids.includes(id), `${id} が含まれていない`);
  }

  // 同じスポットが重複して入っていない
  assert.strictEqual(new Set(ids).size, ids.length);
});

test("全部訪問済みでも maxCount 件まで返す(候補ゼロにしない)", () => {
  const places = makePlaces(15);
  const picked = pickSuggestions(places, places.map((p) => p.id), 10);
  assert.strictEqual(picked.length, 10);
});

// --- attachDurations(所要時間の付与) ---

test("durations が順番通りに durationSec として付く", () => {
  const result = attachDurations(makePlaces(3), [100, 200, 300]);
  assert.deepStrictEqual(result.map((p) => p.durationSec), [100, 200, 300]);
  assert.strictEqual(result[0].id, "p1"); // 元のフィールドも残っている
});

test("durations の null(到達不能) と 不足分は null になる", () => {
  const result = attachDurations(makePlaces(3), [100, null]); // 3件に対して2件しかない
  assert.deepStrictEqual(result.map((p) => p.durationSec), [100, null, null]);
});

test("distances も distanceM として付く(未指定なら null)", () => {
  const withDistances = attachDurations(makePlaces(2), [100, 200], [1500, null]);
  assert.deepStrictEqual(withDistances.map((p) => p.distanceM), [1500, null]);

  const withoutDistances = attachDurations(makePlaces(2), [100, 200]); // 第3引数なし
  assert.deepStrictEqual(withoutDistances.map((p) => p.distanceM), [null, null]);
});

test("attachDurations は元の配列を変更しない", () => {
  const original = makePlaces(2);
  attachDurations(original, [100, 200]);
  assert.strictEqual(original[0].durationSec, undefined);
});

// --- filterWithinMinutes(時間超過の除外) ---

test("指定時間の±10分を外れる場所と到達不能(null)が落ちる", () => {
  const places = attachDurations(makePlaces(6), [1199, 1200, 1800, 2400, 2401, null]);
  const result = filterWithinMinutes(places, 30); // 30分指定では20〜40分を残す
  assert.deepStrictEqual(result.map((p) => p.durationSec), [1200, 1800, 2400]); // 境界ちょうどは残る
});

test("全部超過なら空配列になる", () => {
  const places = attachDurations(makePlaces(2), [3600, 7200]);
  assert.deepStrictEqual(filterWithinMinutes(places, 30), []);
});

test("±10分より近い候補へフォールバックせず、時間条件を厳守する", () => {
  const places = attachDurations(makePlaces(3), [300, 600, 1199]);
  const result = filterWithinMinutes(places, 30);
  assert.deepStrictEqual(result, []);
});

test("durationSec が無い place は時間条件を保証できないため除外する", () => {
  const result = filterWithinMinutes(makePlaces(3), 30); // attachDurations を通していない
  assert.strictEqual(result.length, 0);
});

// --- applyPlaceSearchFilter(Google Nearby Searchの検索条件) ---

test("すべて(allと旧point_of_interest)は非対応typeを送らず、ジャンルを絞らない", () => {
  for (const type of ["all", "point_of_interest"]) {
    const url = new URL("https://example.test/search");
    applyPlaceSearchFilter(url, type);
    assert.strictEqual(url.searchParams.has("type"), false);
    assert.strictEqual(url.searchParams.has("keyword"), false);
  }
});

test("寺院(templeと旧place_of_worship)はtypeではなく日本語キーワードで検索する", () => {
  for (const type of ["temple", "place_of_worship"]) {
    const url = new URL("https://example.test/search");
    applyPlaceSearchFilter(url, type);
    assert.strictEqual(url.searchParams.has("type"), false);
    assert.strictEqual(url.searchParams.get("keyword"), "寺院");
  }
});

test("グルメ(restaurant)など対応typeはそのまま送る", () => {
  const url = new URL("https://example.test/search");
  applyPlaceSearchFilter(url, "restaurant");
  assert.strictEqual(url.searchParams.get("type"), "restaurant");
  assert.strictEqual(url.searchParams.has("keyword"), false);
});

// --- 外周分散検索の候補作成 ---

test("Isochrone外周から指定数の検索中心を等間隔で作る", () => {
  const ring = [
    [0, 0], [1, 0], [2, 0], [3, 0],
    [4, 0], [5, 0], [6, 0], [7, 0], [0, 0],
  ];
  assert.deepStrictEqual(getBoundarySearchPoints(ring, 4), [
    { lng: 0, lat: 0 },
    { lng: 2, lat: 0 },
    { lng: 4, lat: 0 },
    { lng: 6, lat: 0 },
  ]);
});

test("複数方向の候補を均等に結合し、place_id重複を除外する", () => {
  const result = mergeNormalizedPlaceGroups([
    [{ id: "a" }, { id: "b" }, { id: "c" }],
    [{ id: "d" }, { id: "a" }, { id: "e" }],
  ], 4);
  assert.deepStrictEqual(result.map((place) => place.id), ["a", "d", "b", "c"]);
});

// --- normalizePlacesResponse(会社・事業所の除外) ---

const { normalizePlacesResponse } = require("../src/services/place");

// テスト用のGoogle Nearby Searchレスポンス1件分を作る
function makeGooglePlace(name, types) {
  return {
    place_id: `id-${name}`,
    name,
    geometry: { location: { lat: 35.0, lng: 139.0 } },
    vicinity: "テスト住所",
    types,
  };
}

test("typesが汎用typeだけの施設(会社・オフィス)は除外される", () => {
  const data = { results: [
    makeGooglePlace("株式会社テスト", ["point_of_interest", "establishment"]),
    makeGooglePlace("いいカフェ", ["cafe", "point_of_interest", "establishment"]),
  ]};
  const result = normalizePlacesResponse(data);
  assert.deepStrictEqual(result.map((p) => p.name), ["いいカフェ"]);
});

test("事業所系type(不動産屋・保険代理店など)は除外される", () => {
  const data = { results: [
    makeGooglePlace("テスト不動産", ["real_estate_agency", "point_of_interest", "establishment"]),
    makeGooglePlace("テスト保険", ["insurance_agency", "point_of_interest", "establishment"]),
    makeGooglePlace("いい公園", ["park", "point_of_interest", "establishment"]),
  ]};
  const result = normalizePlacesResponse(data);
  assert.deepStrictEqual(result.map((p) => p.name), ["いい公園"]);
});

test("typesが無い施設も除外される(何の施設か判断できないため)", () => {
  const data = { results: [
    { place_id: "id-x", name: "types無し", geometry: { location: { lat: 35, lng: 139 } } },
    makeGooglePlace("いい神社", ["place_of_worship", "point_of_interest"]),
  ]};
  const result = normalizePlacesResponse(data);
  assert.deepStrictEqual(result.map((p) => p.name), ["いい神社"]);
});

test("すべて検索で返る大阪市・北区などの行政区画は除外する", () => {
  const data = { results: [
    makeGooglePlace("大阪市", ["locality", "political"]),
    makeGooglePlace("北区", ["sublocality_level_1", "sublocality", "political"]),
    makeGooglePlace("大阪城", ["tourist_attraction", "point_of_interest", "establishment"]),
  ]};
  const result = normalizePlacesResponse(data);
  assert.deepStrictEqual(result.map((p) => p.name), ["大阪城"]);
});

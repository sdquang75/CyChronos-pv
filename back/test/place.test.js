// pickSuggestions(訪問済み除外+補充)などのテスト。外部API不要で `node --test` で実行できる
const test = require("node:test");
const assert = require("node:assert");
const { pickSuggestions, attachDurations, filterWithinMinutes } = require("../src/services/place");

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

test("attachDurations は元の配列を変更しない", () => {
  const original = makePlaces(2);
  attachDurations(original, [100, 200]);
  assert.strictEqual(original[0].durationSec, undefined);
});

// --- filterWithinMinutes(時間超過の除外) ---

test("指定時間を超える場所と到達不能(null)が落ちる", () => {
  const places = attachDurations(makePlaces(4), [600, 1800, 1801, null]);
  const result = filterWithinMinutes(places, 30); // 30分 = 1800秒まで
  assert.deepStrictEqual(result.map((p) => p.durationSec), [600, 1800]); // 境界ちょうどは残る
});

test("全部超過なら空配列になる", () => {
  const places = attachDurations(makePlaces(2), [3600, 7200]);
  assert.deepStrictEqual(filterWithinMinutes(places, 30), []);
});

test("durationSec が無い place は素通りする(Matrix失敗時のフォールバック)", () => {
  const result = filterWithinMinutes(makePlaces(3), 30); // attachDurations を通していない
  assert.strictEqual(result.length, 3);
});

// pickSuggestions(訪問済み除外+補充)のテスト。外部API不要で `node --test` で実行できる
const test = require("node:test");
const assert = require("node:assert");
const { pickSuggestions } = require("../src/services/place");

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

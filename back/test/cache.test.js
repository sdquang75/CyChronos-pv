// services/cache.js(期限つきメモリキャッシュ)のテスト。`node --test` で実行できる
const test = require("node:test");
const assert = require("node:assert");
const cache = require("../src/services/cache");

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

test("保存した値がそのまま取り出せる", () => {
  cache.set("key1", { hello: "world" });
  assert.deepStrictEqual(cache.get("key1"), { hello: "world" });
});

test("存在しないキーは null", () => {
  assert.strictEqual(cache.get("no-such-key"), null);
});

test("期限切れの値は取り出せない", async () => {
  cache.set("short-lived", "value", 20); // 20msだけ保持
  await sleep(50);
  assert.strictEqual(cache.get("short-lived"), null);
});

test("上限を超えたら一番古いエントリから消える", () => {
  // 上限(100件)まで詰めてから1件足すと、最初に入れたものが追い出される
  for (let i = 0; i < 100; i++) {
    cache.set(`fill-${i}`, i);
  }
  cache.set("one-more", "new");

  assert.strictEqual(cache.get("fill-0"), null); // 一番古いものが消えている
  assert.strictEqual(cache.get("one-more"), "new");
  assert.strictEqual(cache.get("fill-99"), 99); // 新しめのものは残っている
});

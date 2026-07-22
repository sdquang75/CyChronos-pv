const test = require("node:test");
const assert = require("node:assert");
const { getTravelTimes } = require("../src/services/mapbox");

test("Matrix上限を超える候補を24件ずつに分割し、結果を元の順序で結合する", async (t) => {
  const originalFetch = global.fetch;
  const coordinateCounts = [];
  global.fetch = async (requestUrl) => {
    const url = new URL(requestUrl);
    const coordinates = url.pathname.split("/").at(-1).split(";");
    coordinateCounts.push(coordinates.length);
    const destinationCount = coordinates.length - 1;
    return {
      ok: true,
      json: async () => ({
        durations: [[0, ...Array.from({ length: destinationCount }, (_, index) => index + 1)]],
        distances: [[0, ...Array.from({ length: destinationCount }, (_, index) => index + 101)]],
      }),
    };
  };
  t.after(() => { global.fetch = originalFetch; });

  const destinations = Array.from({ length: 50 }, (_, index) => ({
    lng: 135 + index / 1000,
    lat: 34 + index / 1000,
  }));
  const result = await getTravelTimes({ lng: 135, lat: 34 }, destinations);

  assert.deepStrictEqual(coordinateCounts, [25, 25, 3]);
  assert.strictEqual(result.durations.length, 50);
  assert.strictEqual(result.distances.length, 50);
  assert.deepStrictEqual(result.durations.slice(24, 27), [1, 2, 3]);
});

test("候補が0件ならMatrix APIを呼ばず空配列を返す", async (t) => {
  const originalFetch = global.fetch;
  let called = false;
  global.fetch = async () => {
    called = true;
    throw new Error("呼ばれない想定");
  };
  t.after(() => { global.fetch = originalFetch; });

  const result = await getTravelTimes({ lng: 135, lat: 34 }, []);

  assert.deepStrictEqual(result, { durations: [], distances: [] });
  assert.strictEqual(called, false);
});

const test = require("node:test");
const assert = require("node:assert");
const { getCyclingRoute, getTravelTimes, getRoundTripTravelTimes } = require("../src/services/mapbox");

test("自転車ルートは日本語のターン案内を含めて取得する", async (t) => {
  const originalFetch = global.fetch;
  let requestedUrl;
  global.fetch = async (requestUrl) => {
    requestedUrl = new URL(requestUrl);
    return {
      ok: true,
      json: async () => ({ routes: [] }),
    };
  };
  t.after(() => { global.fetch = originalFetch; });

  await getCyclingRoute(
    { lng: 139.7673, lat: 35.6812 },
    { lng: 139.7800, lat: 35.7000 }
  );

  assert.strictEqual(requestedUrl.searchParams.get("geometries"), "geojson");
  assert.strictEqual(requestedUrl.searchParams.get("overview"), "full");
  assert.strictEqual(requestedUrl.searchParams.get("steps"), "true");
  assert.strictEqual(requestedUrl.searchParams.get("language"), "ja");
  assert.strictEqual(requestedUrl.searchParams.get("roundabout_exits"), "true");
});

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

test("往復は往路と復路を別方向で取得し、元の順序で返す", async (t) => {
  const originalFetch = global.fetch;
  const calls = [];
  global.fetch = async (requestUrl) => {
    const url = new URL(requestUrl);
    calls.push({
      sources: url.searchParams.get("sources"),
      destinations: url.searchParams.get("destinations"),
    });

    if (url.searchParams.get("destinations") === "0") {
      return {
        ok: true,
        json: async () => ({
          durations: [[11], [22]],
          distances: [[110], [220]],
        }),
      };
    }

    return {
      ok: true,
      json: async () => ({
        durations: [[0, 10, 20]],
        distances: [[0, 100, 200]],
      }),
    };
  };
  t.after(() => { global.fetch = originalFetch; });

  const result = await getRoundTripTravelTimes(
    { lng: 135, lat: 34 },
    [{ lng: 135.1, lat: 34.1 }, { lng: 135.2, lat: 34.2 }]
  );

  assert.deepStrictEqual(calls, [
    { sources: "0", destinations: null },
    { sources: "1;2", destinations: "0" },
  ]);
  assert.deepStrictEqual(result, {
    outboundDurations: [10, 20],
    outboundDistances: [100, 200],
    returnDurations: [11, 22],
    returnDistances: [110, 220],
  });
});

test("往復候補が0件ならMatrix APIを呼ばない", async (t) => {
  const originalFetch = global.fetch;
  let called = false;
  global.fetch = async () => {
    called = true;
    throw new Error("呼ばれない想定");
  };
  t.after(() => { global.fetch = originalFetch; });

  const result = await getRoundTripTravelTimes({ lng: 135, lat: 34 }, []);

  assert.deepStrictEqual(result, {
    outboundDurations: [],
    outboundDistances: [],
    returnDurations: [],
    returnDistances: [],
  });
  assert.strictEqual(called, false);
});

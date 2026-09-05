//スポットだすやつにょー

const BASE_URL = "https://maps.googleapis.com"; // Google Maps APIのベースURL   
const hidecategory = [
  // 宿泊・生活インフラ系(サイクリングの目的地として弱い)
  "lodging", "hotel", "parking", "gas_station", "atm", "bank", "hospital", "doctor", "pharmacy",
  "school", "university", "police", "fire_station", "post_office", "local_government_office",
  // 会社・事業所系(観光目的地ではないので除外)
  "insurance_agency", "real_estate_agency", "lawyer", "accounting", "finance",
  "general_contractor", "electrician", "plumber", "roofing_contractor", "painter",
  "moving_company", "storage", "car_dealer", "car_repair", "car_rental", "car_wash",
  "locksmith", "laundry", "funeral_home", "cemetery", "courthouse", "embassy", "city_hall",
  "travel_agency", "dentist", "veterinary_care", "physiotherapist", "taxi_stand",
];

// 「それだけでは何の施設か分からない」汎用type。
// カテゴリ未設定の会社・オフィスは types がこれだけになりがちなので、
// 全typeが汎用のものは目的地候補から外す
const genericTypes = ["point_of_interest", "establishment", "premise", "geocode", "plus_code"];

// 「すべて」検索で返りやすい市区町村・住所など、目的地ではない地理情報type。
const administrativeTypes = new Set([
  "country", "political", "locality", "sublocality", "neighborhood",
  "postal_code", "postal_code_prefix", "postal_code_suffix", "postal_town",
  "route", "street_address", "street_number", "intersection",
]);

const sabunminutes = 10; //±10分の範囲で候補を絞る

/**
 * 指定範囲からいけそうなスポットを取得する
 * @param {number} radius 半径(m)
 * @param {string} type スポットの種類
 * @param {number} lng 経度
 * @param {number} lat 緯度
 */
async function getNearbyPlaces(lng, lat, radius, type, { includeNextPage = true } = {}) {

  // .env に置いた Google Places のAPIキーを読み込む
  const token = process.env.GOOGLE_PLACES_API_KEY;

  // Nearby Search のURLを組み立てる。location は「緯度,経度」の順（Mapboxと逆なので注意）
  // キー未設定だと Google は「invalid key」としか返さず原因が分かりにくいので、ここで明示する
  if (!token) {
    throw new Error("Google Maps API error: GOOGLE_PLACES_API_KEY が設定されていません(back/.env を確認)");
  }

  const url = new URL(`${BASE_URL}/maps/api/place/nearbysearch/json`);
  url.searchParams.set("location", `${lat},${lng}`); // 検索の中心座標
  url.searchParams.set("radius", radius);            // 検索半径(m)
  applyPlaceSearchFilter(url, type);
  url.searchParams.set("language", "ja");            // 名前・住所を日本語で返させる(未指定だとローマ字になりがち)
  url.searchParams.set("key", token);                // APIキー

  const data = await fetchPlacesJson(url);
  const results = [...(data.results ?? [])];

  // Googleは1回につき最大20件・毎回同じ「有名さ順」しか返さない。
  // next_page_token で2ページ目(最大+20件)を取り、提案の母集団を増やす。
  // 3ページ目まで取ると更に+2秒かかるので、いまは2ページで止めている。
  if (includeNextPage && data.next_page_token) {
    try {
      results.push(...(await fetchNextPage(data.next_page_token, token)));
    } catch (error) {
      // 2ページ目の失敗は致命傷ではないので、1ページ目だけで続行する
      console.error("Nearby Search 2ページ目の取得に失敗:", error.message);
    }
  }

  return { ...data, results };
}

function isAdministrativeType(type) {
  return administrativeTypes.has(type) ||
    /^administrative_area_level_[1-7]$/.test(type) ||
    /^sublocality_level_[1-5]$/.test(type);
}

// Nearby Search (Legacy) の type に使えないレスポンス専用typeを吸収する。
// 既存フロントとの互換性を保つため point_of_interest / place_of_worship も受け付ける。
function applyPlaceSearchFilter(url, type) {
  const normalizedType = typeof type === "string" ? type.trim() : "";

  if (!normalizedType || normalizedType === "all" || normalizedType === "point_of_interest") {
    return;
  }

  if (normalizedType === "temple" || normalizedType === "place_of_worship") {
    url.searchParams.set("keyword", "寺院");
    return;
  }

  url.searchParams.set("type", normalizedType);
}

/**
 * スポットの写真を1枚取得する(返ってくるのはJSONではなく画像データそのもの)
 * @param {string} photoReference Nearby Search の photos[0].photo_reference の値
 * @param {number} maxWidth 画像の最大幅(px)
 */
async function getPlacePhoto(photoReference, maxWidth) {
  // Google Places のAPIキーを読み込む
  const token = process.env.GOOGLE_PLACES_API_KEY;

  // urlを組み立てる。Googleに渡すクエリ名は photo_reference(スネークケース)
  const url = new URL(`${BASE_URL}/maps/api/place/photo`);
  url.searchParams.set("photo_reference", photoReference);
  url.searchParams.set("maxwidth", maxWidth);
  url.searchParams.set("key", token);

  // 302リダイレクトはfetchが自動で追ってくれるので、そのまま画像本体が返ってくる
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Google Maps API error: ${response.status} ${response.statusText}`);
  }

  // 画像の種類(image/jpeg等)と中身のバイト列を、ルーターがそのまま送れる形にして返す
  const contentType = response.headers.get("content-type") ?? "image/jpeg";
  const buffer = Buffer.from(await response.arrayBuffer());
  return { contentType, buffer };
}

// Google に問い合わせ。HTTP自体が失敗ならthrow
// ※注意: キー不正などでも 200 が返ることがあり、本当の成否は data.status に入る
async function fetchPlacesJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Google Maps API error: ${response.status} ${response.statusText}`);
  }
  const data = await response.json();
  if (data.status === "OK" || data.status === "ZERO_RESULTS") {
    return data;
  }

  // REQUEST_DENIED などの理由は error_message に入る
  // (例: APIキーのIP制限で拒否、キーが無効)。原因を追えるよう status と一緒に残す
  const reason = data.error_message ? ` - ${data.error_message}` : "";
  throw new Error(`Google Maps API error: ${data.status}${reason}`);
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// next_page_token は発行直後は無効で、有効になるまで数秒かかるGoogle側の癖がある。
// 2秒待ってから取得し、まだ無効(INVALID_REQUEST)ならもう1回だけ待って再試行する
async function fetchNextPage(pageToken, token) {
  const url = new URL(`${BASE_URL}/maps/api/place/nearbysearch/json`);
  url.searchParams.set("pagetoken", pageToken); // 検索条件は概ねトークンに入っているが…
  url.searchParams.set("language", "ja");       // language は引き継がれず英語に戻るので毎回付ける
  url.searchParams.set("key", token);

  await sleep(2000);
  try {
    const data = await fetchPlacesJson(url);
    return data.results ?? [];
  } catch (error) {
    if (!error.message.includes("INVALID_REQUEST")) throw error;
    await sleep(1500);
    const data = await fetchPlacesJson(url);
    return data.results ?? [];
  }
}

function normalizePlace(place) {
  const location = place.geometry?.location ?? {};

  return {
    id: place.place_id,
    name: place.name,
    lat: location.lat,
    lng: location.lng,
    address: place.vicinity ?? place.formatted_address ?? "",
    rating: typeof place.rating === "number" ? place.rating : null,
    photoReference: Array.isArray(place.photos) && place.photos.length > 0 ? place.photos[0].photo_reference : null,
    genre: Array.isArray(place.types) && place.types.length > 0 ? place.types[0] : null,
  };
}

function normalizePlacesResponse(data) {
  return (data.results ?? [])
    // ホテル・駐車場・会社など、サイクリングの目的地として弱いものを先に外す
    .filter((place) => {
      const hasHiddenCategory = place.types &&
        place.types.some((type) => hidecategory.includes(type));

      return !hasHiddenCategory;
    })
    // 「大阪市」「北区」等の行政区画・住所結果はサイクリング目的地ではないので外す
    .filter((place) => {
      const types = Array.isArray(place.types) ? place.types : [];
      return !types.some(isAdministrativeType);
    })
    // typesが汎用type(point_of_interest等)だけの施設は、カテゴリ未設定の会社・オフィスの
    // 可能性が高いので外す(typesが無いものも同様に外す)
    .filter((place) => {
      const types = Array.isArray(place.types) ? place.types : [];
      return types.some((type) => !genericTypes.includes(type));
    })
    .map(normalizePlace)
    // 画面表示に最低限必要な値がないものはここで落とす
    .filter((place) =>
      place.id &&
      place.name &&
      Number.isFinite(place.lat) &&
      Number.isFinite(place.lng)
    );
}

// 複数の外周検索結果を方向ごとに1件ずつ取り、place_id重複を除きながら均等に結合する。
function mergeNormalizedPlaceGroups(placeGroups, maxCount) {
  const groups = placeGroups.filter(Array.isArray);
  const maxGroupLength = groups.reduce((max, group) => Math.max(max, group.length), 0);
  const merged = [];
  const seenIds = new Set();

  for (let index = 0; index < maxGroupLength && merged.length < maxCount; index += 1) {
    for (const group of groups) {
      const place = group[index];
      if (!place?.id || seenIds.has(place.id)) continue;
      seenIds.add(place.id);
      merged.push(place);
      if (merged.length >= maxCount) break;
    }
  }

  return merged;
}

// Isochrone外周を等間隔にサンプリングし、ジャンル検索の中心点として使う。
function getBoundarySearchPoints(coordinates, count) {
  if (!Array.isArray(coordinates) || !Number.isInteger(count) || count < 1) {
    return [];
  }

  const validCoordinates = coordinates.filter((coordinate) =>
    Array.isArray(coordinate) &&
    Number.isFinite(coordinate[0]) &&
    Number.isFinite(coordinate[1])
  );
  if (validCoordinates.length === 0) return [];

  // GeoJSON Polygonは先頭と末尾が同一点なので、重複サンプルを避ける。
  const first = validCoordinates[0];
  const last = validCoordinates[validCoordinates.length - 1];
  const openRing = validCoordinates.length > 1 && first[0] === last[0] && first[1] === last[1]
    ? validCoordinates.slice(0, -1)
    : validCoordinates;
  const pointCount = Math.min(count, openRing.length);

  return Array.from({ length: pointCount }, (_, index) => {
    const coordinateIndex = Math.floor(index * openRing.length / pointCount);
    return { lng: openRing[coordinateIndex][0], lat: openRing[coordinateIndex][1] };
  });
}

// Fisher-Yatesシャッフル。Googleは毎回同じ順(有名さ順)で返すので、提案に変化をつける。
// 元の配列は変更せずコピーを返す
function shufflePlaces(places) {
  const shuffled = [...places];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

// 提案する候補の選抜: 訪問済みを除外してからランダムに maxCount 件選ぶ。
// 未訪問だけで足りないときは訪問済みから補充する(候補ゼロで返すより再訪提案の方が親切)
function pickSuggestions(places, visitedPlaceIds, maxCount) {
  const visited = new Set(visitedPlaceIds);
  const unvisited = places.filter((place) => !visited.has(place.id));
  const revisitable = places.filter((place) => visited.has(place.id));

  const picked = shufflePlaces(unvisited).slice(0, maxCount);
  if (picked.length < maxCount) {
    picked.push(...shufflePlaces(revisitable).slice(0, maxCount - picked.length));
  }
  return picked;
}

// 各placeに所要時間(秒)と距離(m)を貼り付けた新しい配列を返す。対応する値が無い場合は null
function attachDurations(places, durations, distances = []) {

  return places.map((place, index) => {

    return {
      ...place,
      durationSec: durations[index] ?? null,
      distanceM: distances[index] ?? null
    };
  });
}

// 指定時間±10分を厳守する。所要時間不明の候補も条件を保証できないため除外する。
function filterWithinMinutes(places, minutes) {
  const minDurationSec = Math.max(0, minutes - sabunminutes) * 60;
  const maxDurationSec = (minutes + sabunminutes) * 60;
  return places.filter((place) =>
    Number.isFinite(place.durationSec) &&
    place.durationSec >= minDurationSec &&
    place.durationSec <= maxDurationSec
  );
}

function attachRoundTripMetrics(places, travelTimes, stayMinutes) {
  return places.map((place, index) => {
    const outboundDurationSec = travelTimes.outboundDurations[index] ?? null;
    const returnDurationSec = travelTimes.returnDurations[index] ?? null;
    const outboundDistanceM = travelTimes.outboundDistances[index] ?? null;
    const returnDistanceM = travelTimes.returnDistances[index] ?? null;
    const roundTripDurationSec = Number.isFinite(outboundDurationSec) && Number.isFinite(returnDurationSec)
      ? outboundDurationSec + returnDurationSec
      : null;
    const roundTripDistanceM = Number.isFinite(outboundDistanceM) && Number.isFinite(returnDistanceM)
      ? outboundDistanceM + returnDistanceM
      : null;
    const stayDurationSec = stayMinutes * 60;

    return {
      ...place,
      durationSec: outboundDurationSec,
      distanceM: outboundDistanceM,
      outboundDurationSec,
      returnDurationSec,
      roundTripDurationSec,
      stayDurationSec,
      totalDurationSec: roundTripDurationSec == null ? null : roundTripDurationSec + stayDurationSec,
      outboundDistanceM,
      returnDistanceM,
      roundTripDistanceM,
    };
  });
}

function filterWithinRoundTripMinutes(places, minutes) {
  const minDurationSec = Math.max(0, minutes - sabunminutes) * 60;
  const maxDurationSec = (minutes + sabunminutes) * 60;
  return places.filter((place) =>
    Number.isFinite(place.totalDurationSec) &&
    place.totalDurationSec >= minDurationSec &&
    place.totalDurationSec <= maxDurationSec
  );
}



module.exports = { getNearbyPlaces, getPlacePhoto, applyPlaceSearchFilter, normalizePlace, normalizePlacesResponse, mergeNormalizedPlaceGroups, getBoundarySearchPoints, shufflePlaces, pickSuggestions, attachDurations, filterWithinMinutes, attachRoundTripMetrics, filterWithinRoundTripMinutes };

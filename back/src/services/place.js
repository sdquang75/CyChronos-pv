//スポットだすやつにょー

const BASE_URL = "https://maps.googleapis.com"; // Google Maps APIのベースURL   
const hidecategory = ["lodging", "hotel", "parking", "gas_station", "atm", "bank", "hospital", "doctor", "pharmacy", "school", "primary_school", "secondary_school", "preschool", "university", "police", "fire_station", "post_office", "local_government_office"]

// 会社の支社・本社などは、Google側にtype(corporate_office等)が無く名前でしか
// 判別できないので、名前に含まれていたら外す(狙ったチェーン店の「支店」等は
// 対象外にしたいので、営業所/支店ではなくこの3語だけに絞る)
const hideNameKeywords = ["支社", "本社", "会社"]


/**
 * 指定範囲からいけそうなスポットを取得する
 * @param {number} radius 半径(m)
 * @param {string} type スポットの種類
 * @param {number} lng 経度
 * @param {number} lat 緯度
 */
async function getNearbyPlaces(lng, lat, radius, type) {

  // .env に置いた Google Places のAPIキーを読み込む
  const token = process.env.GOOGLE_PLACES_API_KEY;

  // Nearby Search のURLを組み立てる。location は「緯度,経度」の順（Mapboxと逆なので注意）
  const url = new URL(`${BASE_URL}/maps/api/place/nearbysearch/json`);
  url.searchParams.set("location", `${lat},${lng}`); // 検索の中心座標
  url.searchParams.set("radius", radius);            // 検索半径(m)
  if (type) {
    url.searchParams.set("type", type);              // 施設の種類
  }
  url.searchParams.set("language", "ja");            // 名前・住所を日本語で返させる(未指定だとローマ字になりがち)
  url.searchParams.set("key", token);                // APIキー

  const data = await fetchPlacesJson(url);
  const results = [...(data.results ?? [])];

  // Googleは1回につき最大20件・毎回同じ「有名さ順」しか返さない。
  // next_page_token で2ページ目(最大+20件)を取り、提案の母集団を増やす。
  // 3ページ目まで取ると更に+2秒かかるので、いまは2ページで止めている。
  if (data.next_page_token) {
    try {
      results.push(...(await fetchNextPage(data.next_page_token, token)));
    } catch (error) {
      // 2ページ目の失敗は致命傷ではないので、1ページ目だけで続行する
      console.error("Nearby Search 2ページ目の取得に失敗:", error.message);
    }
  }

  return { ...data, results };
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

  throw new Error(`Google Maps API error: ${data.status}`);
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
    genre: Array.isArray(place.types) && place.types.length > 0 ? place.types[0] : null,
  };
}

function normalizePlacesResponse(data) {
  return (data.results ?? [])
    .filter((place) => {
      const types = place.types ?? [];

      // typeを指定しない(「すべて」)検索だと、区・町名・郵便番号のような
      // 「場所」ではなく「行政区画/地名」自体がGoogleから返ってくる。
      // 実在の店舗・施設は必ず point_of_interest か establishment を持つので、
      // それが無いものは行き先として不適切とみなして外す
      const isRealPlace =
        types.includes("point_of_interest") || types.includes("establishment");

      // ホテルや駐車場、学校など、サイクリングの目的地として弱いものを外す
      const hasHiddenCategory = types.some((type) => hidecategory.includes(type));

      // 会社の支社・本社などオフィス系を名前で外す
      const hasHiddenNameKeyword = hideNameKeywords.some((keyword) =>
        place.name?.includes(keyword)
      );

      return isRealPlace && !hasHiddenCategory && !hasHiddenNameKeyword;
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

// 指定時間(片道扱い ※片道/往復は未決着)内に行ける場所だけ残す。null(到達不能)は落とす。
// durationSec フィールド自体が無い place は素通りさせる(Matrix失敗時に所要時間なしで続行するため)
function filterWithinMinutes(places, minutes){
  return places.filter((place) => {
    if (place.durationSec === null || place.durationSec > minutes * 60) {
      return false;
    }
    return true;
  });
}

module.exports = { getNearbyPlaces, normalizePlace, normalizePlacesResponse, shufflePlaces, pickSuggestions, attachDurations, filterWithinMinutes };

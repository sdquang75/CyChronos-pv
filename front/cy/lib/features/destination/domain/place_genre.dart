// Google Placesの英語ジャンル(type) → 画面表示用の日本語ラベルの変換表。
// Googleのtypeは200種類以上あり全網羅はできないので、実際にサイクリングの
// 目的地候補として返ってきやすいものを中心に収録している
// (見つからないtypeは _humanizeGenre() でフォールバックする)
const _genreLabels = {
  'cafe': 'カフェ',
  'restaurant': 'レストラン',
  'food': 'グルメ',
  'bakery': 'パン屋',
  'bar': 'バー',
  'meal_delivery': '宅配',
  'meal_takeaway': 'テイクアウト',
  'park': '公園',
  'museum': '美術館・博物館',
  'art_gallery': 'ギャラリー',
  'tourist_attraction': '観光名所',
  'place_of_worship': '寺社・教会',
  'hindu_temple': '寺院',
  'church': '教会',
  'mosque': 'モスク',
  'synagogue': 'シナゴーグ',
  'zoo': '動物園',
  'aquarium': '水族館',
  'amusement_park': '遊園地',
  'stadium': 'スタジアム',
  'bowling_alley': 'ボウリング場',
  'movie_theater': '映画館',
  'night_club': 'ナイトクラブ',
  'casino': 'カジノ',
  'spa': 'スパ',
  'gym': 'ジム',
  'beauty_salon': '美容室',
  'hair_care': 'ヘアサロン',
  'library': '図書館',
  'store': 'ショップ',
  'shopping_mall': 'ショッピングモール',
  'supermarket': 'スーパー',
  'convenience_store': 'コンビニ',
  'department_store': '百貨店',
  'clothing_store': '衣料品店',
  'shoe_store': '靴店',
  'jewelry_store': '宝石店',
  'book_store': '書店',
  'bicycle_store': '自転車店',
  'furniture_store': '家具店',
  'home_goods_store': '生活雑貨店',
  'hardware_store': '金物店',
  'electronics_store': '電気店',
  'florist': '花屋',
  'pet_store': 'ペットショップ',
  'liquor_store': '酒屋',
  'point_of_interest': '観光スポット',
  'establishment': '施設',
};

/// 変換表に無いGoogleのtypeを、せめて読める形にする
/// (例: "hair_care" → "Hair Care")。日本語訳が無い最後の保険
String _humanizeGenre(String genre) {
  return genre
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

/// 英語ジャンルを日本語表示用ラベルにする(変換表に無いものは読める形に整形する)
String placeGenreLabel(String genre) {
  if (genre.isEmpty) return '';
  return _genreLabels[genre] ?? _humanizeGenre(genre);
}

// Real /api/suggest results carry a raw English Google Places type in
// 'genre' (e.g. "cafe"), while the mock list packs multiple Japanese labels
// into one string (e.g. "自然 / 公園") — split and translate both shapes into
// the same tag vocabulary genre chips, destination card badges, and route
// confirm waypoint badges all use, so they always reflect what the data
// actually says instead of a fixed guess (or literal placeholders like
// "A"/"B"/"C").
List<String> destinationTags(Map<String, String> destination) {
  final raw = destination['genre'] ?? '';
  if (raw.isEmpty) return const [];
  final parts = raw.contains('/')
      ? raw.split('/').map((part) => part.trim()).where((part) => part.isNotEmpty)
      : [raw];
  return parts.map(placeGenreLabel).where((label) => label.isNotEmpty).toList();
}

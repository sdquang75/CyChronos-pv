// Google Placesの英語ジャンル(type) → 画面表示用の日本語ラベルの変換表
const _genreLabels = {
  'cafe': 'カフェ',
  'restaurant': 'レストラン',
  'food': 'グルメ',
  'park': '公園',
  'museum': '美術館・博物館',
  'tourist_attraction': '観光名所',
  'place_of_worship': '寺社・教会',
  'store': 'ショップ',
  'point_of_interest': '観光スポット',
  'establishment': '施設',
};

/// 英語ジャンルを日本語表示用ラベルにする(変換表に無いものはそのまま返す)
String placeGenreLabel(String genre) {
  if (genre.isEmpty) return '';
  return _genreLabels[genre] ?? genre;
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

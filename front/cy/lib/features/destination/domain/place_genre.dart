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

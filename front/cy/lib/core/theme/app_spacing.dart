// アプリ全体で使う余白の基準値。画面ごとにバラバラな数値(14, 16, 18, 20, 24...)を
// 書く代わりにこのスケールから選ぶことで、余白の付け方が揃う。
// (既存画面で実際に使われていた値をそのまま採用しているので、見た目は変えていない)
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// カード・ボタンの標準の角丸(見出しカード、情報カードなど)
  static const double radiusCard = 20;

  /// バッジ・チップ・完全な丸ボタンの角丸
  static const double radiusPill = 9999;

  /// 入力欄・小さめのカードの角丸
  static const double radiusInput = 12;
}

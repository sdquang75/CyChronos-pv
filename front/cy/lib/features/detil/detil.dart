import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_top_bar.dart';
import '../route_confirm/route_confirm.dart';

// Google Placesの英語ジャンル(type) → 画面表示用の日本語ラベルの変換表
const Map<String, String> _genreLabels = {
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

class DetilScreen extends StatelessWidget {
  final String name;
  final String address;
  final String genre; // Google Placesの英語ジャンル(例: cafe)。表示時に日本語へ変換する
  final String? imageUrl; // スポット写真のURL(写真が無いときは null = 仮画像を表示)
  final int? durationSec; // 現在地からの所要時間(秒)。不明なら null
  final int? distanceMeter; // 現在地からの距離(m)。不明なら null
  final double? rating; // Googleの星評価(例: 4.2)。評価なしは null
  final Map<String, dynamic> destination; // 目的地1件分の元データ(ルート確認画面へそのまま引き継ぐ)

  const DetilScreen({
    super.key,
    required this.name,
    required this.address,
    required this.genre,
    this.imageUrl, // 写真URLを受け取る(省略可)
    this.durationSec, // 所要時間を受け取る(省略可)
    this.distanceMeter, // 距離を受け取る(省略可)
    this.rating, // 評価を受け取る(省略可)
    this.destination = const {}, // 元データを受け取る(省略可)
  });

  // 英語ジャンルを日本語にして返す(変換表に無いものは英語のまま表示)
  String _genreLabel() {
    if (genre.isEmpty) return 'ジャンル';
    return _genreLabels[genre] ?? genre;
  }

  // 距離をkm表示用の文字列にする(小数3桁まで・末尾の0は削る)。不明なら「--」
  String _distanceText() {
    final meters = distanceMeter;
    if (meters == null) return '--';
    return (meters / 1000).toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  // 所要時間の文字列(例: 1時間15分 / 30分)。不明なら「--」
  String _durationText() {
    final sec = durationSec;
    if (sec == null) return '--';
    final hours = sec ~/ 3600;
    final minutes = (sec % 3600) ~/ 60;
    if (hours == 0) return '$minutes分';
    return '$hours時間$minutes分';
  }

  // スポット写真を表示する。URLが無いとき・読み込みに失敗したときは仮画像に切り替える
  Widget _buildPhoto() {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return Image.asset('assets/testimage.png', fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      // 読み込み中はインジケーターを出す
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      // 通信失敗でも画面を壊さず仮画像を出す
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/testimage.png', fit: BoxFit.cover);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppScreenFrame・下部メニューバーはHomeScreen(IndexedStackシェル)側で
    // 一括して描画されるので、ここでは自分の中身だけを組み立てる。
    // 共有の浮動メニューバーに本文が隠れないよう、下端の余白だけ確保しておく
    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(title: 'スポット詳細'),
            Expanded(
              child: SingleChildScrollView(
                // 縦に長い画面なので、小さい端末でもスクロールして全部見られるようにする
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg + AppBottomNavigation.barHeightFor(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // スポット写真
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCard,
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 220,
                        color: AppColors.accentBg, // 画像読み込み中の背景色
                        child: _buildPhoto(),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 名前・ジャンル・評価
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : '観光地名',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBg,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _genreLabel(),
                                  style: AppTypography.label.copyWith(
                                    fontFamily: 'HankenGrotesk',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: AppColors.starGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating != null
                                    ? rating!.toStringAsFixed(1)
                                    : '評価なし',
                                style: AppTypography.body,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 住所・距離・所要時間
                    AppCard(
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: '住所',
                            value: address.isNotEmpty ? address : '住所不明',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(
                            icon: Icons.directions_bike_rounded,
                            label: '距離',
                            value: '${_distanceText()}km',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: '所要時間',
                            value: _durationText(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    AppButton(
                      label: 'ルートを見る',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // 目的地データを丸ごと渡してルート確認画面へ
                        // (RideFlowの入れ子Navigatorでpushするので「戻る」でここに帰れる)
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => RouteConfirmScreen(
                                  destination: destination,
                                ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    AppButton(
                      label: 'お気に入り登録',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.favorite_border_rounded,
                      // TODO: お気に入り機能は未実装
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 住所・距離・所要時間の1行分(アイコン + ラベル + 値)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 72,
          child: Text(label, style: AppTypography.label),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

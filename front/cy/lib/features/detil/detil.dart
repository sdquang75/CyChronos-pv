import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/tap_scale.dart';
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

/// スポット詳細画面 (Apple Mapsのミニマリズム思想に基づく洗練された詳細ビュー).
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
    this.imageUrl,
    this.durationSec,
    this.distanceMeter,
    this.rating,
    this.destination = const {},
  });

  String _genreLabel() {
    if (genre.isEmpty) return 'ジャンル';
    return _genreLabels[genre] ?? genre;
  }

  String _distanceText() {
    final meters = distanceMeter;
    if (meters == null) return '--';
    return (meters / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  String _durationText() {
    final sec = durationSec;
    if (sec == null) return '--';
    final hours = sec ~/ 3600;
    final minutes = (sec % 3600) ~/ 60;
    if (hours == 0) return '$minutes分';
    return '$hours時間$minutes分';
  }

  Widget _buildPhoto() {
    final url = imageUrl;
    final Widget imageWidget = (url == null || url.isEmpty)
        ? Image.asset('assets/testimage.png', fit: BoxFit.cover)
        : Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/testimage.png', fit: BoxFit.cover);
            },
          );

    final tag = 'destination-photo-${destination['id'] ?? destination['name']}';
    return Hero(tag: tag, child: imageWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(title: 'スポット詳細'),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24 + AppBottomNavigation.barHeightFor(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // スポット写真 (Apple-style 24px radius with subtle border)
                    Container(
                      width: double.infinity,
                      height: 220,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.accentBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildPhoto(),
                    ),

                    const SizedBox(height: 16),

                    // 名前・ジャンル・評価
                    AppCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : '観光地名',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBg,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  _genreLabel(),
                                  style: const TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontFamilyFallback: ['NotoSansJP'],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.starGold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppColors.starGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating != null
                                          ? rating!.toStringAsFixed(1)
                                          : '評価なし',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrainsMono',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 住所・距離・所要時間 (Apple Inset Grouped style)
                    AppCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          _AppleInfoRow(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFF007AFF),
                            iconBgColor: const Color(0xFF007AFF).withValues(alpha: 0.12),
                            label: '住所',
                            value: address.isNotEmpty ? address : '住所不明',
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          _AppleInfoRow(
                            icon: Icons.directions_bike_rounded,
                            iconColor: const Color(0xFF34C759),
                            iconBgColor: const Color(0xFF34C759).withValues(alpha: 0.12),
                            label: '距離',
                            value: '${_distanceText()}km',
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          _AppleInfoRow(
                            icon: Icons.schedule_rounded,
                            iconColor: const Color(0xFFFF9500),
                            iconBgColor: const Color(0xFFFF9500).withValues(alpha: 0.12),
                            label: '所要時間',
                            value: _durationText(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    TapScale(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RouteConfirmScreen(
                              destination: destination,
                            ),
                          ),
                        );
                      },
                      child: AppButton(
                        label: 'ルートを見る',
                        icon: Icons.navigation_rounded,
                        height: 52,
                        borderRadius: 18,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RouteConfirmScreen(
                                destination: destination,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    AppButton(
                      label: 'お気に入り登録',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.favorite_border_rounded,
                      height: 48,
                      borderRadius: 16,
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

// Apple iOS Maps-style clean info row
class _AppleInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;

  const _AppleInfoRow({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/place_photo.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_screen_frame.dart';

class DestinationListScreen extends StatelessWidget {
  final List<dynamic> places;
  final int? minutes; // 検索に使った空き時間(分)。ヘッダーの表示用

  const DestinationListScreen({super.key, required this.places, this.minutes});

  // 空き時間を「X時間YY分」の形にする(受け取れなかったときは「--」)
  String _freeTimeText() {
    final total = minutes;
    if (total == null) return '--';
    final h = total ~/ 60;
    final m = (total % 60).toString().padLeft(2, '0');
    return '$h時間$m分';
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Stack(
          children: [
            Positioned.fill(
              bottom: AppBottomNavigation.barHeight,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildLogo(),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),

                            const SizedBox(height: 20),

                            Expanded(child: _buildDestinationList()),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              text: '情報変更',
                              icon: Icons.tune_rounded,
                              isPrimary: false,
                              onPressed: () {
                                _showMessage(context, '情報変更画面は後で実装します');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              text: '再提案',
                              icon: Icons.refresh_rounded,
                              isPrimary: true,
                              onPressed: () {
                                _showMessage(context, '再提案機能は後で実装します');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 共通の画面下部メニューバー(HOME・HISTORY・SETTINGS)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppBottomNavigation.barHeight,
              child: AppBottomNavigation(current: AppTab.home),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Center(
        child: Image.asset(
          'assets/logo_long.png',
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'おすすめスポット',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
            height: 1.25,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          '条件に合った目的地を選びましょう。',
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF484553),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EBFF),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: const Color(0xFF19005C).withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          // 空き時間の値が動的になったので Row 全体の const は外す
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Color(0xFF19005C),
              ),
              const SizedBox(width: 8),
              const Text(
                '空き時間',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF484553),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _freeTimeText(), // ホーム画面で入力した空き時間を表示
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF19005C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationList() {
    if (places.isEmpty) {
      return const _EmptyDestinationView();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final rawDestination = places[index];

        if (rawDestination is! Map) {
          return const SizedBox.shrink();
        }

        final destination = Map<String, dynamic>.from(rawDestination);

        return _DestinationCard(destination: destination);
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
          ),
        ),
        backgroundColor: const Color(0xFF2A0088),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  // /api/suggest の places 1件分
  //
  // 主な項目:
  // id
  // name
  // address
  // genre
  // lat
  // lng
  // durationSec
  // durationMinutes
  // distanceM
  final Map<String, dynamic> destination;

  const _DestinationCard({required this.destination});

  // カードのサムネイル。写真があればバック経由の実写真、なければロゴを出す
  Widget _buildThumbnail() {
    // サムネイルは小さいので幅200pxで十分(通信量とGoogle課金の節約)
    final photoUrl = placePhotoUrl(
      destination['photoReference']?.toString(),
      maxwidth: 200,
    );

    if (photoUrl == null) {
      return Image.asset('assets/logo.png', fit: BoxFit.cover);
    }
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      // 通信失敗でも画面を壊さずロゴに切り替える
      errorBuilder:
          (context, error, stackTrace) =>
              Image.asset('assets/logo.png', fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic rawDuration = destination['durationMinutes'];

    final int? durationMinutes =
        rawDuration is num
            ? rawDuration.round()
            : int.tryParse(rawDuration?.toString() ?? '');

    final String durationText =
        durationMinutes != null ? '約$durationMinutes分' : '所要時間不明';

    // 「詳細を見る」に限らず、カードのどこをタップしても詳細画面へ移動する
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openDetail(context),
      child: _buildCard(context, durationText),
    );
  }

  // 選択した目的地データをGoRouterのextraで詳細画面側へ渡す
  void _openDetail(BuildContext context) {
    context.push('/detil', extra: destination);
  }

  Widget _buildCard(BuildContext context, String durationText) {
    final String name = destination['name']?.toString() ?? '名称不明';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC9C4D5).withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC9C4D5).withValues(alpha: 0.35),
              ),
            ),
            child: _buildThumbnail(), // スポットの実写真(なければロゴ)
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF19005C),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EBFF),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: const Color(
                              0xFF19005C,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bike_rounded,
                              size: 15,
                              color: Color(0xFF19005C),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                durationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Color(0xFF19005C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openDetail(context),
                        borderRadius: BorderRadius.circular(9999),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '詳細を見る',
                                style: TextStyle(
                                  fontFamily: 'HankenGrotesk',
                                  fontFamilyFallback: ['NotoSansJP'],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF19005C),
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Color(0xFF19005C),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDestinationView extends StatelessWidget {
  const _EmptyDestinationView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC9C4D5).withValues(alpha: 0.35),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 42,
              color: Color(0xFF19005C),
            ),
            SizedBox(height: 16),
            Text(
              '目的地が見つかりませんでした',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF19005C),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '時間やジャンルを変更して、もう一度お試しください。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF484553),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary ? const Color(0xFF19005C) : Colors.white;

    final foregroundColor = isPrimary ? Colors.white : const Color(0xFF19005C);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: const Color(0xFF19005C), width: 1.5),
            boxShadow:
                isPrimary
                    ? [
                      BoxShadow(
                        color: const Color(0xFF19005C).withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 7),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: const ['NotoSansJP'],
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

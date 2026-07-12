import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class DestinationListScreen extends StatelessWidget {
  final List<dynamic> places;

  const DestinationListScreen({
    super.key,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 390 || size.height > 1115;

    final Widget content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 88.92,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildLogo(),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),

                          const SizedBox(height: 20),

                          Expanded(
                            child: _buildDestinationList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            text: '情報変更',
                            icon: Icons.tune_rounded,
                            isPrimary: false,
                            onPressed: () {
                              _showMessage(
                                context,
                                '情報変更画面は後で実装します',
                              );
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
                              _showMessage(
                                context,
                                '再提案機能は後で実装します',
                              );
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

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 88.92,
            child: _BottomNavigation(),
          ),
        ],
      ),
    );

    // HOME画面と同じPC表示用スマホフレーム
    if (isLargeScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF191C1F),
        body: Center(
          child: Container(
            width: 390,
            height: 1115,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        20,
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EBFF),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: const Color(0xFF19005C).withValues(
                alpha: 0.18,
              ),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Color(0xFF19005C),
              ),
              SizedBox(width: 8),
              Text(
                '空き時間',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF484553),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '1時間00分',
                style: TextStyle(
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
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 8,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final rawDestination = places[index];

        if (rawDestination is! Map) {
          return const SizedBox.shrink();
        }

        final destination = Map<String, dynamic>.from(
          rawDestination,
        );

        return _DestinationCard(
          destination: destination,
        );
      },
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  const _DestinationCard({
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        destination['name']?.toString() ?? '名称不明';

    final dynamic rawDuration =
        destination['durationMinutes'];

    final int? durationMinutes = rawDuration is num
        ? rawDuration.round()
        : int.tryParse(
            rawDuration?.toString() ?? '',
          );

    final String durationText = durationMinutes != null
        ? '約$durationMinutes分'
        : '所要時間不明';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC9C4D5).withValues(
            alpha: 0.35,
          ),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(
              alpha: 0.04,
            ),
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
                color: const Color(0xFFC9C4D5).withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: Image.asset(
              // logo.jpg は存在しない(pubspec未登録)ため、実在する logo.png に修正
              'assets/logo.png',
              fit: BoxFit.cover,
            ),
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
                          borderRadius: BorderRadius.circular(
                            9999,
                          ),
                          border: Border.all(
                            color: const Color(0xFF19005C)
                                .withValues(
                              alpha: 0.15,
                            ),
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
                        onTap: () {
                          // 選択した目的地データを
                          // GoRouterのextraで詳細画面側へ渡す
                          context.push(
                            '/detil',
                            extra: destination,
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          9999,
                        ),
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
                                  fontFamilyFallback: [
                                    'NotoSansJP',
                                  ],
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
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC9C4D5).withValues(
              alpha: 0.35,
            ),
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
    final backgroundColor = isPrimary
        ? const Color(0xFF19005C)
        : Colors.white;

    final foregroundColor = isPrimary
        ? Colors.white
        : const Color(0xFF19005C);

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
            border: Border.all(
              color: const Color(0xFF19005C),
              width: 1.5,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF19005C)
                          .withValues(
                        alpha: 0.18,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 7),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: const [
                    'NotoSansJP',
                  ],
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

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  void _showComingSoon(
    BuildContext context,
    String screenName,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$screenNameへの移動は後で実装します',
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
          ),
        ),
        backgroundColor: const Color(0xFF2A0088),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE).withValues(
              alpha: 0.8,
            ),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC9C4D5).withValues(
                  alpha: 0.3,
                ),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 20,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                label: 'HOME',
                svgData: _kHomeTabSvg,
                isSelected: true,
                onTap: () {
                  context.go('/home');
                },
              ),
              _BottomNavItem(
                label: 'HISTORY',
                svgData: _kHistoryTabSvg,
                onTap: () {
                  _showComingSoon(
                    context,
                    '履歴画面',
                  );
                },
              ),
              _BottomNavItem(
                label: 'SETTINGS',
                icon: Icons.settings_outlined,
                onTap: () {
                  _showComingSoon(
                    context,
                    '設定画面',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? svgData;
  final IconData? icon;
  final bool isSelected;

  const _BottomNavItem({
    required this.label,
    required this.onTap,
    this.svgData,
    this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? const Color(0xFF19005C)
        : const Color(0xFF484553);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 70,
        // 枠に収まらないときだけ自動で縮小し、はみ出しを防ぐ
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 24,
                child: icon != null
                    ? Icon(
                        icon,
                        color: color,
                        size: 25,
                      )
                    : SvgPicture.string(
                        svgData!,
                        colorFilter: ColorFilter.mode(
                          color,
                          BlendMode.srcIn,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _kHomeTabSvg = '''
<svg viewBox="0 0 24 24" fill="none"
    xmlns="http://www.w3.org/2000/svg">
  <path
    d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"/>
  <path
    d="M9 22V12h6v10"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"/>
</svg>
''';

const _kHistoryTabSvg = '''
<svg viewBox="0 0 24 24" fill="none"
    xmlns="http://www.w3.org/2000/svg">
  <circle
    cx="12"
    cy="12"
    r="10"
    stroke="currentColor"
    stroke-width="2"/>
  <path
    d="M12 6V12L16 14"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"/>
</svg>
''';
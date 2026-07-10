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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 330,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      34,
                      18,
                      0,
                    ),
                    child: Image.asset(
                      'assets/logo_long.png',
                      width: 200,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black54,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'おすすめスポット',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Row(
                              children: [
                                Text(
                                  '空き時間：',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '1',
                                  style: TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '時間',
                                  style: TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '00',
                                  style: TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '分',
                                  style: TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Expanded(
                              child: places.isEmpty
                                  ? const Center(
                                      child: Text(
                                        '目的地が見つかりませんでした',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: places.length,
                                      itemBuilder: (context, index) {
                                        final rawDestination =
                                            places[index];

                                        if (rawDestination is! Map) {
                                          return const SizedBox.shrink();
                                        }

                                        final destination =
                                            Map<String, dynamic>.from(
                                          rawDestination,
                                        );

                                        return _DestinationCard(
                                          destination: destination,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        text: '情報変更',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '情報変更画面は後で実装します',
                              ),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        text: '再提案',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '再提案機能は後で実装します',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const _BottomNavigation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  // /api/suggest の places 1件分
  // { id, name, lat, lng, address, rating, genre }
  final Map<String, dynamic> destination;

  const _DestinationCard({
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        destination['name']?.toString() ?? '名称不明';

    final String address =
        destination['address']?.toString() ?? '';

    final dynamic rating = destination['rating'];

    final String genre =
        destination['genre']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black54,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black54,
              ),
              color: Colors.white,
            ),
            child: ClipRRect(
              child: Image.asset(
                'assets/logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black45,
                    ),
                  ),
                  child: Text(
                    address.isNotEmpty
                        ? address
                        : '住所情報なし',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black45,
                    ),
                  ),
                  child: Text(
                    rating != null
                        ? '$genre ★$rating'
                        : genre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 38,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF3B00D9),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF3B00D9),
            fontSize: 16,
            fontWeight: FontWeight.bold,
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
    return SizedBox(
      height: 88.92,
      child: ClipRRect(
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.onTap,
    this.svgData,
    this.icon,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? svgData;
  final IconData? icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? const Color(0xFF19005C)
        : const Color(0xFF484553);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 82,
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
                fontSize: 10,
                color: color,
              ),
            ),
          ],
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
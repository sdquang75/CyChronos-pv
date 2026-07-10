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
                                        final destination =
                                            places[index]
                                                as Map<String, dynamic>;

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

                  Container(
                    height: 1,
                    color: const Color(0xFF3B00D9),
                  ),

                  const SizedBox(height: 10),

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

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            svgPath: 'assets/home_nav.svg',
            routePath: '/home',
          ),
          _BottomNavItem(
            svgPath: 'assets/history_nav.svg',
            routePath: '/history',
          ),
          _BottomNavItem(
            svgPath: 'assets/settings_nav.svg',
            routePath: '/settings',
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String svgPath;
  final String routePath;

  const _BottomNavItem({
    required this.svgPath,
    required this.routePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(routePath);
      },
      child: SizedBox(
        width: 70,
        height: 50,
        child: SvgPicture.asset(
          svgPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
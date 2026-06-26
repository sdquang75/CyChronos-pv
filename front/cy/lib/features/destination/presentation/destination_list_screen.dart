import 'package:flutter/material.dart';

class DestinationListScreen extends StatefulWidget {
  const DestinationListScreen({super.key});

  @override
  State<DestinationListScreen> createState() => _DestinationListScreenState();
}

class _DestinationListScreenState extends State<DestinationListScreen> {
  String selectedGenre = 'すべて';

  final List<Map<String, String>> destinations = [
    {
      'title': '五月山公園',
      'info': '自転車で約45分',
      'genre': '自然 / 公園',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '川沿いカフェ',
      'info': '自転車で約25分',
      'genre': 'カフェ',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '大阪城公園',
      'info': '自転車で約30分',
      'genre': '観光 / 公園',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '箕面の滝',
      'info': '自転車で約60分',
      'genre': '自然 / 観光',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '中之島公園',
      'info': '自転車で約20分',
      'genre': '公園 / 観光',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '靱公園',
      'info': '自転車で約18分',
      'genre': '自然 / 公園',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '北浜カフェ',
      'info': '自転車で約22分',
      'genre': 'カフェ / 観光',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '淀川河川公園',
      'info': '自転車で約35分',
      'genre': '自然 / 公園',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '天王寺公園',
      'info': '自転車で約40分',
      'genre': '公園 / 観光',
      'image': 'assets/logo.jpg',
    },
    {
      'title': '街角ベーカリー',
      'info': '自転車で約15分',
      'genre': 'カフェ',
      'image': 'assets/logo.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = selectedGenre == 'すべて'
        ? destinations
        : destinations.where((destination) {
            return destination['genre']!.contains(selectedGenre);
          }).toList();

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
                    padding: const EdgeInsets.fromLTRB(18, 34, 18, 0),
                    child: Image.asset(
                      'assets/logo_long.png',
                      width: 200,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black54),
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
                                  style: TextStyle(fontSize: 11),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '時間',
                                  style: TextStyle(fontSize: 11),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '00',
                                  style: TextStyle(fontSize: 11),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '分',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 5,
                              runSpacing: 5,
                              children: ['すべて', '自然', 'カフェ', '観光', '公園']
                                  .map((genre) {
                                return _SmallChip(
                                  text: genre,
                                  selected: selectedGenre == genre,
                                  onTap: () {
                                    setState(() {
                                      selectedGenre = genre;
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 14),

                            Expanded(
                              child: filteredDestinations.isEmpty
                                  ? const Center(
                                      child: Text(
                                        '該当する目的地がありません',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: filteredDestinations.length,
                                      itemBuilder: (context, index) {
                                        return _DestinationCard(
                                          destination:
                                              filteredDestinations[index],
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
                              content: Text('情報変更画面は後で'),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        text: '再提案',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('再提案機能は後で'),
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

class _SmallChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SmallChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B00D9) : Colors.white,
          border: Border.all(color: const Color(0xFF3B00D9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : const Color(0xFF3B00D9),
          ),
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final Map<String, String> destination;

  const _DestinationCard({
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              color: Colors.white,
            ),
            child: ClipRRect(
              child: Image.asset(
                destination['image'] ?? 'assets/logo.jpg',
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
                  destination['title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black45),
                  ),
                  child: Text(
                    destination['info']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black45),
                  ),
                  child: Text(
                    destination['genre']!,
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
            icon: Icons.home_outlined,
            label: 'ホーム',
          ),
          _BottomNavItem(
            icon: Icons.calendar_month_outlined,
            label: '履歴',
          ),
          _BottomNavItem(
            icon: Icons.settings_outlined,
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomNavItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Color(0xFF1F004D),
          size: 25,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF1F004D),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'home_tab_header.dart';

// TAB: HISTORY ACTIVITIES SCREEN (MOCKUP)
class HistoryTabView extends StatelessWidget {
  const HistoryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeTabHeader(title: 'アクティビティ履歴', subtitle: 'これまでの走行記録'),
          const SizedBox(height: 24),
          const _HistoryItem(
            title: '週末のモーニングライド',
            date: '2026/05/24',
            distance: '22.4 km',
            time: '1:12:05',
            calories: '420 kcal',
          ),
          const SizedBox(height: 16),
          const _HistoryItem(
            title: '鎌倉寺院巡りサイクリング',
            date: '2026/05/17',
            distance: '15.8 km',
            time: '0:58:30',
            calories: '310 kcal',
          ),
          const SizedBox(height: 16),
          const _HistoryItem(
            title: '荒川サイクリングロード往復',
            date: '2026/05/10',
            distance: '45.0 km',
            time: '2:15:18',
            calories: '890 kcal',
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.title,
    required this.date,
    required this.distance,
    required this.time,
    required this.calories,
  });

  final String title;
  final String date;
  final String distance;
  final String time;
  final String calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC9C4D5).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF19005C),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: const Color(0xFF484553).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HistoryStat(label: '距離', value: distance),
              _HistoryStat(label: '時間', value: time),
              _HistoryStat(label: '消費カロリー', value: calories),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontSize: 12,
            color: const Color(0xFF484553).withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF191C1F),
          ),
        ),
      ],
    );
  }
}

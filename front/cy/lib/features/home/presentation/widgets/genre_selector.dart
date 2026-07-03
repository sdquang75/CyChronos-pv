import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';

// Wrap of genre/interest chips (Cafe/Nature/Food/...) with inline SVG icons.
class GenreSelector extends StatelessWidget {
  const GenreSelector({
    super.key,
    required this.selectedGenres,
    required this.onToggle,
  });

  final Set<String> selectedGenres;
  final ValueChanged<String> onToggle;

  static final _genres = [
    {'id': 'Cafe', 'label': 'カフェ', 'svg': AppIcons.cafe},
    {'id': 'Nature', 'label': '自然', 'svg': AppIcons.nature},
    {'id': 'Food', 'label': 'グルメ', 'svg': AppIcons.food},
    {'id': 'Temple', 'label': '寺院', 'svg': AppIcons.temple},
    {'id': 'Art', 'label': 'アート', 'svg': AppIcons.art},
    {'id': 'Viewpoint', 'label': '絶景', 'svg': AppIcons.viewpoint},
    {'id': 'Shop', 'label': 'ショッピング', 'svg': AppIcons.shop},
    {'id': 'Landmark', 'label': 'ランドマーク', 'svg': AppIcons.landmark},
    {'id': 'Hill', 'label': 'ヒルクライム', 'svg': AppIcons.hill},
    {'id': 'Park', 'label': '公園', 'svg': AppIcons.park},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INTEREST',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.7,
            color: Color(0xFF484553),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              _genres.map((genre) {
                final id = genre['id'] as String;
                final label = genre['label'] as String;
                final svgStr = genre['svg'] as String;
                final isSelected = selectedGenres.contains(id);

                return GestureDetector(
                  onTap: () => onToggle(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFF1EBFF)
                              : const Color(0xFFF2F3F8),
                      borderRadius: BorderRadius.circular(9999),
                      border:
                          isSelected
                              ? null
                              : Border.all(
                                color: const Color(0xFFC9C4D5),
                                width: 1,
                              ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          svgStr,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            isSelected
                                ? const Color(0xFF19005C)
                                : const Color(0xFF484553),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: ['NotoSansJP'],
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 16,
                            color:
                                isSelected
                                    ? const Color(0xFF19005C)
                                    : const Color(0xFF484553),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

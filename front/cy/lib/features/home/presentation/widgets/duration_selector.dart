import 'package:flutter/material.dart';

// Horizontal scrollable list of ride-duration chips (15-180 min).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onSelected,
  });

  final int selectedDuration;
  final ValueChanged<int> onSelected;

  static const _durations = [15, 30, 45, 60, 90, 120, 150, 180];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DURATION',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.7,
            color: Color(0xFF484553),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _durations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final dur = _durations[index];
              final isSelected = selectedDuration == dur;

              return Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                  builder: (context, value, child) {
                    final color =
                        Color.lerp(
                          const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                          const Color(0xFF19005C).withValues(alpha: 0.85),
                          value,
                        )!;
                    final textColor =
                        Color.lerp(
                          const Color(0xFF191C1F),
                          const Color(0xFFFFFFFF),
                          value,
                        )!;
                    final borderColor =
                        Color.lerp(
                          const Color(0xFFC9C4D5).withValues(alpha: 0.5),
                          const Color(0xFF19005C).withValues(alpha: 0.8),
                          value,
                        )!;

                    return GestureDetector(
                      onTap: () => onSelected(dur),
                      child: Container(
                        height: 66,
                        constraints: BoxConstraints(
                          minWidth: dur >= 100 ? 120 : 100,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            dur >= 60 ? '${dur ~/ 60}時間' : '$dur分',
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

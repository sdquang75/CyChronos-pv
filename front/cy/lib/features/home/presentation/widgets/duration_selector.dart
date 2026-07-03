import 'package:flutter/material.dart';

// Horizontal scrollable list of ride-duration chips.
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onSelected,
  });

  final int selectedDuration;
  final ValueChanged<int> onSelected;

  static const _durations = [
    (minutes: 30, label: '30分'),
    (minutes: 60, label: '1時間'),
    (minutes: 90, label: '1.5時間'),
    (minutes: 120, label: '2時間'),
    (minutes: 180, label: '3時間+'),
  ];

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
          height: 66,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _durations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = _durations[index];
              final isSelected = selectedDuration == entry.minutes;

              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                builder: (context, value, child) {
                  final backgroundColor =
                      Color.lerp(Colors.white, const Color(0xFF2A0088), value)!;
                  final textColor =
                      Color.lerp(const Color(0xFF191C1F), Colors.white, value)!;
                  final borderColor =
                      Color.lerp(
                        const Color(0xFFC9C4D5),
                        const Color(0xFF2A0088),
                        value,
                      )!;

                  return GestureDetector(
                    onTap: () => onSelected(entry.minutes),
                    child: Container(
                      height: 66,
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow:
                            isSelected
                                ? const []
                                : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2E0094,
                                    ).withValues(alpha: 0.02),
                                    blurRadius: 5,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                      ),
                      child: Center(
                        child: Text(
                          entry.label,
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: ['NotoSansJP'],
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

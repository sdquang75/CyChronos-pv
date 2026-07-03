import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_icons.dart';
import 'labeled_slider.dart';

// Expandable "詳細設定" card with cruising speed / rest duration / rest
// frequency sliders.
class AdvancedConfigCard extends StatelessWidget {
  const AdvancedConfigCard({
    super.key,
    required this.expanded,
    required this.onToggleExpanded,
    required this.speedKmh,
    required this.onSpeedChanged,
    required this.restMinutes,
    required this.onRestMinutesChanged,
    required this.restFreqMin,
    required this.onRestFreqChanged,
  });

  final bool expanded;
  final VoidCallback onToggleExpanded;
  final double speedKmh;
  final ValueChanged<double> onSpeedChanged;
  final double restMinutes;
  final ValueChanged<double> onRestMinutesChanged;
  final double restFreqMin;
  final ValueChanged<double> onRestFreqChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.string(
                            AppIcons.settings,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF19005C),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '詳細設定',
                            style: TextStyle(
                              fontFamily: 'HankenGrotesk',
                              fontFamilyFallback: ['NotoSansJP'],
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Color(0xFF19005C),
                            ),
                          ),
                        ],
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF484553),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '速度・休憩時間の設定',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontFamilyFallback: ['NotoSansJP'],
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF484553),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanding sliders area
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            clipBehavior: Clip.antiAlias,
            child:
                !expanded
                    ? const SizedBox.shrink()
                    : Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 32,
                      ),
                      child: Column(
                        children: [
                          const Divider(height: 1, color: Color(0x33C9C4D5)),
                          const SizedBox(height: 24),

                          // 巡航速度 (Cruising Speed)
                          LabeledSlider(
                            label: '巡航速度',
                            valueText: '${speedKmh.toStringAsFixed(1)} km/h',
                            value: speedKmh,
                            min: 10.0,
                            max: 30.0,
                            divisions: 20,
                            onChanged: onSpeedChanged,
                          ),
                          const SizedBox(height: 24),

                          // 休憩時間 (Rest Duration)
                          LabeledSlider(
                            label: '休憩時間',
                            valueText: '${restMinutes.toInt()} 分',
                            value: restMinutes,
                            min: 5.0,
                            max: 45.0,
                            divisions: 8,
                            onChanged: onRestMinutesChanged,
                          ),
                          const SizedBox(height: 24),

                          // 休憩頻度 (Rest Frequency)
                          LabeledSlider(
                            label: '休憩頻度',
                            valueText: '毎 ${restFreqMin.toInt()} 分',
                            value: restFreqMin,
                            min: 15.0,
                            max: 120.0,
                            divisions: 7,
                            onChanged: onRestFreqChanged,
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

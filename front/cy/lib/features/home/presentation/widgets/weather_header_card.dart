import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/weather_condition.dart';
import '../../domain/weather_state.dart';
import '../providers/weather_provider.dart';

// 現在地の天気カード(Open-Meteo、APIキー不要)。
// 上段にアイコン+気温/天気ラベル、区切り線の下に風速・湿度を表示する。
class WeatherHeaderCard extends ConsumerWidget {
  const WeatherHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherProvider);

    final condition = switch (state) {
      WeatherLoaded(:final data) => WeatherCondition.fromCode(data.weatherCode),
      _ => const WeatherCondition('晴れ', Icons.wb_sunny_rounded),
    };
    final temperatureText = switch (state) {
      WeatherLoaded(:final data) => '${data.temperatureC.round()}°C',
      _ => '--°C',
    };
    final windText = switch (state) {
      WeatherLoaded(:final data) => data.windSpeedKmh.round().toString(),
      _ => '--',
    };
    final humidityText = switch (state) {
      WeatherLoaded(:final data) => data.humidityPercent.toString(),
      _ => '--',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    state is WeatherLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                        : Icon(
                          condition.icon,
                          color: AppColors.primary,
                          size: 28,
                        ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        temperatureText,
                        style: const TextStyle(
                          fontFamily: 'HankenGrotesk',
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                          letterSpacing: -0.56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      condition.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontFamilyFallback: ['NotoSansJP'],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _WeatherStat(
                    icon: Icons.air_rounded,
                    label: '風速',
                    value: windText,
                    unit: 'km/h',
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _WeatherStat(
                    icon: Icons.water_drop_rounded,
                    label: '湿度',
                    value: humidityText,
                    unit: '%',
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

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w500,
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

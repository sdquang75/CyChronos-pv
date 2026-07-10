import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cy/core/theme/app_colors.dart';
import '../../domain/weather_condition.dart';
import '../../domain/weather_state.dart';
import '../providers/weather_provider.dart';

// Current weather summary card, backed by Open-Meteo (no API key required).
// Top row shows the condition icon + temperature/label; a divider then
// separates it from the wind/humidity stats row below.
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 83,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greenGradient.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: state is WeatherLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.greenIcon,
                        ),
                      )
                    : Icon(
                        condition.icon,
                        color: AppColors.greenIcon,
                        size: 44,
                      ),
              ),
              const SizedBox(width: 20),
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
                          fontSize: 48,
                          letterSpacing: -0.96,
                          color: AppColors.greenIcon,
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
                        fontSize: 24,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderMedium)),
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
                const SizedBox(width: 32),
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
            fontSize: 12,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.greenIcon),
              const SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
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

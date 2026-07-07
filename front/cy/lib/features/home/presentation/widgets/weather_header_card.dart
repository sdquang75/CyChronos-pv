import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/weather_condition.dart';
import '../../domain/weather_state.dart';
import '../providers/weather_provider.dart';

// Current weather summary card, backed by Open-Meteo (no API key required).
// Laid out as a single horizontal row (icon, temp/condition, stats) to keep
// the card's vertical footprint small.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5D0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0E4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: state is WeatherLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4F604E),
                        ),
                      ),
                    )
                  : Icon(
                      condition.icon,
                      color: const Color(0xFF4F604E),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  temperatureText,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    letterSpacing: -0.44,
                    color: Color(0xFF4F604E),
                  ),
                ),
                Text(
                  condition.label,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFC4C8C0),
              indent: 4,
              endIndent: 4,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _WeatherStat(
                        icon: Icons.air_rounded,
                        label: '風速',
                        value: windText,
                        unit: 'km/h',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
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
            ),
          ],
        ),
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
            color: Color(0xFF5F5E5A),
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
              Icon(icon, size: 13, color: const Color(0xFF5F5E5A)),
              const SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                        color: Color(0xFF1A1C1C),
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontFamily: 'HankenGrotesk',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFF1A1C1C),
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

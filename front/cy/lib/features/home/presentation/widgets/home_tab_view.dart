import 'package:flutter/material.dart';
import 'advanced_config_card.dart';
import 'floating_cta_button.dart';
import 'home_app_title.dart';
import 'weather_header_card.dart';

// TAB: HOME PLANNER SCREEN — top title, weather summary and the customize
// (stay duration / spare time / genre) card.
class HomeTabView extends StatelessWidget {
  const HomeTabView({
    super.key,
    required this.scrollController,
    required this.stayDurationMinutes,
    required this.onStayDurationChanged,
    required this.spareTimeMinutes,
    required this.onSpareTimeChanged,
    required this.selectedGenreId,
    required this.onGenreChanged,
    required this.onFindDestination,
  });

  final ScrollController scrollController;
  final String stayDurationMinutes;
  final ValueChanged<String?> onStayDurationChanged;
  final String spareTimeMinutes;
  final ValueChanged<String?> onSpareTimeChanged;
  final String? selectedGenreId;
  final ValueChanged<String?> onGenreChanged;
  final VoidCallback onFindDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCF8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33D5E8D1), Color(0x00D5E8D1)],
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 100, // Space for the fixed Bottom Bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomeAppTitle(),
            const SizedBox(height: 20),
            const WeatherHeaderCard(),
            const SizedBox(height: 12),
            AdvancedConfigCard(
              stayDurationMinutes: stayDurationMinutes,
              onStayDurationChanged: onStayDurationChanged,
              spareTimeMinutes: spareTimeMinutes,
              onSpareTimeChanged: onSpareTimeChanged,
              selectedGenreId: selectedGenreId,
              onGenreChanged: onGenreChanged,
            ),
            const SizedBox(height: 20),
            FloatingCtaButton(onTap: onFindDestination),
          ],
        ),
      ),
    );
  }
}

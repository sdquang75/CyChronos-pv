import 'package:flutter/material.dart';
import 'advanced_config_card.dart';
import 'duration_selector.dart';
import 'genre_selector.dart';
import 'home_hero_header.dart';

// TAB: HOME PLANNER SCREEN — composes the hero header, duration/genre
// selectors and the advanced config card.
class HomeTabView extends StatelessWidget {
  const HomeTabView({
    super.key,
    required this.scrollController,
    required this.selectedDuration,
    required this.onDurationSelected,
    required this.selectedGenres,
    required this.onGenreToggled,
    required this.advancedExpanded,
    required this.onToggleAdvanced,
    required this.speedKmh,
    required this.onSpeedChanged,
    required this.restMinutes,
    required this.onRestMinutesChanged,
    required this.restFreqMin,
    required this.onRestFreqChanged,
  });

  final ScrollController scrollController;
  final int selectedDuration;
  final ValueChanged<int> onDurationSelected;
  final Set<String> selectedGenres;
  final ValueChanged<String> onGenreToggled;
  final bool advancedExpanded;
  final VoidCallback onToggleAdvanced;
  final double speedKmh;
  final ValueChanged<double> onSpeedChanged;
  final double restMinutes;
  final ValueChanged<double> onRestMinutesChanged;
  final double restFreqMin;
  final ValueChanged<double> onRestFreqChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 180, // Space for floating CTA & Bottom Bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeroHeader(),
          const SizedBox(height: 36),
          DurationSelector(
            selectedDuration: selectedDuration,
            onSelected: onDurationSelected,
          ),
          const SizedBox(height: 36),
          GenreSelector(
            selectedGenres: selectedGenres,
            onToggle: onGenreToggled,
          ),
          const SizedBox(height: 32),
          AdvancedConfigCard(
            expanded: advancedExpanded,
            onToggleExpanded: onToggleAdvanced,
            speedKmh: speedKmh,
            onSpeedChanged: onSpeedChanged,
            restMinutes: restMinutes,
            onRestMinutesChanged: onRestMinutesChanged,
            restFreqMin: restFreqMin,
            onRestFreqChanged: onRestFreqChanged,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'advanced_config_card.dart';
import 'floating_cta_button.dart';
import 'home_app_title.dart';
import 'weather_header_card.dart';

// TAB: HOME PLANNER SCREEN — top title, weather summary and the customize
// (stay duration / spare time / genre) card. Owns its own scroll position
// and customize-card selections so they survive being hidden behind the
// ExploreFlow's nested Navigator (e.g. when the destination list is pushed
// on top, or another bottom-nav tab is selected).
// ジャンルID(AdvancedConfigCardの選択肢) → Google Places の type
const _genreTypes = {
  'Cafe': 'cafe',
  'Nature': 'park',
  'Food': 'restaurant',
  'Temple': 'place_of_worship',
  'Art': 'museum',
  'Viewpoint': 'tourist_attraction',
  'Shop': 'store',
  'Landmark': 'tourist_attraction',
  'Hill': 'park',
  'Park': 'park',
};

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key, required this.onFindDestination});

  // 余裕時間(分)とGoogle Placesのtypeを渡して、目的地一覧を開く
  final void Function(int minutes, String type) onFindDestination;

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  final ScrollController _scrollController = ScrollController();

  String _stayDurationMinutes = '30';
  String _spareTimeMinutes = '30';
  String? _selectedGenreId;

  // 余裕時間は「往復の移動+滞在」をまかなう合計予算という前提で、滞在時間を
  // 引いた残りを2等分し、片道の移動時間としてバックエンドに渡す。
  // 滞在時間が余裕時間に近い/超えるほど選択でも、最低5分は確保する
  // (0分だとMapboxのisochroneが引けずAPIが400を返す)
  int get _travelMinutesEachWay {
    final spareTime = int.parse(_spareTimeMinutes);
    final stayDuration = int.parse(_stayDurationMinutes);
    final travelMinutes = ((spareTime - stayDuration) / 2).round();
    return travelMinutes < 5 ? 5 : travelMinutes;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgWarm,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.greenGradient.withValues(alpha: 0.2),
            AppColors.greenGradient.withValues(alpha: 0),
          ],
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
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
              stayDurationMinutes: _stayDurationMinutes,
              onStayDurationChanged: (id) => setState(
                () => _stayDurationMinutes = id ?? _stayDurationMinutes,
              ),
              spareTimeMinutes: _spareTimeMinutes,
              onSpareTimeChanged: (id) => setState(
                () => _spareTimeMinutes = id ?? _spareTimeMinutes,
              ),
              selectedGenreId: _selectedGenreId,
              onGenreChanged: (id) => setState(() => _selectedGenreId = id),
            ),
            const SizedBox(height: 20),
            FloatingCtaButton(
              onTap: () => widget.onFindDestination(
                _travelMinutesEachWay,
                // "すべて"(selectedGenreId == null)は絞り込みなし='' を送る。
                // 'cafe'固定にすると「すべて」を選んでもカフェしか出なくなる
                _genreTypes[_selectedGenreId] ?? '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

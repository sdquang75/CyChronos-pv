import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import 'package:cy/core/widgets/staggered_entrance.dart';
import 'package:cy/core/widgets/tap_scale.dart';
import 'package:cy/features/home/domain/recommendation_state.dart';
import 'package:cy/features/home/presentation/providers/recommendation_provider.dart';
import 'package:cy/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:cy/features/route_confirm/widgets/route_card_pieces.dart';

// Destination search & results screen, built directly from the Figma
// "Confirm Route" frame's Bottom Action Card: each result is that exact
// card shrunk down to just its Destination Summary row, and tapping it
// morphs the card open to reveal the Route Details metrics + "start"
// button — the same pieces RouteConfirmScreen uses.
class DestinationListScreen extends ConsumerStatefulWidget {
  const DestinationListScreen({super.key});

  @override
  ConsumerState<DestinationListScreen> createState() =>
      _DestinationListScreenState();
}

class _DestinationListScreenState
    extends ConsumerState<DestinationListScreen> {
  static const List<Map<String, String>> _destinations = [
    {
      'title': '五月山公園',
      'genre': '自然 / 公園',
      'duration': '45 min',
      'distance': '9.8 km',
      'elevation': '58 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '川沿いカフェ',
      'genre': 'カフェ',
      'duration': '25 min',
      'distance': '5.4 km',
      'elevation': '12 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '大阪城公園',
      'genre': '観光 / 公園',
      'duration': '30 min',
      'distance': '6.7 km',
      'elevation': '18 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '箕面の滝',
      'genre': '自然 / 観光',
      'duration': '60 min',
      'distance': '14.2 km',
      'elevation': '96 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '中之島公園',
      'genre': '公園 / 観光',
      'duration': '20 min',
      'distance': '4.1 km',
      'elevation': '6 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '靱公園',
      'genre': '自然 / 公園',
      'duration': '18 min',
      'distance': '3.5 km',
      'elevation': '4 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '北浜カフェ',
      'genre': 'カフェ / 観光',
      'duration': '22 min',
      'distance': '4.8 km',
      'elevation': '9 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '淀川河川公園',
      'genre': '自然 / 公園',
      'duration': '35 min',
      'distance': '8.0 km',
      'elevation': '10 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '天王寺公園',
      'genre': '公園 / 観光',
      'duration': '40 min',
      'distance': '9.1 km',
      'elevation': '22 m',
      'image': 'assets/testimage.png',
    },
    {
      'title': '街角ベーカリー',
      'genre': 'カフェ',
      'duration': '15 min',
      'distance': '2.9 km',
      'elevation': '3 m',
      'image': 'assets/testimage.png',
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedGenre = 'すべて';
  String _query = '';
  bool _isSearching = false;
  int _searchGeneration = 0;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    // Fetch real nearby recommendations as soon as this screen opens, so
    // the list can switch from the mock placeholder to live data without
    // requiring the user to press search first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider.notifier).fetchForCurrentLocation();
    });
  }

  // Prefers real backend recommendations when available; falls back to the
  // mock list otherwise (e.g. while loading, on error, or before the
  // endpoint is implemented) so the screen never looks empty.
  List<Map<String, String>> get _sourceDestinations {
    final recommendationState = ref.watch(recommendationProvider);
    final apiDestinations = recommendationState is RecommendationLoaded
        ? _parseApiDestinations(recommendationState.data)
        : const <Map<String, String>>[];
    return apiDestinations.isNotEmpty ? apiDestinations : _destinations;
  }

  List<Map<String, String>> get _filteredDestinations {
    final query = _query.trim();
    return _sourceDestinations.where((destination) {
      final matchesGenre =
          _selectedGenre == 'すべて' ||
          destination['genre']!.contains(_selectedGenre);
      final matchesQuery =
          query.isEmpty ||
          destination['title']!.contains(query) ||
          destination['genre']!.contains(query);
      return matchesGenre && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() {
      _isSearching = true;
      _expandedIndex = null;
    });
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchGeneration++;
    });
  }

  void _onGenreSelected(String genre) {
    if (genre == _selectedGenre) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedGenre = genre;
      _expandedIndex = null;
      _searchGeneration++;
    });
  }

  void _onCardToggled(int index) {
    HapticFeedback.selectionClick();
    setState(() => _expandedIndex = _expandedIndex == index ? null : index);
  }

  void _startRoute(Map<String, String> destination) {
    HapticFeedback.mediumImpact();
    context.push(
      '/route_confirm',
      extra: {
        'destinationName': destination['title'],
        'distanceText': destination['distance'],
        'durationText': destination['duration'],
        'elevationText': destination['elevation'],
        'thumbnailAsset': destination['image'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    final results = _filteredDestinations;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFDFCF8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33D5E8D1), Color(0x00D5E8D1)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const AppTopBar(title: 'おすすめスポット'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        children: [
                          _SearchBar(
                            controller: _searchController,
                            isSearching: _isSearching,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            onSubmit: _runSearch,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _genres.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final genre = _genres[index];
                                return _GenreChip(
                                  label: genre,
                                  selected: genre == _selectedGenre,
                                  onTap: () => _onGenreSelected(genre),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isSearching
                          ? const _SearchingIndicator()
                          : results.isEmpty
                          ? const _NoResults()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                4,
                                20,
                                120,
                              ),
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final destination = results[index];
                                return StaggeredEntrance(
                                  key: ValueKey(
                                    '$_searchGeneration-${destination['title']}',
                                  ),
                                  delay: Duration(milliseconds: 45 * index),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _DestinationRouteCard(
                                      destination: destination,
                                      isExpanded: _expandedIndex == index,
                                      onToggle: () => _onCardToggled(index),
                                      onStart: () => _startRoute(destination),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HomeBottomNavBar(
                currentIndex: 0,
                onTap: (_) => context.go('/home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _genres = ['すべて', '自然', 'カフェ', '観光', '公園'];

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5D0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF5F5E5A)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontSize: 15,
                color: Color(0xFF1B1C1C),
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'スポットを検索',
                hintStyle: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontSize: 15,
                  color: Color(0xFF5F5E5A),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: isSearching ? null : onSubmit,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A654E),
                  shape: BoxShape.circle,
                ),
                child: isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A654E) : const Color(0xFFDDE6DE),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: const ['NotoSansJP'],
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFF4A654E),
          ),
        ),
      ),
    );
  }
}

// Lenient mapping from the backend's (currently unconfirmed) recommendation
// payload shape into the same fields the mock data uses, so the card list
// can render real results as soon as the endpoint exists without needing
// another UI rewrite. Unrecognized/malformed entries are skipped; if none
// of the response parses, the caller falls back to the mock list.
List<Map<String, String>> _parseApiDestinations(dynamic data) {
  if (data is! List) return const [];

  final parsed = <Map<String, String>>[];
  for (final item in data) {
    if (item is! Map) continue;
    final title = item['title'] ?? item['name'];
    if (title == null) continue;
    parsed.add({
      'title': title.toString(),
      'genre': (item['genre'] ?? item['category'] ?? '').toString(),
      'duration': (item['duration'] ?? item['durationText'] ?? '').toString(),
      'distance': (item['distance'] ?? item['distanceText'] ?? '').toString(),
      'elevation': (item['elevation'] ?? item['elevationText'] ?? '')
          .toString(),
      'image':
          (item['image'] ?? item['thumbnailAsset'] ?? 'assets/testimage.png')
              .toString(),
    });
  }
  return parsed;
}

class _SearchingIndicator extends StatelessWidget {
  const _SearchingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF4A654E),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '該当する目的地がありません',
        style: TextStyle(
          fontFamily: 'HankenGrotesk',
          fontFamilyFallback: ['NotoSansJP'],
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF5F5E5A),
        ),
      ),
    );
  }
}

// The Figma "Bottom Action Card", shrunk to just its Destination Summary
// row when collapsed. Tapping it morphs the card open (AnimatedSize) to
// reveal the Route Details metrics + "start" button underneath — same
// pieces as RouteConfirmScreen's card, just embedded in a list.
class _DestinationRouteCard extends StatelessWidget {
  const _DestinationRouteCard({
    required this.destination,
    required this.isExpanded,
    required this.onToggle,
    required this.onStart,
  });

  final Map<String, String> destination;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD1D5D0)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF1B1C1C,
              ).withValues(alpha: isExpanded ? 0.06 : 0.03),
              blurRadius: isExpanded ? 16 : 8,
              offset: Offset(0, isExpanded ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Destination Summary" — always visible, this is the
            // "shrunk down" state of the card.
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: isExpanded ? 16 : 0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isExpanded
                        ? const Color(0xFFE4E2E1)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      destination['image']!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Wrap(
                          spacing: 2,
                          children: [
                            WaypointBadge(label: 'A'),
                            WaypointBadge(label: 'B'),
                            WaypointBadge(label: 'C'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination['title']!,
                          style: const TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: ['NotoSansJP'],
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Color(0xFF1B1C1C),
                            height: 24 / 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF5F5E5A),
                    ),
                  ),
                ],
              ),
            ),
            // "Route Details (Metrics)" + "Actions → Button" — revealed
            // when the card is tapped open.
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RouteMetric(
                                label: 'DISTANCE',
                                value: destination['distance']!,
                              ),
                              const MetricDivider(),
                              RouteMetric(
                                label: 'TIME',
                                value: destination['duration']!,
                              ),
                              const MetricDivider(),
                              RouteMetric(
                                label: 'ELEVATION',
                                value: destination['elevation']!,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        RouteStartButton(onTap: onStart),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cy/core/network/place_photo.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import 'package:cy/core/widgets/staggered_entrance.dart';
import 'package:cy/core/widgets/tap_scale.dart';
import 'package:cy/features/home/domain/recommendation_state.dart';
import 'package:cy/features/home/presentation/providers/recommendation_provider.dart';
import 'package:cy/features/route_confirm/route_confirm.dart';
import 'package:cy/features/route_confirm/widgets/route_card_pieces.dart';
import '../domain/place_genre.dart';
import 'destination_detail_screen.dart';

// Destination search & results screen, built directly from the Figma
// "Confirm Route" frame's Bottom Action Card: each result is that exact
// card shrunk down to just its Destination Summary row, and tapping it
// morphs the card open to reveal the Route Details metrics + "start"
// button — the same pieces RouteConfirmScreen uses.
class DestinationListScreen extends ConsumerStatefulWidget {
  const DestinationListScreen({
    super.key,
    this.minutes = 30,
    this.type = 'cafe',
  });

  // Search radius (spare time to travel) and Google Places type, threaded in
  // from the Home tab's customize card via ExploreFlow.
  final int minutes;
  final String type;

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
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '川沿いカフェ',
      'genre': 'カフェ',
      'duration': '25 min',
      'distance': '5.4 km',
      'elevation': '12 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '大阪城公園',
      'genre': '観光 / 公園',
      'duration': '30 min',
      'distance': '6.7 km',
      'elevation': '18 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '箕面の滝',
      'genre': '自然 / 観光',
      'duration': '60 min',
      'distance': '14.2 km',
      'elevation': '96 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '中之島公園',
      'genre': '公園 / 観光',
      'duration': '20 min',
      'distance': '4.1 km',
      'elevation': '6 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '靱公園',
      'genre': '自然 / 公園',
      'duration': '18 min',
      'distance': '3.5 km',
      'elevation': '4 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '北浜カフェ',
      'genre': 'カフェ / 観光',
      'duration': '22 min',
      'distance': '4.8 km',
      'elevation': '9 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '淀川河川公園',
      'genre': '自然 / 公園',
      'duration': '35 min',
      'distance': '8.0 km',
      'elevation': '10 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '天王寺公園',
      'genre': '公園 / 観光',
      'duration': '40 min',
      'distance': '9.1 km',
      'elevation': '22 m',
      'image': 'assets/kitty.jpeg',
    },
    {
      'title': '街角ベーカリー',
      'genre': 'カフェ',
      'duration': '15 min',
      'distance': '2.9 km',
      'elevation': '3 m',
      'image': 'assets/kitty.jpeg',
    },
  ];

  String _selectedGenre = 'すべて';
  int _searchGeneration = 0;
  int? _expandedIndex;

  // Keyed on the "start" button itself (not the card) — AnimatedSize's
  // *reported* size still animates from collapsed to expanded, so the card's
  // own RenderBox doesn't have its final height yet on the frame right after
  // toggling. The button, top-aligned inside AnimatedSize's child, is laid
  // out at its true final position on that very frame, so measuring it
  // (rather than the card) gives an accurate target without waiting for the
  // reveal animation to finish.
  final Map<int, GlobalKey> _startButtonKeys = {};

  GlobalKey _startButtonKeyFor(int index) =>
      _startButtonKeys.putIfAbsent(index, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    // Fetch real nearby recommendations as soon as this screen opens, so
    // the list can switch from the mock placeholder to live data without
    // requiring the user to press search first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider.notifier).fetchForCurrentLocation(
            minutes: widget.minutes,
            type: widget.type,
          );
    });
  }

  // True while the first /api/suggest request is still in flight — the mock
  // list must NOT be shown during this window, or it briefly looks like real
  // results before getting swapped out from under the user.
  bool get _isLoadingRecommendations {
    final state = ref.watch(recommendationProvider);
    return state is RecommendationLocating || state is RecommendationLoading;
  }

  // Prefers real backend recommendations when available; falls back to the
  // mock list otherwise (e.g. on error, permission denied, or before the
  // endpoint is implemented) so the screen never looks permanently empty.
  List<Map<String, String>> get _sourceDestinations {
    final recommendationState = ref.watch(recommendationProvider);
    final apiDestinations = recommendationState is RecommendationLoaded
        ? _parseApiDestinations(recommendationState.data)
        : const <Map<String, String>>[];
    return apiDestinations.isNotEmpty ? apiDestinations : _destinations;
  }

  // Genre chips are built from whatever tags the current result set
  // actually has, so they always match real data instead of a fixed guess
  // that may not exist among the results (or may hide real genres). Empty
  // while the first request is in flight, since _sourceDestinations would
  // otherwise fall back to the mock list's genres and flash chips that
  // don't match the real results about to replace them.
  List<String> get _availableGenres {
    if (_isLoadingRecommendations) return const [];
    final tags = <String>{};
    for (final destination in _sourceDestinations) {
      tags.addAll(destinationTags(destination));
    }
    final sorted = tags.toList()..sort();
    return ['すべて', ...sorted];
  }

  // Falls back to "すべて" if the previously-selected chip no longer exists
  // in the current result set (e.g. after a new search), rather than
  // silently filtering to zero results with no chip visibly selected.
  String get _effectiveSelectedGenre =>
      _availableGenres.contains(_selectedGenre) ? _selectedGenre : 'すべて';

  bool _matchesGenre(Map<String, String> destination) {
    final selected = _effectiveSelectedGenre;
    if (selected == 'すべて') return true;
    return destinationTags(destination).contains(selected);
  }

  List<Map<String, String>> get _filteredDestinations {
    return _sourceDestinations.where(_matchesGenre).toList();
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

  // The floating HomeBottomNavBar is a sibling overlay positioned on top of
  // this screen by HomeScreen's Stack, not part of this ListView's own
  // layout — so Scrollable.ensureVisible has no idea it covers roughly the
  // last ~120px of the viewport and will happily call the button "visible"
  // while it's still hidden underneath. Reserve that much clearance
  // ourselves when deciding how far to scroll.
  static const double _bottomNavClearance = 140;

  void _onCardToggled(int index) {
    HapticFeedback.selectionClick();
    final expanding = _expandedIndex != index;
    setState(() => _expandedIndex = expanding ? index : null);
    if (!expanding) return;

    // One frame after the toggle, the "start" button already exists at its
    // true final position (see _startButtonKeys' doc comment) — no need to
    // wait for the reveal animation to finish.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollStartButtonAboveNavBar(index);
    });
  }

  void _scrollStartButtonAboveNavBar(int index) {
    final buttonContext = _startButtonKeys[index]?.currentContext;
    if (buttonContext == null) return;
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    final scrollable = Scrollable.maybeOf(buttonContext);
    final scrollableBox =
        scrollable?.context.findRenderObject() as RenderBox?;
    if (buttonBox == null || scrollable == null || scrollableBox == null) {
      return;
    }

    // Button's bottom edge, measured relative to the scroll viewport.
    final buttonBottom = buttonBox
            .localToGlobal(Offset.zero, ancestor: scrollableBox)
            .dy +
        buttonBox.size.height;
    final visibleBottom =
        scrollable.position.viewportDimension - _bottomNavClearance;

    if (buttonBottom <= visibleBottom) return; // already clear of the nav bar

    final target = (scrollable.position.pixels + (buttonBottom - visibleBottom))
        .clamp(0.0, scrollable.position.maxScrollExtent);
    scrollable.position.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _openDetails(Map<String, String> destination) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DestinationDetailScreen(destination: destination),
      ),
    );
  }

  void _startRoute(Map<String, String> destination) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          final tags = destinationTags(destination);
          return RouteConfirmScreen(
            placeId: destination['id'],
            destinationName: destination['title'] ?? 'ABC park',
            waypointLabels: tags.isNotEmpty ? tags : const ['A', 'B', 'C'],
            distanceText: destination['distance'] ?? '12.4 km',
            durationText: destination['duration'] ?? '45 min',
            elevationText: destination['elevation'] ?? '42 m',
            thumbnailAsset: destination['image'] ?? 'assets/kitty.jpeg',
            destLat: double.tryParse(destination['lat'] ?? ''),
            destLng: double.tryParse(destination['lng'] ?? ''),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredDestinations;

    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(title: 'おすすめスポット'),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _isLoadingRecommendations
                  ? const SizedBox(height: 20, width: double.infinity)
                  : Padding(
                      key: const ValueKey('genre-chips'),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableGenres.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final genre = _availableGenres[index];
                            return _GenreChip(
                              label: genre,
                              selected: genre == _effectiveSelectedGenre,
                              onTap: () => _onGenreSelected(genre),
                            );
                          },
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: _isLoadingRecommendations
                  ? const _SearchingIndicator()
                  : results.isEmpty
                  ? const _NoResults()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
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
                              startButtonKey: _startButtonKeyFor(index),
                              onToggle: () => _onCardToggled(index),
                              onStart: () => _startRoute(destination),
                              onDetails: () => _openDetails(destination),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
          color: selected ? AppColors.greenPrimary : AppColors.greenChipBgLight,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: const ['NotoSansJP'],
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.greenPrimary,
          ),
        ),
      ),
    );
  }
}

// Maps a /api/suggest response ({ searchArea, places: [...] }) into the same
// fields the mock data uses, so the card list can render real results without
// another UI rewrite. Each place is { id, name, lat, lng, address, rating,
// genre, durationMinutes, distanceKm } (see back/src/routes/suggest.js).
// Unrecognized/malformed entries are skipped; if none of the response
// parses, the caller falls back to the mock list.
List<Map<String, String>> _parseApiDestinations(dynamic data) {
  final places = data is Map ? data['places'] : data;
  if (places is! List) return const [];

  final parsed = <Map<String, String>>[];
  for (final item in places) {
    if (item is! Map) continue;
    final title = item['name'] ?? item['title'];
    if (title == null) continue;
    final durationMinutes = item['durationMinutes'];
    final distanceKm = item['distanceKm'];
    parsed.add({
      'id': (item['id'] ?? '').toString(),
      'title': title.toString(),
      'genre': (item['genre'] ?? item['category'] ?? '').toString(),
      'duration': durationMinutes == null
          ? (item['duration'] ?? item['durationText'] ?? '').toString()
          : '$durationMinutes min',
      'distance': distanceKm == null
          ? (item['distance'] ?? item['distanceText'] ?? '').toString()
          : '$distanceKm km',
      'elevation': (item['elevation'] ?? item['elevationText'] ?? '')
          .toString(),
      'image':
          (item['image'] ?? item['thumbnailAsset'] ?? 'assets/kitty.jpeg')
              .toString(),
      'lat': (item['lat'] ?? '').toString(),
      'lng': (item['lng'] ?? '').toString(),
      'address': (item['address'] ?? '').toString(),
      'rating': (item['rating'] ?? '').toString(),
      'photoReference': (item['photoReference'] ?? '').toString(),
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
          color: AppColors.greenPrimary,
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
          color: AppColors.textMuted,
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
    required this.startButtonKey,
    required this.onToggle,
    required this.onStart,
    required this.onDetails,
  });

  final Map<String, String> destination;
  final bool isExpanded;
  // Lets the parent screen measure the button's true position the frame
  // it appears (see _DestinationListScreenState._startButtonKeys), to
  // auto-scroll it into view without waiting for the reveal to finish.
  final Key startButtonKey;
  final VoidCallback onToggle;
  final VoidCallback onStart;
  final VoidCallback onDetails;

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
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(
                alpha: isExpanded ? 0.06 : 0.03,
              ),
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
                        ? AppColors.dividerLight
                        : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _DestinationThumbnail(
                      photoReference: destination['photoReference'],
                      fallbackAsset: destination['image']!,
                      size: 64,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: destinationTags(destination)
                              .map((tag) => WaypointBadge(label: tag))
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination['title']!,
                          style: const TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: ['NotoSansJP'],
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppColors.textPrimary,
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
                      color: AppColors.textMuted,
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
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: onDetails,
                            icon: const Icon(Icons.info_outline_rounded, size: 16),
                            label: const Text('詳細を見る'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.greenPrimary,
                              textStyle: const TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontFamilyFallback: ['NotoSansJP'],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RouteStartButton(key: startButtonKey, onTap: onStart),
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

// Thumbnail shown on each destination card: a real spot photo via the
// backend's /api/maps/photo proxy when a photoReference is available,
// falling back to the mock/placeholder asset otherwise or on load failure.
class _DestinationThumbnail extends StatelessWidget {
  const _DestinationThumbnail({
    required this.photoReference,
    required this.fallbackAsset,
    required this.size,
  });

  final String? photoReference;
  final String fallbackAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = placePhotoUrl(photoReference, maxwidth: 200);
    if (photoUrl == null) {
      return Image.asset(fallbackAsset, width: size, height: size, fit: BoxFit.cover);
    }
    return Image.network(
      photoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(fallbackAsset, width: size, height: size, fit: BoxFit.cover),
    );
  }
}

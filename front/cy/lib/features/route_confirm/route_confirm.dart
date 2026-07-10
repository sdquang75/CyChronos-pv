import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import 'package:cy/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:cy/features/route_confirm/widgets/route_card_pieces.dart';

// "Confirm Route" screen — shown after a destination is picked (from
// DestinationListScreen / DetilScreen) so the rider can review the route
// summary before starting. Reuses the same green/HankenGrotesk design
// system and floating HomeBottomNavBar as the Home tab.
class RouteConfirmScreen extends StatelessWidget {
  const RouteConfirmScreen({
    super.key,
    this.destinationName = 'ABC park',
    this.waypointLabels = const ['A', 'B', 'C'],
    this.distanceText = '12.4 km',
    this.durationText = '45 min',
    this.elevationText = '42 m',
    this.thumbnailAsset = 'assets/testimage.png',
  });

  final String destinationName;
  final List<String> waypointLabels;
  final String distanceText;
  final String durationText;
  final String elevationText;
  final String thumbnailAsset;

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTopBar(title: 'Confirm Route'),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MapPreview(thumbnailAsset: thumbnailAsset),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                24,
                              ),
                              child: _RouteSummaryCard(
                                destinationName: destinationName,
                                waypointLabels: waypointLabels,
                                distanceText: distanceText,
                                durationText: durationText,
                                elevationText: elevationText,
                                thumbnailAsset: thumbnailAsset,
                              ),
                            ),
                          ],
                        ),
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

// "Canvas: Map View" — static route preview image (no map SDK is wired up
// yet in this project, so this follows the same AssetImage placeholder
// pattern already used by DetilScreen).
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.thumbnailAsset});

  final String thumbnailAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 202,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5D0)),
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(thumbnailAsset),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// "Bottom Action Card" — destination summary, distance/time/elevation
// metrics, and the primary "start" button.
class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.destinationName,
    required this.waypointLabels,
    required this.distanceText,
    required this.durationText,
    required this.elevationText,
    required this.thumbnailAsset,
  });

  final String destinationName;
  final List<String> waypointLabels;
  final String distanceText;
  final String durationText;
  final String elevationText;
  final String thumbnailAsset;

  void _handleStart(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Starting ride...',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
          ),
        ),
        backgroundColor: const Color(0xFF4A654E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5D0)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B1C1C).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE4E2E1))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    thumbnailAsset,
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
                      Wrap(
                        spacing: 2,
                        children: waypointLabels
                            .map((label) => WaypointBadge(label: label))
                            .toList(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        destinationName,
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RouteMetric(label: 'DISTANCE', value: distanceText),
                const MetricDivider(),
                RouteMetric(label: 'TIME', value: durationText),
                const MetricDivider(),
                RouteMetric(label: 'ELEVATION', value: elevationText),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RouteStartButton(onTap: () => _handleStart(context)),
        ],
      ),
    );
  }
}

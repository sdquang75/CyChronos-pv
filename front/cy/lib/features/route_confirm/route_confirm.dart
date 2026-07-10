import 'package:flutter/material.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import 'package:cy/features/route_confirm/widgets/route_card_pieces.dart';

// "Confirm Route" screen — shown after a destination is picked from
// DestinationListScreen, both pushed on the Explore tab's own nested
// Navigator (see ExploreFlow), so this sits on top of the shared
// AppScreenFrame/HomeBottomNavBar that HomeScreen already provides.
class RouteConfirmScreen extends StatelessWidget {
  const RouteConfirmScreen({
    super.key,
    this.placeId,
    this.destinationName = 'ABC park',
    this.waypointLabels = const ['A', 'B', 'C'],
    this.distanceText = '12.4 km',
    this.durationText = '45 min',
    this.elevationText = '42 m',
    this.thumbnailAsset = 'assets/testimage.png',
  });

  // Google place_id from DestinationListScreen's /api/suggest result. Null
  // for mock/placeholder destinations. Carried through so the "start" button
  // can record it as trip_history.destination_place_id.
  final String? placeId;
  final String destinationName;
  final List<String> waypointLabels;
  final String distanceText;
  final String durationText;
  final String elevationText;
  final String thumbnailAsset;

  @override
  Widget build(BuildContext context) {
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          border: Border.all(color: AppColors.borderLight),
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
        backgroundColor: AppColors.greenPrimary,
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
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
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
              border: Border(bottom: BorderSide(color: AppColors.dividerLight)),
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
                          color: AppColors.textPrimary,
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

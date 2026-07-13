import 'package:flutter/material.dart';
import 'package:cy/core/network/place_photo.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import 'package:cy/features/route_confirm/route_confirm.dart';
import 'package:cy/features/route_confirm/widgets/route_card_pieces.dart';
import '../domain/place_genre.dart';

// Destination detail screen — shown from a "詳細を見る" tap on the
// destination list's expanded card. Pushed on the Explore tab's own nested
// Navigator, same as RouteConfirmScreen, so it sits on top of the shared
// AppScreenFrame/HomeBottomNavBar HomeScreen already provides.
class DestinationDetailScreen extends StatelessWidget {
  const DestinationDetailScreen({super.key, required this.destination});

  // Same Map<String, String> shape _DestinationRouteCard/_startRoute use:
  // id, title, genre, duration, distance, image, lat, lng,
  // address, rating, photoReference.
  final Map<String, String> destination;

  String get _name =>
      destination['title']?.isNotEmpty == true ? destination['title']! : '観光地名';

  String get _address =>
      destination['address']?.isNotEmpty == true ? destination['address']! : '住所不明';

  String get _genreLabel {
    final genre = destination['genre'] ?? '';
    if (genre.isEmpty) return 'ジャンル';
    return placeGenreLabel(genre);
  }

  double? get _rating => double.tryParse(destination['rating'] ?? '');

  String? get _photoUrl => placePhotoUrl(destination['photoReference']);

  void _openRoute(BuildContext context) {
    final tags = destinationTags(destination);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteConfirmScreen(
          placeId: destination['id'],
          destinationName: destination['title'] ?? 'ABC park',
          waypointLabels: tags.isNotEmpty ? tags : const ['A', 'B', 'C'],
          distanceText: destination['distance'] ?? '12.4 km',
          durationText: destination['duration'] ?? '45 min',
          thumbnailAsset: destination['image'] ?? 'assets/kitty.jpeg',
          destLat: double.tryParse(destination['lat'] ?? ''),
          destLng: double.tryParse(destination['lng'] ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(
      child: Container(
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
              const AppTopBar(title: 'Spot Details'),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Photo(photoUrl: _photoUrl, thumbnailAsset: destination['image']),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontFamilyFallback: ['NotoSansJP'],
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Text(
                                    _genreLabel,
                                    style: const TextStyle(
                                      fontFamily: 'HankenGrotesk',
                                      fontFamilyFallback: ['NotoSansJP'],
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB300)),
                                const SizedBox(width: 2),
                                Text(
                                  _rating != null ? _rating!.toStringAsFixed(1) : '評価なし',
                                  style: const TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontFamilyFallback: ['NotoSansJP'],
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _address,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontFamilyFallback: ['NotoSansJP'],
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  RouteMetric(
                                    label: 'DISTANCE',
                                    value: destination['distance'] ?? '--',
                                  ),
                                  const MetricDivider(),
                                  RouteMetric(
                                    label: 'TIME',
                                    value: destination['duration'] ?? '--',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PinnedRouteActionButton(
                child: RouteStartButton(
                  label: 'ルートを見る',
                  icon: Icons.directions_bike_rounded,
                  onTap: () => _openRoute(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photoUrl, required this.thumbnailAsset});

  final String? photoUrl;
  final String? thumbnailAsset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          width: double.infinity,
          color: AppColors.terracottaChipBg,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => _fallbackImage(),
      );
    }
    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Image.asset(
      thumbnailAsset?.isNotEmpty == true ? thumbnailAsset! : 'assets/kitty.jpeg',
      fit: BoxFit.cover,
    );
  }
}

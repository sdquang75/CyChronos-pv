import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// LatLngだけ取り込む(このパッケージのPathクラスがFlutter標準のPathと名前衝突するため)
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'package:cy/core/widgets/app_top_bar.dart';
import 'package:cy/features/auth/domain/auth_state.dart';
import 'package:cy/features/auth/presentation/providers/auth_provider.dart';
import 'package:cy/features/home/data/location_service.dart';
import 'package:cy/features/route_confirm/data/route_repository.dart';
import 'package:cy/features/route_confirm/widgets/route_card_pieces.dart';

// "Confirm Route" screen — shown after a destination is picked from
// DestinationListScreen, both pushed on the Ride tab's own nested
// Navigator (see RideFlow), so this sits on top of the shared
// AppScreenFrame/HomeBottomNavBar that HomeScreen already provides.
class RouteConfirmScreen extends ConsumerStatefulWidget {
  const RouteConfirmScreen({
    super.key,
    this.placeId,
    this.destinationName = 'ABC park',
    this.waypointLabels = const ['A', 'B', 'C'],
    this.distanceText = '12.4 km',
    this.durationText = '45 min',
    this.thumbnailAsset = 'assets/kitty.jpeg',
    this.destLat,
    this.destLng,
  });

  // Google place_id from DestinationListScreen's /api/suggest result. Null
  // for mock/placeholder destinations. Carried through so the "start" button
  // can record it as trip_history.destination_place_id.
  final String? placeId;
  final String destinationName;
  final List<String> waypointLabels;

  // Fallback text shown before a real route loads (or if it never does —
  // e.g. no coordinates, offline, location denied). Once a real route is
  // fetched, distance/duration are recomputed from it.
  final String distanceText;
  final String durationText;
  final String thumbnailAsset;

  // Destination coordinates from the /api/suggest result. Null for
  // mock/placeholder destinations — in that case we skip the route API call
  // and just show the static thumbnail + estimate text, same as before.
  final double? destLat;
  final double? destLng;

  @override
  ConsumerState<RouteConfirmScreen> createState() => _RouteConfirmScreenState();
}

class _RouteConfirmScreenState extends ConsumerState<RouteConfirmScreen> {
  final LocationService _locationService = LocationService();
  final RouteRepository _repository = RouteRepository();

  CyclingRoute? _route; // 取得できた実ルート(null = 取得前 or 失敗)
  bool _loadingRoute = false;
  bool _busy = false; // 開始APIの二度押し防止

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  /// 現在地を取得して、バックの /api/maps/route で実際の走行ルートを取りに行く。
  /// 目的地の座標が無いとき(モックの目的地など)は何もせず概算値表示のまま
  Future<void> _loadRoute() async {
    final toLat = widget.destLat;
    final toLng = widget.destLng;
    if (toLat == null || toLng == null) return;

    setState(() => _loadingRoute = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final route = await _repository.fetchCyclingRoute(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: toLat,
        toLng: toLng,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _loadingRoute = false;
      });
    } catch (error) {
      // 位置情報が取れない・バック未起動などでも画面は壊さず、概算値表示のまま続行する
      debugPrint('route load error: $error');
      if (!mounted) return;
      setState(() => _loadingRoute = false);
    }
  }

  String get _distanceText {
    final meters = _route?.distanceM;
    if (meters == null) return widget.distanceText;
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String get _durationText {
    final sec = _route?.durationSec;
    if (sec == null) return widget.durationText;
    final minutes = (sec / 60).round();
    return '$minutes min';
  }

  Future<void> _handleStart() async {
    if (_busy) return;
    setState(() => _busy = true);

    final authState = ref.read(authProvider);
    final userId = authState is AuthAuthenticated
        ? authState.user.userId
        : null;

    ScaffoldMessenger.of(context).clearSnackBars();
    try {
      if (userId != null) {
        await _repository.startTrip(
          userId: userId,
          placeId: widget.placeId,
          destinationName: widget.destinationName,
        );
      }
      _showMessage('Starting ride...', AppColors.greenPrimary);
    } catch (error) {
      debugPrint('trip start error: $error');
      // 記録に失敗しても致命的ではないので、案内自体は始まったように見せる
      _showMessage('Starting ride...', AppColors.greenPrimary);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              const AppTopBar(title: 'Confirm Route'),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MapPreview(
                        thumbnailAsset: widget.thumbnailAsset,
                        loading: _loadingRoute,
                        route: _route,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.destinationName,
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
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.waypointLabels
                                  .map((label) => WaypointBadge(label: label))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: AppColors.borderLight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  RouteMetric(
                                    label: 'DISTANCE',
                                    value: _distanceText,
                                  ),
                                  const MetricDivider(),
                                  RouteMetric(
                                    label: 'TIME',
                                    value: _durationText,
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
                child: RouteStartButton(onTap: _busy ? () {} : _handleStart),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// "Canvas: Map View" — real route on an OpenStreetMap tile layer once a
// route has been fetched; falls back to the static thumbnail (loading,
// no coordinates, or fetch failure) so this never looks broken.
class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.thumbnailAsset,
    required this.loading,
    required this.route,
  });

  final String thumbnailAsset;
  final bool loading;
  final CyclingRoute? route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          width: double.infinity,
          color: AppColors.greenChipBg,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final points = route?.points;
    if (points != null && points.length >= 2) {
      return _RouteMap(points: points);
    }

    return Image(image: AssetImage(thumbnailAsset), fit: BoxFit.cover);
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.points});

  final List<List<double>> points; // [経度, 緯度] の並び

  @override
  Widget build(BuildContext context) {
    // ルートの [経度, 緯度] を地図ライブラリの LatLng(緯度, 経度) に変換(順番が逆なので注意)
    final routePoints = points.map((p) => LatLng(p[1], p[0])).toList();

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(routePoints),
          padding: const EdgeInsets.all(24),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cychronos.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: 4,
              color: AppColors.greenPrimary,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: routePoints.first,
              width: 16,
              height: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.greenPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
            Marker(
              point: routePoints.last,
              width: 32,
              height: 32,
              alignment: Alignment.topCenter,
              child: const Icon(
                Icons.location_pin,
                size: 32,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}

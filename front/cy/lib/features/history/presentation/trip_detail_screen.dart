import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_screen_frame.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../data/history_repository.dart';
import 'providers/history_provider.dart';

/// 走行記録の詳細画面。
/// GET /api/trips/:tripId から取得した locations (走行中のGPSログ)を
/// Google Maps 上に Polyline で描画し、走行距離・時間・平均速度を詳しく表示する。
/// 他の全画面と同様に AppScreenFrame でラップし、BlueStacksやPC環境でも
/// 統一されたスマホ枠(450x943)で表示される。
class TripDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> trip;
  final HistoryRepository? historyRepository;
  final bool useMapTiles;

  const TripDetailScreen({
    super.key,
    required this.trip,
    this.historyRepository,
    this.useMapTiles = true,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late final HistoryRepository _repository =
      widget.historyRepository ?? ref.read(historyRepositoryProvider);

  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _errorMessage;
  GoogleMapController? _mapController;

  int get _tripId => (widget.trip['trip_id'] as num).toInt();

  String get _name {
    final name = (_detail ?? widget.trip)['destination_name']?.toString() ?? '';
    return name.isNotEmpty ? name : '目的地未設定';
  }

  List<Map<String, dynamic>> get _locations {
    final raw = _detail?['locations'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((loc) => Map<String, dynamic>.from(loc))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final authState = ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;
    if (userId == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'ログイン情報が確認できませんでした。';
      });
      return;
    }

    try {
      final detail = await _repository.fetchTripDetail(
        userId: userId,
        tripId: _tripId,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetchTripDetail error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '詳細データの取得に失敗しました。';
      });
    }
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        title: const Text('走行記録の削除'),
        content: const Text('この走行記録を削除しますか？\n削除した記録は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(historyProvider.notifier).deleteTrip(tripId: _tripId);
      if (!mounted) return;
      if (success) {
        AppToast.show(context, '走行記録を削除しました');
        Navigator.of(context).pop();
      } else {
        AppToast.show(context, '削除に失敗しました。もう一度お試しください。');
      }
    }
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '--';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '--';
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/$month/$day $hour:$minute';
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '--';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '--';
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}/$month/$day';
  }

  String _formatDuration(dynamic rawSeconds) {
    if (rawSeconds is! num) return '--';
    final total = rawSeconds.round();
    final hours = total ~/ 3600;
    final minutes = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    if (hours == 0) return '$minutes:$secs';
    return '$hours:$minutes:$secs';
  }

  String _formatDistance(dynamic rawMeters) {
    if (rawMeters is! num) return '--';
    final km = (rawMeters / 1000).toStringAsFixed(1);
    return '$km km';
  }

  String _formatSpeed(dynamic rawSpeed) {
    if (rawSpeed is! num) return '--';
    return '${rawSpeed.toStringAsFixed(1)} km/h';
  }

  @override
  Widget build(BuildContext context) {
    final tripData = _detail ?? widget.trip;

    return AppScreenFrame(
      child: Scaffold(
        backgroundColor: AppColors.bgCool,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const AppTopBar(
                title: '走行記録の詳細',
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMapSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTitleCard(tripData),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMetricsCard(tripData),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        key: const ValueKey('bottom-delete-trip-button'),
                        label: 'この走行記録を削除する',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.delete_outline_rounded,
                        onPressed: _confirmDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    final locations = _locations;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : locations.isEmpty
                ? _buildEmptyMapPlaceholder()
                : _buildMapView(locations),
      ),
    );
  }

  Widget _buildEmptyMapPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 44,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '走行ログがありません',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage ?? 'このトリップのGPS座標ログは記録されていません。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<Map<String, dynamic>> locations) {
    final points = locations
        .map((l) => LatLng(
              (l['lat'] as num).toDouble(),
              (l['lng'] as num).toDouble(),
            ))
        .toList();

    if (!widget.useMapTiles) {
      return CustomPaint(
        painter: _RouteFallbackPainter(points: points),
        child: const SizedBox.expand(),
      );
    }

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: points.first, zoom: 14),
      onMapCreated: (controller) async {
        _mapController = controller;
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        if (points.length >= 2) {
          await controller.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 40),
          );
        }
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('actual_route'),
          points: points,
          width: 5,
          color: AppColors.primary,
        ),
      },
      markers: {
        Marker(
          markerId: const MarkerId('start'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: '出発地点'),
        ),
        Marker(
          markerId: const MarkerId('end'),
          position: points.last,
          infoWindow: const InfoWindow(title: '終了地点'),
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
    );
  }

  Widget _buildTitleCard(Map<String, dynamic> trip) {
    final dateText = _formatDate(trip['start_time']);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: AppTypography.label.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(Map<String, dynamic> trip) {
    final distanceText = _formatDistance(trip['total_distance_m']);
    final durationText = _formatDuration(trip['duration_sec']);
    final speedText = _formatSpeed(trip['average_speed_kmh']);
    final startText = _formatDateTime(trip['start_time']);
    final endText = _formatDateTime(trip['end_time']);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('距離', distanceText, Icons.straighten_rounded),
              ),
              Expanded(
                child: _buildStatItem('時間', durationText, Icons.timer_outlined),
              ),
              Expanded(
                child: _buildStatItem('平均速度', speedText, Icons.speed_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: AppColors.border.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(Icons.play_circle_outline_rounded, '出発日時', startText),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Icons.flag_outlined, '到着日時', endText),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RouteFallbackPainter extends CustomPainter {
  final List<LatLng> points;

  _RouteFallbackPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    var minX = points.first.longitude;
    var maxX = minX;
    var minY = points.first.latitude;
    var maxY = minY;

    for (final p in points) {
      if (p.longitude < minX) minX = p.longitude;
      if (p.longitude > maxX) maxX = p.longitude;
      if (p.latitude < minY) minY = p.latitude;
      if (p.latitude > maxY) maxY = p.latitude;
    }

    final spanX = math.max(1e-6, maxX - minX);
    final spanY = math.max(1e-6, maxY - minY);

    for (var i = 0; i < points.length; i++) {
      final normX = (points[i].longitude - minX) / spanX;
      final normY = 1.0 - ((points[i].latitude - minY) / spanY);
      final dx = 24 + normX * (size.width - 48);
      final dy = 24 + normY * (size.height - 48);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RouteFallbackPainter oldDelegate) =>
      oldDelegate.points != points;
}

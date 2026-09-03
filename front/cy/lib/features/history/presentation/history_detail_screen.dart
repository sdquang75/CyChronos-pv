import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// LatLngだけ取り込む(このパッケージのPathクラスがFlutter標準のPathと名前衝突するため)
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/widgets/app_screen_frame.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/history_repository.dart';

/// 走行履歴の詳細画面。
/// back/docs/API.md「3. ログ単体取得」(GET /api/trips/{trip_id})で
/// トリップ詳細と座標ログを取得し、実際に走った軌跡を地図に描く。
class HistoryDetailScreen extends ConsumerStatefulWidget {
  final int tripId;
  final HistoryRepository? repository; // テスト用に差し替え可(省略時は本物)
  final bool useMapTiles; // テスト時はfalse(タイル取得の通信ができないため)

  const HistoryDetailScreen({
    super.key,
    required this.tripId,
    this.repository,
    this.useMapTiles = true,
  });

  @override
  ConsumerState<HistoryDetailScreen> createState() =>
      _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  static const Color _primary = Color(0xFF19005C);
  static const Color _border = Color(0xFFC9C4D5);
  static const Color _sub = Color(0xFF484553);

  late final HistoryRepository _repository =
      widget.repository ?? HistoryRepository();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _trip;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  /// ログイン中ユーザーの user_id(バックエンド users テーブルのID)を取り出す
  int? _currentUserId() {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return null;
    return authState.user.userId;
  }

  Future<void> _loadTrip() async {
    final userId = _currentUserId();

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ユーザー情報を取得できませんでした。再度ログインしてください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trip = await _repository.fetchTripDetail(
        userId: userId,
        tripId: widget.tripId,
      );
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '走行記録を取得できませんでした。通信環境をご確認のうえ、もう一度お試しください。';
      });
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/history');
  }

  // ---- 表示用の文字列ヘルパー(履歴一覧のカードと表記を揃える)----

  String _titleText() {
    final name = _trip?['destination_name']?.toString() ?? '';
    return name.isNotEmpty ? name : '目的地未設定';
  }

  String _dateText() {
    final raw = _trip?['start_time']?.toString();
    if (raw == null) return '--';

    final dateTime = DateTime.tryParse(raw)?.toLocal();
    if (dateTime == null) return '--';

    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day $hour:$minute';
  }

  String _distanceText() {
    final meters = _trip?['total_distance_m'];
    if (meters is! num) return '--';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _durationText() {
    final seconds = _trip?['duration_sec'];
    if (seconds is! num) return '--';

    final total = seconds.round();
    final hours = total ~/ 3600;
    final minutes = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  String _speedText() {
    final speed = _trip?['average_speed_kmh'];
    if (speed is! num) return '--';
    return '${speed.toStringAsFixed(1)} km/h';
  }

  /// 座標ログを地図ライブラリの LatLng に変換する。
  /// 型が想定外の点は無視して、描ける点だけで軌跡を作る
  List<LatLng> _trackPoints() {
    final locations = _trip?['locations'];
    if (locations is! List) return const [];

    final points = <LatLng>[];
    for (final item in locations) {
      if (item is! Map) continue;
      final lat = item['lat'];
      final lng = item['lng'];
      if (lat is num && lng is num) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _goBack,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 23,
                    color: _primary,
                  ),
                ),
              ),
            ),
          ),
          Image.asset('assets/logo_long.png', width: 190, fit: BoxFit.contain),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6049C5)),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildMessage(
        icon: Icons.error_outline_rounded,
        title: '読み込みに失敗しました',
        message: _errorMessage!,
        onRetry: _loadTrip,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Text(
          _titleText(),
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: _primary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dateText(),
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: _sub.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        _buildTrack(),
        const SizedBox(height: 16),
        _buildStatsCard(),
      ],
    );
  }

  /// 走行軌跡。座標ログが2点未満のときは地図の代わりに理由を出す
  Widget _buildTrack() {
    final points = _trackPoints();

    if (points.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: _sub.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'この走行には軌跡が記録されていません',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: const ['NotoSansJP'],
                fontSize: 13,
                color: _sub.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 320,
        child:
            !widget.useMapTiles
                ? Container(color: const Color(0xFFE8E4F3))
                : FlutterMap(
                  options: MapOptions(
                    // 走行範囲全体が収まるようにカメラを合わせる
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(points),
                      padding: const EdgeInsets.all(32),
                    ),
                  ),
                  children: [
                    // 背景の地図タイル(OpenStreetMap。APIキー不要)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cychronos.app',
                    ),
                    // 実際に走った軌跡
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 5,
                          color: _primary,
                        ),
                      ],
                    ),
                    // スタート(青丸)とゴール(赤ピン)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: points.first,
                          width: 18,
                          height: 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A65D9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ),
                        Marker(
                          point: points.last,
                          width: 40,
                          height: 40,
                          // ピンの先端がゴール地点を指すように上へずらす
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Color(0xFFE23D3D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E0094).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStat('距離', _distanceText()),
          _buildStat('時間', _durationText()),
          _buildStat('平均速度', _speedText()),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: const ['NotoSansJP'],
            fontSize: 11,
            color: _sub.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _sub.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: const ['NotoSansJP'],
                fontSize: 13,
                color: _sub.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  '再読み込み',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

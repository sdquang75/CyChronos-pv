import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/network/place_photo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/app_top_bar.dart';
import '../auth/domain/auth_state.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../home/data/location_service.dart';
import 'data/route_repository.dart';

/// ルート確認・案内画面(Googleマップ風)。
/// 開くと全画面にルートが出て、下に情報バー(目的地・距離・時間・案内開始)が被さる。
/// 「案内開始」でバーが消えて全画面の案内モードになり、「案内を終了」で戻る
class RouteConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>
  destination; // 詳細画面から渡される目的地1件分(/api/suggest のplaces 1要素)
  final LocationService? locationService; // テスト用に差し替え可(省略時は本物)
  final RouteRepository? repository; // テスト用に差し替え可(省略時は本物)
  final bool useMapTiles; // テスト時はfalse(Google Maps SDKが動かないため簡易描画に切り替える)

  const RouteConfirmScreen({
    super.key,
    required this.destination,
    this.locationService,
    this.repository,
    this.useMapTiles = true,
  });

  @override
  ConsumerState<RouteConfirmScreen> createState() => _RouteConfirmScreenState();
}

class _RouteConfirmScreenState extends ConsumerState<RouteConfirmScreen> {
  late final LocationService _locationService =
      widget.locationService ?? LocationService();
  late final RouteRepository _repository =
      widget.repository ?? RouteRepository();

  CyclingRoute? _route; // 取得できた実ルート(null = 取得前 or 失敗)
  bool _loading = true; // ルート取得中かどうか
  String? _errorMessage; // 取得失敗時にユーザーへ見せる文言
  bool _navigating = false; // 案内モード中か(trueで下のバーが消えて全画面になる)
  bool _busy = false; // 開始/終了APIの二度押し防止
  int? _tripId; // 記録中トリップのID(null = 記録なし)

  // ---- destination(Map)から表示用の値を取り出すヘルパーたち ----

  String get _name => widget.destination['name']?.toString() ?? '目的地';

  String get _address => widget.destination['address']?.toString() ?? '';

  double? get _destLat => (widget.destination['lat'] as num?)?.toDouble();

  double? get _destLng => (widget.destination['lng'] as num?)?.toDouble();

  // 実ルートが取れなかったときは、候補一覧時点の概算値(Matrix API)で代用する
  double? get _displayDistanceM =>
      _route?.distanceM ??
      (widget.destination['distanceM'] as num?)?.toDouble();

  double? get _displayDurationSec =>
      _route?.durationSec ??
      (widget.destination['durationSec'] as num?)?.toDouble();

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  /// 現在地を取得して、バックの /api/maps/route で実際の走行ルートを取りに行く
  Future<void> _loadRoute() async {
    final toLat = _destLat;
    final toLng = _destLng;

    // 座標が受け取れていないときはAPIを呼ばず概算値表示に切り替える
    if (toLat == null || toLng == null) {
      setState(() {
        _loading = false;
        _errorMessage = '目的地の座標が受け取れませんでした';
      });
      return;
    }

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
        _loading = false;
      });
    } catch (error) {
      // 位置情報が取れない・バック未起動などでも画面は壊さず、概算値で続行する
      debugPrint('route load error: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'ルートを取得できませんでした(候補一覧時点の概算値を表示しています)';
      });
    }
  }

  /// 案内開始: 下のバーを消して全画面の案内モードへ。
  /// ログイン済みならトリップ開始も記録する(訪問済み除外が効くようになる)
  Future<void> _startNavigation() async {
    if (_busy) return; // 二度押しガード
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    // ログイン済みユーザーの user_id を取る(取れなければ記録なしで案内だけする)
    final authState = ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;

    try {
      if (userId != null) {
        final tripId = await _repository.startTrip(
          userId: userId,
          placeId: widget.destination['id']?.toString(),
          destinationName: _name,
        );
        _tripId = tripId;
      } else {
        _showMessage('ログイン情報が取得できないため、走行記録なしで案内します');
      }
    } catch (error) {
      // 記録に失敗しても案内自体は始める(記録はおまけ、案内が主目的)
      debugPrint('trip start error: $error');
      _showMessage('走行記録の開始に失敗しました(記録なしで案内します)');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _navigating = true; // 記録の成否に関わらず案内モードに入る
        });
      }
    }
  }

  /// 案内終了: バーを戻す。トリップ記録中ならバックに終了も記録する
  Future<void> _endNavigation() async {
    if (_busy) return; // 二度押しガード
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);

    final authState = ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;
    final tripId = _tripId;

    try {
      if (tripId != null && userId != null) {
        await _repository.endTrip(userId: userId, tripId: tripId);
        _tripId = null;
      } else {
        _showMessage('案内を終了しました');
      }
    } catch (error) {
      debugPrint('trip end error: $error');
      _showMessage('走行記録の終了に失敗しました');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _navigating = false; // バーを戻す
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    AppToast.show(context, message);
  }

  // ---- 表示用の文字列ヘルパー ----

  // 距離をkm表示の文字列にする(小数1桁)。不明なら「--」
  String _distanceText() {
    final meters = _displayDistanceM;
    if (meters == null) return '--';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  // 所要時間を「◯時間◯分」の文字列にする(1時間未満は「◯分」)。不明なら「--」
  String _durationText() {
    final sec = _displayDurationSec;
    if (sec == null) return '--';
    final hours = sec ~/ 3600;
    final minutes = (sec % 3600) ~/ 60;
    if (hours == 0) return '約$minutes分';
    return '約$hours時間$minutes分';
  }

  @override
  Widget build(BuildContext context) {
    // AppScreenFrameはHomeScreen(IndexedStackシェル)側で一括して描画されるので、
    // ここでは自分の中身だけを組み立てる
    return Scaffold(
      backgroundColor: AppColors.bgCool,
      // 案内モード中はヘッダーも消して全画面にする
      appBar:
          _navigating
              ? null
              : PreferredSize(
                preferredSize: Size.fromHeight(AppTopBar.heightFor(context)),
                child: const AppTopBar(title: 'ルート確認'),
              ),
      body: Stack(
          children: [
            // マップ代わりのルート表示(常に全画面。バーはこの上に被さる)
            Positioned.fill(child: _buildRoutePreview()),

            // ルート取得に失敗したときだけ、概算値表示であることを上部に知らせる
            if (_errorMessage != null && !_navigating)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

            // 案内モード中だけ上に出る「残り距離・時間」のチップ(Googleマップのあの表示)
            if (_navigating)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_distanceText()} ・ ${_durationText()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 下部: 通常時は情報バー、案内モード中は「案内を終了」ボタンだけ。
            // AnimatedSwitcherで切り替え時にスッと入れ替わる。
            // この画面はHomeScreen側の画面下部メニューバー(常に最前面に被さる)の
            // 上に重なって描画されるので、そのぶんだけ持ち上げてボタンが隠れないようにする
            Positioned(
              left: 0,
              right: 0,
              bottom: AppBottomNavigation.barHeightFor(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                // 下からスライドしてくる切り替えアニメーション
                transitionBuilder:
                    (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                child: _navigating ? _buildEndButton() : _buildInfoPanel(),
              ),
            ),
          ],
        ),
    );
  }

  /// マップ領域の中身: 取得中→インジケーター / 成功→ルート形状 / 失敗→目的地の写真
  Widget _buildRoutePreview() {
    if (_loading) {
      return Container(
        color: AppColors.accentBg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final route = _route;
    if (route != null && route.points.length >= 2) {
      // 本物の地図(Google Maps)の上にルートを重ねる。
      // テスト時は地図SDKが動かないので簡易描画(線だけ)に切り替える
      if (widget.useMapTiles) {
        return _buildMap(route);
      }
      return Container(
        color: AppColors.bgCool, // マップの下地の色
        child: CustomPaint(
          painter: _RoutePreviewPainter(points: route.points),
          child: const SizedBox.expand(),
        ),
      );
    }

    // ルートが描けないときは目的地の写真(なければ仮画像)を出しておく
    final photoUrl = placePhotoUrl(
      widget.destination['photoReference']?.toString(),
    );
    if (photoUrl == null) {
      return Image.asset('assets/testimage.png', fit: BoxFit.cover);
    }
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) =>
              Image.asset('assets/testimage.png', fit: BoxFit.cover),
    );
  }

  /// 本物の地図(Google Maps)にルートの線と出発・目的地のマーカーを重ねる
  Widget _buildMap(CyclingRoute route) {
    // ルートの [経度, 緯度] を地図SDKの LatLng(緯度, 経度) に変換(順番が逆なので注意)
    final routePoints =
        route.points.map((point) => LatLng(point[1], point[0])).toList();

    // ルート全体が収まる南西・北東の角を求める(カメラ合わせ用)
    var minLat = routePoints.first.latitude;
    var maxLat = minLat;
    var minLng = routePoints.first.longitude;
    var maxLng = minLng;
    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    return GoogleMap(
      initialCameraPosition:
          CameraPosition(target: routePoints.first, zoom: 13),
      // 下の情報バー・画面下部メニューバー・上のチップに隠れないよう、
      // 地図の見える中心を上下にずらす
      padding: EdgeInsets.only(
        top: 100,
        bottom: 260 + AppBottomNavigation.barHeightFor(context),
      ),
      onMapCreated: (controller) async {
        // 地図のレイアウト確定前にbounds指定すると失敗することがあるので少し待つ
        await Future.delayed(const Duration(milliseconds: 100));
        // 待っている間に画面が閉じられていたら、破棄済みの地図を触らない
        if (!mounted) return;
        // ルート全体が画面に収まるようにカメラを合わせる
        await controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 48));
      },
      // ルートの線
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          width: 5,
          color: AppColors.primary,
        ),
      },
      // 出発地(青)と目的地(赤=デフォルト)のマーカー
      markers: {
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: routePoints.last,
        ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  /// 通常時の下部バー: 目的地情報+距離・時間+ボタン(Googleマップの検索結果バー風)
  Widget _buildInfoPanel() {
    return Container(
      key: const ValueKey('info-panel'), // AnimatedSwitcherが切り替えを認識するための目印
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目的地の名前
          Text(
            _name,
            maxLines: 1, // 長い名前は1行に収めて…で省略する
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle.copyWith(fontSize: 22),
          ),
          // 住所(あるときだけ)
          if (_address.isNotEmpty)
            Text(
              _address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),

          // 距離と所要時間を1行で
          Row(
            children: [
              const Icon(
                Icons.directions_bike,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${_distanceText()} ・ ${_durationText()}',
                style: AppTypography.stat.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ボタン: 左=ルートを変更(戻る) / 右=案内開始
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'ルートを変更',
                  variant: AppButtonVariant.secondary,
                  height: 50,
                  borderRadius: AppSpacing.radiusInput,
                  onPressed: () {
                    // 詳細画面に戻って選び直せるようにする
                    // (RideFlowの入れ子Navigatorでpushされてきた画面なので、
                    // go_routerではなく素のNavigatorでpopする)
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: '案内開始',
                  height: 50,
                  borderRadius: AppSpacing.radiusInput,
                  onPressed: _busy ? null : _startNavigation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 案内モード中の下部: 「案内を終了」ボタンだけ(バーは消えて全画面)
  Widget _buildEndButton() {
    return Padding(
      key: const ValueKey('end-button'), // AnimatedSwitcherが切り替えを認識するための目印
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: _busy ? null : _endNavigation,
          icon: const Icon(Icons.close, color: Colors.white),
          label: const Text(
            '案内を終了',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger, // Googleマップの終了ボタンと同じ赤系
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
        ),
      ),
    );
  }
}

/// ルートの形を線で描くペインター(地図タイルは使わない簡易プレビュー)。
/// 出発地に丸、目的地にピンを打つ
class _RoutePreviewPainter extends CustomPainter {
  final List<List<double>> points; // [経度, 緯度] の並び

  const _RoutePreviewPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // ルート全体が収まる範囲(最小・最大の経度緯度)を求める
    double minLng = points.first[0], maxLng = points.first[0];
    double minLat = points.first[1], maxLat = points.first[1];
    for (final point in points) {
      if (point[0] < minLng) minLng = point[0];
      if (point[0] > maxLng) maxLng = point[0];
      if (point[1] < minLat) minLat = point[1];
      if (point[1] > maxLat) maxLat = point[1];
    }

    // 画面の余白ぶんを引いた描画領域に、縦横比を保ったまま収まる倍率を計算する
    const padding = 48.0; // 下部バーやチップと被りにくいよう広めに取る
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;
    // 完全な直線ルートで割り算がゼロにならないよう、ごく小さい値で下駄を履かせる
    final lngSpan = (maxLng - minLng).abs().clamp(1e-6, double.infinity);
    final latSpan = (maxLat - minLat).abs().clamp(1e-6, double.infinity);
    final scale =
        (drawWidth / lngSpan) < (drawHeight / latSpan)
            ? (drawWidth / lngSpan)
            : (drawHeight / latSpan);

    // 描いたルートが領域の真ん中に来るようにずらす量
    final offsetX = (size.width - lngSpan * scale) / 2;
    final offsetY = (size.height - latSpan * scale) / 2;

    // 経度緯度→画面座標に変換(緯度は北が上なのでY軸を反転する)
    Offset toOffset(List<double> point) {
      final x = (point[0] - minLng) * scale + offsetX;
      final y = size.height - ((point[1] - minLat) * scale + offsetY);
      return Offset(x, y);
    }

    // ルートの線を描く
    final path =
        Path()..moveTo(toOffset(points.first).dx, toOffset(points.first).dy);
    for (final point in points.skip(1)) {
      final offset = toOffset(point);
      path.lineTo(offset.dx, offset.dy);
    }
    final linePaint =
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 出発地(先頭の点)は丸
    canvas.drawCircle(
      toOffset(points.first),
      8,
      Paint()..color = const Color(0xFF2A65D9),
    );

    // 目的地(最後の点)は赤丸+白抜きでピンっぽく
    final goal = toOffset(points.last);
    canvas.drawCircle(goal, 10, Paint()..color = AppColors.danger);
    canvas.drawCircle(goal, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RoutePreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}

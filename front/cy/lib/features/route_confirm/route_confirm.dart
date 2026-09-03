import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/network/place_photo.dart';
import '../../core/widgets/app_screen_frame.dart';
import '../auth/domain/auth_state.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../home/data/location_service.dart';
import 'data/navigation_announcer.dart';
import 'data/route_repository.dart';
import 'domain/navigation_engine.dart';

enum _RouteStage {
  outboundPreview,
  outboundNavigating,
  staying,
  returnPreview,
  returnNavigating,
  completed,
}

/// ルート確認・案内画面(Googleマップ風)。
/// 開くと全画面にルートが出て、下に情報バー(目的地・距離・時間・案内開始)が被さる。
/// 「案内開始」でバーが消えて全画面の案内モードになり、「案内を終了」で戻る
class RouteConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>
  destination; // 詳細画面から渡される目的地1件分(/api/suggest のplaces 1要素)
  final LocationService? locationService; // テスト用に差し替え可(省略時は本物)
  final RouteRepository? repository; // テスト用に差し替え可(省略時は本物)
  final NavigationAnnouncer? announcer; // テスト時は端末TTSを呼ばない偽物へ差し替える
  final bool useMapTiles; // テスト時はfalse(Google Maps SDKが動かないため簡易描画に切り替える)
  final bool keepScreenAwake; // テスト時はfalseにしてプラットフォーム通信を避ける

  const RouteConfirmScreen({
    super.key,
    required this.destination,
    this.locationService,
    this.repository,
    this.announcer,
    this.useMapTiles = true,
    this.keepScreenAwake = true,
  });

  @override
  ConsumerState<RouteConfirmScreen> createState() => _RouteConfirmScreenState();
}

class _RouteConfirmScreenState extends ConsumerState<RouteConfirmScreen> {
  late final LocationService _locationService =
      widget.locationService ?? LocationService();
  late final RouteRepository _repository =
      widget.repository ?? RouteRepository();
  late final NavigationAnnouncer _announcer =
      widget.announcer ?? DeviceNavigationAnnouncer();

  CyclingRoute? _route; // 取得できた実ルート(null = 取得前 or 失敗)
  bool _loading = true; // ルート取得中かどうか
  String? _errorMessage; // 取得失敗時にユーザーへ見せる文言
  bool _busy = false; // 開始/終了APIの二度押し防止
  int? _tripId; // 記録中トリップのID(null = 記録なし)
  _RouteStage _stage = _RouteStage.outboundPreview;
  double? _originLat;
  double? _originLng;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _stayTimer;
  GoogleMapController? _mapController;
  NavigationEngine? _navigationEngine;
  NavigationSnapshot? _navigationSnapshot;
  Position? _currentPosition;
  String? _navigationStatusMessage;
  bool _voiceEnabled = true;
  bool _rerouting = false;
  bool _arrivalHandling = false;
  bool _completedOnReturn = false;
  bool _allowPop = false;
  bool _exitDialogVisible = false;
  int _offRouteSamples = 0;
  int _arrivalSamples = 0;
  int? _guidanceStepIndex;
  bool _announcedPrepare = false;
  bool _announcedNow = false;
  DateTime? _lastRerouteAt;
  DateTime? _routeFetchedAt;
  double? _routeFromLat;
  double? _routeFromLng;

  static const _arrivalRadiusM = 60.0;
  static const _offRouteRadiusM = 70.0;
  static const _rerouteCooldown = Duration(seconds: 60);
  static const _routeReuseWindow = Duration(minutes: 5);

  // ---- destination(Map)から表示用の値を取り出すヘルパーたち ----

  String get _name => widget.destination['name']?.toString() ?? '目的地';

  String get _address => widget.destination['address']?.toString() ?? '';

  double? get _destLat => (widget.destination['lat'] as num?)?.toDouble();

  double? get _destLng => (widget.destination['lng'] as num?)?.toDouble();

  bool get _isRoundTrip => widget.destination['tripMode'] == 'round_trip';

  int get _plannedStayMinutes =>
      (widget.destination['plannedStayMinutes'] as num?)?.round() ?? 0;

  bool get _isNavigating =>
      _stage == _RouteStage.outboundNavigating ||
      _stage == _RouteStage.returnNavigating;

  bool get _shouldGuardBack =>
      _busy ||
      _tripId != null ||
      _isNavigating ||
      _stage == _RouteStage.staying;

  bool get _isReturnRoute =>
      _stage == _RouteStage.returnPreview ||
      _stage == _RouteStage.returnNavigating ||
      (_stage == _RouteStage.completed && _completedOnReturn);

  double? get _targetLat => _isReturnRoute ? _originLat : _destLat;

  double? get _targetLng => _isReturnRoute ? _originLng : _destLng;

  NavigationStep? get _upcomingStep {
    final index = _navigationSnapshot?.upcomingStepIndex;
    final steps = _route?.steps;
    if (index == null || steps == null || index < 0 || index >= steps.length) {
      return null;
    }
    return steps[index];
  }

  // 実ルートが取れなかったときは、候補一覧時点の概算値(Matrix API)で代用する
  double? get _displayDistanceM =>
      (_isNavigating ? _navigationSnapshot?.remainingDistanceM : null) ??
      _route?.distanceM ??
      (widget.destination[_isReturnRoute ? 'returnDistanceM' : 'distanceM']
              as num?)
          ?.toDouble();

  double? get _displayDurationSec =>
      (_isNavigating ? _navigationSnapshot?.remainingDurationSec : null) ??
      _route?.durationSec ??
      (widget.destination[_isReturnRoute ? 'returnDurationSec' : 'durationSec']
              as num?)
          ?.toDouble();

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stayTimer?.cancel();
    _mapController?.dispose();
    unawaited(_announcer.stop());
    if (widget.keepScreenAwake) unawaited(WakelockPlus.disable());
    super.dispose();
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
      _originLat = position.latitude;
      _originLng = position.longitude;
      final route = await _repository.fetchCyclingRoute(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: toLat,
        toLng: toLng,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _routeFromLat = position.latitude;
        _routeFromLng = position.longitude;
        _routeFetchedAt = DateTime.now();
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

    if (_stage == _RouteStage.returnPreview) {
      await _startReturnNavigation();
      return;
    }

    setState(() => _busy = true);

    // プレビューを開いてから移動している可能性があるため、案内開始地点を取り直す。
    Position? navigationStartPosition;
    try {
      final position = await _locationService.getCurrentPosition();
      navigationStartPosition = position;
      final toLat = _destLat;
      final toLng = _destLng;
      if (toLat == null || toLng == null) {
        throw StateError('目的地の座標がありません');
      }
      final route =
          _canReuseRouteFrom(position)
              ? _route!
              : await _repository.fetchCyclingRoute(
                fromLat: position.latitude,
                fromLng: position.longitude,
                toLat: toLat,
                toLng: toLng,
              );
      if (!mounted) return;
      _originLat = position.latitude;
      _originLng = position.longitude;
      _currentPosition = position;
      _route = route;
      if (!_canReuseRouteFrom(position)) {
        _routeFromLat = position.latitude;
        _routeFromLng = position.longitude;
        _routeFetchedAt = DateTime.now();
      }
      _navigationEngine = NavigationEngine(route);
      _errorMessage = null;
    } catch (error) {
      debugPrint('route refresh on navigation start error: $error');
      // 経路の再取得だけ失敗しても、往復の帰着地点には実際に案内を始めた地点を使う。
      final position = navigationStartPosition;
      if (position != null) {
        _originLat = position.latitude;
        _originLng = position.longitude;
        _currentPosition = position;
      }
      if (_route == null || _originLat == null || _originLng == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _errorMessage = '案内開始地点からのルートを取得できませんでした。通信と位置情報を確認してください。';
        });
        return;
      }
      // 直前のプレビュー経路は残っているので、通信の一時失敗時だけそれを利用する。
      _navigationEngine = NavigationEngine(_route!);
      _navigationStatusMessage = '開始地点の再計算に失敗したため、表示中のルートで案内します。';
    }

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
        _showMessage('案内を開始しました。行ってらっしゃい!');
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
          _stage = _RouteStage.outboundNavigating;
        });
        await _activateNavigation();
      }
    }
  }

  Future<void> _startReturnNavigation() async {
    final originLat = _originLat;
    final originLng = _originLng;
    if (originLat == null || originLng == null) {
      _showMessage('出発地点を確認できないため、帰りの案内を開始できません。');
      return;
    }

    setState(() => _busy = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final reusedRoute = _canReuseRouteFrom(position);
      final route =
          reusedRoute
              ? _route!
              : await _repository.fetchCyclingRoute(
                fromLat: position.latitude,
                fromLng: position.longitude,
                toLat: originLat,
                toLng: originLng,
              );
      if (!mounted) return;
      setState(() {
        _route = route;
        if (!reusedRoute) {
          _routeFromLat = position.latitude;
          _routeFromLng = position.longitude;
          _routeFetchedAt = DateTime.now();
        }
        _currentPosition = position;
        _navigationEngine = NavigationEngine(route);
        _stage = _RouteStage.returnNavigating;
        _busy = false;
        _errorMessage = null;
      });
      await _activateNavigation();
    } catch (error) {
      debugPrint('return route refresh error: $error');
      if (!mounted) return;
      if (_route != null) {
        setState(() {
          _navigationEngine = NavigationEngine(_route!);
          _stage = _RouteStage.returnNavigating;
          _busy = false;
          _navigationStatusMessage = '現在地からの再計算に失敗したため、表示中の復路で案内します。';
        });
        await _activateNavigation();
      } else {
        setState(() {
          _busy = false;
          _errorMessage = '帰りのルートを取得できませんでした。通信と位置情報を確認してください。';
        });
      }
    }
  }

  Future<void> _activateNavigation() async {
    _offRouteSamples = 0;
    _arrivalSamples = 0;
    _arrivalHandling = false;
    _rerouting = false;
    _guidanceStepIndex = null;
    _announcedPrepare = false;
    _announcedNow = false;

    if (widget.keepScreenAwake) {
      try {
        await WakelockPlus.enable();
      } catch (error) {
        debugPrint('wakelock enable error: $error');
        if (mounted) {
          setState(() => _navigationStatusMessage = '画面の自動消灯を無効にできませんでした。');
        }
      }
    }
    _startPositionMonitoring();
    await _speak(
      _isReturnRoute
          ? '帰りの案内を開始します。安全を確認して出発してください。'
          : '案内を開始します。安全を確認して出発してください。',
    );
  }

  bool _canReuseRouteFrom(Position position) {
    final routeFromLat = _routeFromLat;
    final routeFromLng = _routeFromLng;
    final fetchedAt = _routeFetchedAt;
    if (_route == null ||
        routeFromLat == null ||
        routeFromLng == null ||
        fetchedAt == null ||
        DateTime.now().difference(fetchedAt) > _routeReuseWindow) {
      return false;
    }
    return Geolocator.distanceBetween(
          routeFromLat,
          routeFromLng,
          position.latitude,
          position.longitude,
        ) <=
        50;
  }

  void _startPositionMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen(
      _handlePosition,
      onError: (Object error) {
        debugPrint('arrival monitoring error: $error');
        if (!mounted || !_isNavigating) return;
        setState(() {
          _navigationStatusMessage = '現在地を更新できません。位置情報の設定を確認してください。';
        });
      },
    );
  }

  void _handlePosition(Position position) {
    if (!mounted || !_isNavigating || _arrivalHandling) return;
    final engine = _navigationEngine;
    if (engine == null) return;

    final snapshot = engine.update(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    setState(() {
      _currentPosition = position;
      _navigationSnapshot = snapshot;
      final status = _navigationStatusMessage;
      if (!_rerouting &&
          (status?.startsWith('ルートを再検索') == true ||
              status?.startsWith('現在地を更新') == true)) {
        _navigationStatusMessage = null;
      }
    });
    _followCurrentPosition(position);
    _handleGuidance(snapshot);
    _checkArrival(position);
    _checkRouteDeviation(position, snapshot);
  }

  void _followCurrentPosition(Position position) {
    final controller = _mapController;
    if (controller == null || !widget.useMapTiles) return;
    final bearing =
        position.heading.isFinite && position.heading >= 0
            ? position.heading
            : 0.0;
    unawaited(
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17,
            tilt: 45,
            bearing: bearing,
          ),
        ),
      ),
    );
  }

  void _handleGuidance(NavigationSnapshot snapshot) {
    final index = snapshot.upcomingStepIndex;
    final distance = snapshot.distanceToManeuverM;
    if (index == null || distance == null) return;

    if (_guidanceStepIndex != index) {
      _guidanceStepIndex = index;
      _announcedPrepare = false;
      _announcedNow = false;
    }
    final instruction = _upcomingStep?.instruction;
    if (instruction == null || instruction.isEmpty) return;

    if (distance <= 70 && !_announcedNow) {
      _announcedNow = true;
      unawaited(_speak('まもなく、$instruction', urgent: true));
    } else if (distance <= 300 && !_announcedPrepare) {
      _announcedPrepare = true;
      unawaited(_speak('${_spokenDistance(distance)}先、$instruction'));
    }
  }

  void _checkArrival(Position position) {
    final targetLat = _targetLat;
    final targetLng = _targetLng;
    if (targetLat == null || targetLng == null) return;
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLat,
      targetLng,
    );
    final accuracyAllowance = position.accuracy.clamp(0.0, 30.0);
    final arrived = distance <= _arrivalRadiusM + accuracyAllowance;
    _arrivalSamples = arrived ? _arrivalSamples + 1 : 0;
    // 高精度GPSなら停止した瞬間の1回で到着させ、低精度時だけ連続確認する。
    final requiredSamples = position.accuracy <= 20 ? 1 : 2;
    if (_arrivalSamples < requiredSamples) return;

    _arrivalHandling = true;
    if (_stage == _RouteStage.outboundNavigating && _isRoundTrip) {
      unawaited(_beginStay());
    } else {
      unawaited(_completeArrival());
    }
  }

  void _checkRouteDeviation(Position position, NavigationSnapshot snapshot) {
    if (_arrivalHandling || _rerouting) return;
    if (position.accuracy > 50) {
      _offRouteSamples = 0;
      return;
    }
    final threshold = math.max(_offRouteRadiusM, position.accuracy * 2);
    _offRouteSamples =
        snapshot.offRouteDistanceM > threshold ? _offRouteSamples + 1 : 0;
    if (_offRouteSamples < 3) return;

    final lastReroute = _lastRerouteAt;
    if (lastReroute != null &&
        DateTime.now().difference(lastReroute) < _rerouteCooldown) {
      return;
    }
    unawaited(_rerouteFrom(position));
  }

  Future<void> _rerouteFrom(Position position) async {
    if (_rerouting || !_isNavigating) return;
    final targetLat = _targetLat;
    final targetLng = _targetLng;
    if (targetLat == null || targetLng == null) return;

    setState(() {
      _rerouting = true;
      _navigationStatusMessage = 'ルートを再検索しています…';
    });
    _lastRerouteAt = DateTime.now();
    _offRouteSamples = 0;
    await _speak('ルートを外れました。新しいルートを検索します。', urgent: true);

    try {
      final route = await _repository.fetchCyclingRoute(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: targetLat,
        toLng: targetLng,
      );
      final engine = NavigationEngine(route);
      final snapshot = engine.update(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || !_isNavigating) return;
      setState(() {
        _route = route;
        _routeFromLat = position.latitude;
        _routeFromLng = position.longitude;
        _routeFetchedAt = DateTime.now();
        _navigationEngine = engine;
        _navigationSnapshot = snapshot;
        _rerouting = false;
        _navigationStatusMessage = '新しいルートに更新しました。';
        _guidanceStepIndex = null;
        _announcedPrepare = false;
        _announcedNow = false;
      });
      await _speak('新しいルートで案内を続けます。');
    } catch (error) {
      debugPrint('route recalculation error: $error');
      if (!mounted) return;
      setState(() {
        _rerouting = false;
        _navigationStatusMessage = 'ルートを再検索できませんでした。現在のルート表示を継続します。';
      });
    }
  }

  Future<void> _speak(String message, {bool urgent = false}) async {
    try {
      // 音声をミュートしていても、曲がり角と到着の振動通知は残す。
      if (urgent) await _announcer.vibrate();
      if (_voiceEnabled) await _announcer.speak(message);
    } catch (error) {
      debugPrint('navigation voice error: $error');
      if (mounted && _isNavigating) {
        setState(
          () => _navigationStatusMessage = '音声案内を再生できません。画面の案内をご確認ください。',
        );
      }
    }
  }

  Future<void> _completeArrival() async {
    if (!mounted) return;
    final completedOnReturn = _stage == _RouteStage.returnNavigating;
    final stopPositionUpdates = _positionSubscription?.cancel();
    _positionSubscription = null;
    setState(() {
      _completedOnReturn = completedOnReturn;
      _stage = _RouteStage.completed;
      _rerouting = false;
      _offRouteSamples = 0;
      _navigationStatusMessage = null;
      _navigationSnapshot = NavigationSnapshot(
        nearestSegmentIndex:
            _navigationSnapshot?.nearestSegmentIndex ??
            math.max(0, (_route?.points.length ?? 1) - 2),
        offRouteDistanceM: 0,
        remainingDistanceM: 0,
        remainingDurationSec: 0,
        upcomingStepIndex: _navigationSnapshot?.upcomingStepIndex,
        distanceToManeuverM: 0,
      );
    });
    // 到着表示と記録を音声・端末制御の完了待ちで遅らせない。
    if (stopPositionUpdates != null) unawaited(stopPositionUpdates);
    unawaited(_disableWakeLock('arrival'));
    unawaited(
      _speak(
        completedOnReturn ? '出発地点に到着しました。お疲れさまでした。' : '目的地に到着しました。お疲れさまでした。',
        urgent: true,
      ),
    );
    await _finishTripRecord();
  }

  Future<void> _disableWakeLock(String reason) async {
    if (!widget.keepScreenAwake) return;
    try {
      await WakelockPlus.disable();
    } catch (error) {
      debugPrint('wakelock disable ($reason) error: $error');
    }
  }

  Future<void> _finishTripRecord() async {
    final tripId = _tripId;
    if (tripId == null) return;
    final authState = ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;
    if (userId == null) return;

    try {
      await _repository.endTrip(userId: userId, tripId: tripId);
      _tripId = null;
    } catch (error) {
      debugPrint('trip auto finish error: $error');
      if (mounted) {
        setState(() => _navigationStatusMessage = '到着しましたが、走行記録の保存に失敗しました。');
      }
    }
  }

  Future<void> _finishCompletedFlow() async {
    if (_busy) return;
    if (_tripId != null) {
      setState(() => _busy = true);
      await _finishTripRecord();
      if (!mounted) return;
      setState(() => _busy = false);
      if (_tripId != null) {
        _showMessage('走行記録を保存できませんでした。通信を確認してもう一度お試しください。');
        return;
      }
    }
    if (mounted) context.go('/home');
  }

  String _spokenDistance(double meters) {
    if (meters < 100) return '${(meters / 10).round() * 10}メートル';
    if (meters < 1000) return '${(meters / 50).round() * 50}メートル';
    return '${(meters / 1000).toStringAsFixed(1)}キロメートル';
  }

  Future<void> _beginStay() async {
    if (!_isRoundTrip || _stage != _RouteStage.outboundNavigating) return;
    if (!mounted) return;
    setState(() {
      _stage = _RouteStage.staying;
      _rerouting = false;
      _navigationStatusMessage = null;
    });

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _stayTimer?.cancel();

    if (widget.keepScreenAwake) {
      try {
        await WakelockPlus.disable();
      } catch (error) {
        debugPrint('wakelock disable on stay error: $error');
      }
    }

    if (!mounted) return;
    _showMessage('案内を一時停止しました。滞在を開始します。');
    await _speak('目的地に到着しました。案内を一時停止します。', urgent: true);

    if (_plannedStayMinutes == 0) {
      await _prepareReturnRoute();
      return;
    }
    _stayTimer = Timer(
      Duration(minutes: _plannedStayMinutes),
      _prepareReturnRoute,
    );
  }

  Future<void> _prepareReturnRoute() async {
    if (_busy || !mounted) return;
    final originLat = _originLat;
    final originLng = _originLng;
    if (originLat == null || originLng == null) {
      _showMessage('出発地点を確認できないため、帰りのルートを表示できませんでした。');
      return;
    }

    _stayTimer?.cancel();
    setState(() {
      _busy = true;
      _loading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final route = await _repository.fetchCyclingRoute(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: originLat,
        toLng: originLng,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _routeFromLat = position.latitude;
        _routeFromLng = position.longitude;
        _routeFetchedAt = DateTime.now();
        _navigationEngine = NavigationEngine(route);
        _navigationSnapshot = null;
        _stage = _RouteStage.returnPreview;
        _loading = false;
        _busy = false;
      });
      _showMessage('帰りのルートを表示しました。');
    } catch (error) {
      debugPrint('return route load error: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _busy = false;
        _errorMessage = '帰りのルートを取得できませんでした。もう一度お試しください。';
      });
    }
  }

  /// 案内終了: バーを戻す。トリップ記録中ならバックに終了も記録する
  Future<bool> _endNavigation() async {
    if (_busy) return false; // 二度押しガード
    setState(() {
      _busy = true;
      _arrivalHandling = true;
    });

    final authState = ref.read(authProvider);
    final userId =
        authState is AuthAuthenticated ? authState.user.userId : null;
    final tripId = _tripId;
    final endedStage = _stage;
    final stopPositionUpdates = _positionSubscription?.cancel();
    _positionSubscription = null;
    _stayTimer?.cancel();
    var recordEnded = true;

    try {
      if (tripId != null && userId != null) {
        await _repository.endTrip(userId: userId, tripId: tripId);
        _tripId = null;
        _showMessage('お疲れさまでした!走行を記録しました');
      } else if (tripId != null) {
        recordEnded = false;
        _showMessage('ログイン情報を確認できず、走行記録を終了できませんでした');
      } else {
        _showMessage('案内を終了しました');
      }
    } catch (error) {
      debugPrint('trip end error: $error');
      recordEnded = false;
      _showMessage('走行記録の終了に失敗しました');
    } finally {
      if (stopPositionUpdates != null) unawaited(stopPositionUpdates);
      unawaited(_announcer.stop());
      unawaited(_disableWakeLock('navigation end'));
      if (mounted) {
        setState(() {
          _busy = false;
          _arrivalHandling = false;
          _navigationSnapshot = null;
          _currentPosition = null;
          _navigationStatusMessage = null;
          _rerouting = false;
          _stage =
              endedStage == _RouteStage.returnNavigating
                  ? _RouteStage.returnPreview
                  : _RouteStage.outboundPreview;
        });
      }
    }
    return recordEnded;
  }

  Future<void> _handleBackAttempt() async {
    if (_allowPop || _exitDialogVisible) return;
    if (_busy) {
      _showMessage('処理中です。少し待ってからもう一度お試しください。');
      return;
    }

    _exitDialogVisible = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('案内を終了しますか？'),
            content: const Text('前の画面に戻ると、案内と走行記録を終了します。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD93A2A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('終了して戻る'),
              ),
            ],
          ),
    );
    _exitDialogVisible = false;
    if (!mounted || shouldExit != true) return;

    final recordEnded = await _endNavigation();
    if (!mounted) return;
    if (!recordEnded) {
      _showMessage('走行記録を終了できなかったため、画面を移動しませんでした。もう一度お試しください。');
      return;
    }

    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        context.go('/home');
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A0088),
        behavior: SnackBarBehavior.floating,
        // 下部の「案内を終了」ボタンに被らないよう、少し上に出す
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
    final screen = AppScreenFrame(
      child: Scaffold(
        // 案内モード中はロゴバーも消して全画面にする
        appBar:
            _isNavigating
                ? null
                : AppBar(
                  title: const Image(
                    image: AssetImage('assets/logo_long.png'),
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
        body: Stack(
          children: [
            // マップ代わりのルート表示(常に全画面。バーはこの上に被さる)
            Positioned.fill(child: _buildRoutePreview()),

            // ルート取得に失敗したときだけ、概算値表示であることを上部に知らせる
            if (_errorMessage != null && !_isNavigating)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),

            // 走行中は視線移動を減らすため、次の操作を大きく固定表示する。
            if (_isNavigating)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildNavigationHeader(),
              ),

            if (_isNavigating && _navigationStatusMessage != null)
              Positioned(
                top: 154,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: Material(
                    color: _rerouting ? const Color(0xFFFFF3E0) : Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        children: [
                          if (_rerouting)
                            const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              _navigationStatusMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 下部: 通常時は情報バー、案内モード中は「案内を終了」ボタンだけ。
            // AnimatedSwitcherで切り替え時にスッと入れ替わる
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
                child: _buildBottomPanel(),
              ),
            ),
          ],
        ),
      ),
    );
    return PopScope<Object?>(
      canPop: _allowPop || !_shouldGuardBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleBackAttempt());
      },
      child: screen,
    );
  }

  /// マップ領域の中身: 取得中→インジケーター / 成功→ルート形状 / 失敗→目的地の写真
  Widget _buildRoutePreview() {
    if (_loading) {
      return Container(
        color: const Color(0xFFF1EBFF),
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
        color: const Color(0xFFF8F9FE), // マップの下地の色
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

  Widget _buildNavigationHeader() {
    final step = _upcomingStep;
    final instruction = step?.instruction ?? 'ルートに沿って進んでください';
    final distance = _navigationSnapshot?.distanceToManeuverM;
    final distanceLabel =
        distance == null ? '現在地を確認中' : _compactDistance(distance);

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF09209C),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_maneuverIcon(step), color: Colors.white, size: 38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    distanceLabel,
                    style: const TextStyle(
                      color: Color(0xFFDCE4FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_isRoundTrip ? (_isReturnRoute ? '復路 ・ ' : '往路 ・ ') : ''}${_distanceText()} ・ ${_durationText()}',
                    style: const TextStyle(
                      color: Color(0xFFDCE4FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('voice-toggle'),
              tooltip: _voiceEnabled ? '音声案内をオフ' : '音声案内をオン',
              onPressed: () {
                setState(() => _voiceEnabled = !_voiceEnabled);
                if (!_voiceEnabled) {
                  unawaited(_announcer.stop());
                } else {
                  unawaited(_speak('音声案内をオンにしました。'));
                }
              },
              icon: Icon(
                _voiceEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactDistance(double meters) {
    if (meters < 1000) return '${math.max(0, meters).round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  IconData _maneuverIcon(NavigationStep? step) {
    if (step == null) return Icons.navigation_rounded;
    if (step.maneuverType == 'arrive') return Icons.flag_rounded;
    final modifier = step.modifier ?? '';
    if (modifier.contains('left')) return Icons.turn_left_rounded;
    if (modifier.contains('right')) return Icons.turn_right_rounded;
    if (modifier.contains('uturn')) return Icons.u_turn_left_rounded;
    if (step.maneuverType == 'roundabout' || step.maneuverType == 'rotary') {
      return Icons.roundabout_left_rounded;
    }
    return Icons.straight_rounded;
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

    final travelledEnd = math.min(
      routePoints.length,
      (_navigationSnapshot?.nearestSegmentIndex ?? -2) + 2,
    );
    final travelledPoints =
        travelledEnd >= 2
            ? routePoints.take(travelledEnd).toList()
            : const <LatLng>[];
    final currentPosition = _currentPosition;
    final currentMarkerPosition =
        currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : _originLat != null && _originLng != null
            ? LatLng(_originLat!, _originLng!)
            : null;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: routePoints.first,
        zoom: 13,
      ),
      // 下の情報バー・上のチップに隠れないよう、地図の見える中心を上下にずらす
      padding: EdgeInsets.only(
        top: _isNavigating ? 190 : 100,
        bottom: _isNavigating ? 100 : 260,
      ),
      onMapCreated: (controller) async {
        _mapController = controller;
        // 地図のレイアウト確定前にbounds指定すると失敗することがあるので少し待つ
        await Future.delayed(const Duration(milliseconds: 100));
        // 待っている間に画面が閉じられていたら、破棄済みの地図を触らない
        if (!mounted) return;
        // ルート全体が画面に収まるようにカメラを合わせる
        final current = _currentPosition;
        if (_isNavigating && current != null) {
          _followCurrentPosition(current);
        } else {
          await controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 48));
        }
      },
      // ルートの線
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          width: 5,
          color: const Color(0xFF19005C),
        ),
        if (travelledPoints.length >= 2)
          Polyline(
            polylineId: const PolylineId('travelled-route'),
            points: travelledPoints,
            width: 5,
            color: const Color(0xFF9AA0A6),
          ),
      },
      // 現在地(青)と目的地(赤=デフォルト)のマーカー
      markers: {
        Marker(
          markerId: const MarkerId('destination'),
          position: routePoints.last,
        ),
        if (currentMarkerPosition != null)
          Marker(
            markerId: const MarkerId('current-position'),
            position: currentMarkerPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            rotation: currentPosition?.heading ?? 0,
            flat: currentPosition != null,
            anchor:
                currentPosition != null
                    ? const Offset(0.5, 0.5)
                    : const Offset(0.5, 1),
            zIndexInt: 10,
          ),
      },
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
    );
  }

  /// 通常時の下部バー: 目的地情報+距離・時間+ボタン(Googleマップの検索結果バー風)
  Widget _buildBottomPanel() {
    switch (_stage) {
      case _RouteStage.outboundNavigating:
        return _isRoundTrip
            ? _buildOutboundNavigationButtons()
            : _buildEndButton();
      case _RouteStage.returnNavigating:
        return _buildEndButton();
      case _RouteStage.staying:
        return _buildStayPanel();
      case _RouteStage.completed:
        return _buildCompletedPanel();
      case _RouteStage.outboundPreview:
      case _RouteStage.returnPreview:
        return _buildInfoPanel();
    }
  }

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
            _isReturnRoute ? '出発地点へ戻る' : _name,
            maxLines: 1, // 長い名前は1行に収めて…で省略する
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          // 住所(あるときだけ)
          if (!_isReturnRoute && _address.isNotEmpty)
            Text(
              _address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          const SizedBox(height: 10),

          // 距離と所要時間を1行で
          Row(
            children: [
              const Icon(
                Icons.directions_bike,
                size: 18,
                color: Color(0xFF19005C),
              ),
              const SizedBox(width: 6),
              Text(
                '${_distanceText()} ・ ${_durationText()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF19005C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ボタン: 左=ルートを変更(戻る) / 右=案内開始
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // 詳細画面に戻って選び直せるようにする
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home'); // 直接開かれたときの保険
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 3, 11, 59),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ルートを変更',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _startNavigation,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: const Color.fromARGB(255, 9, 31, 156),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isReturnRoute ? '帰りの案内を開始' : '案内開始',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutboundNavigationButtons() {
    return Container(
      key: const ValueKey('outbound-buttons'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : _endNavigation,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                side: const BorderSide(color: Color(0xFFD93A2A), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '案内を終了',
                style: TextStyle(fontSize: 15, color: Color(0xFFD93A2A)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _beginStay,
              icon: const Icon(Icons.flag_rounded, color: Colors.white),
              label: const Text(
                '到着・滞在を開始',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                backgroundColor: const Color.fromARGB(255, 9, 31, 156),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStayPanel() {
    return Container(
      key: const ValueKey('stay-panel'),
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
          const Text(
            '滞在中',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF19005C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '案内を停止しています。$_plannedStayMinutes分後に帰りのルートを表示します。',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _endNavigation,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: const BorderSide(color: Color(0xFFD93A2A), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '案内を終了',
                    style: TextStyle(fontSize: 15, color: Color(0xFFD93A2A)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _prepareReturnRoute,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    backgroundColor: const Color.fromARGB(255, 9, 31, 156),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '今すぐ折り返す',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedPanel() {
    return Container(
      key: const ValueKey('completed-panel'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF14883B),
            size: 52,
          ),
          const SizedBox(height: 8),
          Text(
            _completedOnReturn ? '出発地点に到着しました' : '目的地に到着しました',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF19005C),
            ),
          ),
          if (_navigationStatusMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _navigationStatusMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFD93A2A)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _finishCompletedFlow,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
                backgroundColor: const Color.fromARGB(255, 9, 31, 156),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _tripId != null ? '記録保存を再試行' : '完了',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
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
            backgroundColor: const Color(0xFFD93A2A), // Googleマップの終了ボタンと同じ赤系
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
          ..color = const Color(0xFF19005C)
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
    canvas.drawCircle(goal, 10, Paint()..color = const Color(0xFFD93A2A));
    canvas.drawCircle(goal, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RoutePreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}

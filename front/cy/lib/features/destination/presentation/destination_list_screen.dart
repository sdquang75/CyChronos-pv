import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/place_photo.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/staggered_entrance.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../detil/detil.dart';
import '../../home/domain/recommendation_state.dart';
import '../../home/presentation/providers/recommendation_provider.dart';

class DestinationListScreen extends ConsumerStatefulWidget {
  final int minutes;

  // ホーム画面で選択したGoogle Placesの検索タイプ
  // 例：cafe、park、restaurant
  final String type;

  const DestinationListScreen({
    super.key,
    required this.minutes,
    required this.type,
  });

  @override
  ConsumerState<DestinationListScreen> createState() =>
      _DestinationListScreenState();
}

class _DestinationListScreenState
    extends ConsumerState<DestinationListScreen> {
  @override
  void initState() {
    super.initState();

    // この画面自体が検索の実行主体になる(reformと同じ構成)。
    // ホーム画面ではローディング/エラーをトースト表示せず、
    // ここに来た時点ですぐ検索を始めて、結果はこの画面の中で状態として出す
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });
  }

  void _search() {
    ref
        .read(recommendationProvider.notifier)
        .fetchForCurrentLocation(minutes: widget.minutes, type: widget.type);
  }

  void _retry() {
    HapticFeedback.lightImpact();
    _search();
  }

  bool get _isLoading {
    final state = ref.watch(recommendationProvider);
    return state is RecommendationInitial ||
        state is RecommendationLocating ||
        state is RecommendationLoading;
  }

  // /api/suggest から取得できた目的地一覧(まだ結果が無ければ空)
  List<dynamic> get _places {
    final state = ref.watch(recommendationProvider);
    if (state is! RecommendationLoaded) return const [];
    final data = state.data;
    if (data is! Map) return const [];
    final rawPlaces = data['places'];
    if (rawPlaces is! List) return const [];
    return rawPlaces;
  }

  // 空き時間を「X時間YY分」の形にする
  String _freeTimeText() {
    final total = widget.minutes;
    final hours = total ~/ 60;
    final minutes = (total % 60).toString().padLeft(2, '0');

    return '$hours時間$minutes分';
  }

  @override
  Widget build(BuildContext context) {
    // AppScreenFrame・下部メニューバーはHomeScreen(IndexedStackシェル)側で
    // 一括して描画されるので、ここでは自分の中身だけを組み立てる
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: AppBottomNavigation.barHeightFor(context),
          ),
          child: Column(
            children: [
              _buildLogo(),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 20),

                      Expanded(
                        child: _buildBody(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        text: '情報変更',
                        icon: Icons.tune_rounded,
                        isPrimary: false,
                        onPressed: _goBackToHome,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _ActionButton(
                        text: _isLoading
                            ? '検索中...'
                            : '再提案',
                        icon: _isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                        isPrimary: true,
                        onPressed: () {
                          if (_isLoading) return;
                          _retry();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        20,
      ),
      child: Center(
        child: Image.asset(
          'assets/logo_long.png',
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'おすすめスポット',
          style: TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Color(0xFF19005C),
            height: 1.25,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          '条件に合った目的地を選びましょう。',
          style: TextStyle(
            fontFamily: 'Inter',
            fontFamilyFallback: ['NotoSansJP'],
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF484553),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EBFF),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: const Color(
                0xFF19005C,
              ).withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Color(0xFF19005C),
              ),

              const SizedBox(width: 8),

              const Text(
                '空き時間',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: ['NotoSansJP'],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF484553),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _freeTimeText(),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF19005C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 検索状態に応じて中身を切り替える(ローディング/エラー/空/一覧)。
  // ホーム画面でトースト表示していた検索中・エラーの案内を、
  // この画面自体の「状態として作り込まれた表示」に置き換えたもの
  Widget _buildBody() {
    final state = ref.watch(recommendationProvider);

    if (state is RecommendationInitial ||
        state is RecommendationLocating ||
        state is RecommendationLoading) {
      return const _SearchingIndicator();
    }

    if (state is RecommendationLocationServiceDisabled) {
      return _DestinationStateView(
        icon: Icons.location_disabled_rounded,
        title: '位置情報を確認してください',
        message: '位置情報サービスが無効です。端末の設定をご確認ください。',
        onRetry: _retry,
      );
    }

    if (state is RecommendationPermissionDenied) {
      return _DestinationStateView(
        icon: Icons.location_disabled_rounded,
        title: '位置情報の利用を許可してください',
        message: '位置情報を許可すると、現在地周辺のおすすめスポットを検索できます。',
        onRetry: _retry,
      );
    }

    if (state is RecommendationPermissionDeniedForever) {
      return _DestinationStateView(
        icon: Icons.location_disabled_rounded,
        title: '位置情報の利用が拒否されています',
        message: '設定アプリから位置情報の利用を許可してください。',
        onRetry: _retry,
      );
    }

    if (state is RecommendationError) {
      return _DestinationStateView(
        icon: Icons.error_outline_rounded,
        title: '検索に失敗しました',
        message: '通信環境をご確認のうえ、もう一度お試しください。',
        onRetry: _retry,
      );
    }

    // RecommendationLoaded
    if (_places.isEmpty) {
      return const _DestinationStateView(
        icon: Icons.location_off_rounded,
        title: '目的地が見つかりませんでした',
        message: '時間やジャンルを変更して、もう一度お試しください。',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 4,
        bottom: 8,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final rawDestination = _places[index];

        if (rawDestination is! Map) {
          return const SizedBox.shrink();
        }

        final destination = Map<String, dynamic>.from(
          rawDestination,
        );

        return StaggeredEntrance(
          key: ValueKey(destination['id'] ?? destination['name'] ?? index),
          delay: Duration(milliseconds: 45 * index),
          child: _DestinationCard(
            destination: destination,
          ),
        );
      },
    );
  }

  // 「情報変更」を押したときの処理
  // RideFlow(HOMEタブ専用の入れ子Navigator)からpushされてきた画面なので、
  // popすればHOMEタブのプランナー画面(入力した時間やジャンルはそのまま)に戻る
  void _goBackToHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

class _DestinationCard extends StatelessWidget {
  // /api/suggest のplaces 1件分
  //
  // 主な項目:
  // id
  // name
  // address
  // genre
  // lat
  // lng
  // durationSec
  // durationMinutes
  // distanceM
  final Map<String, dynamic> destination;

  const _DestinationCard({
    required this.destination,
  });

  // カードのサムネイル
  // 写真があればバックエンド経由の実写真、
  // なければロゴを表示する
  Widget _buildThumbnail() {
    // サムネイルは小さいため幅200pxで取得する
    final photoUrl = placePhotoUrl(
      destination['photoReference']?.toString(),
      maxwidth: 200,
    );

    if (photoUrl == null) {
      return Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      // 通信失敗時はロゴへ切り替える
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamic rawDuration =
        destination['durationMinutes'];

    final int? durationMinutes = rawDuration is num
        ? rawDuration.round()
        : int.tryParse(
            rawDuration?.toString() ?? '',
          );

    final String durationText = durationMinutes != null
        ? '約$durationMinutes分'
        : '所要時間不明';

    // カード全体をタップして詳細画面へ移動できる(押下時に軽く縮小+触覚フィードバック)
    return TapScale(
      onTap: () {
        _openDetail(context);
      },
      child: _buildCard(
        context,
        durationText,
      ),
    );
  }

  // 選択した目的地を詳細画面へ渡す(RideFlowの入れ子Navigatorでpush。
  // 元はapp_router.dartの/detilルートが持っていた変換ロジックをここに移した)
  void _openDetail(BuildContext context) {
    // 数値はAPIの都合で int でも double でも来るので num で受けてから変換する
    final durationSec = destination['durationSec'] as num?;
    final distanceM = destination['distanceM'] as num?;
    final rating = destination['rating'] as num?;

    // 写真は photoReference をバックの写真プロキシのURLに変換して渡す。
    // 写真なしのスポットは null になり、詳細画面側で仮画像が表示される
    final imageUrl = placePhotoUrl(
      destination['photoReference']?.toString(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => DetilScreen(
              name: destination['name']?.toString() ?? '',
              address: destination['address']?.toString() ?? '',
              genre: destination['genre']?.toString() ?? '',
              imageUrl: imageUrl,
              durationSec: durationSec?.round(), // 所要時間(秒)
              distanceMeter: distanceM?.round(), // 距離(m)
              rating: rating?.toDouble(), // 評価(例: 4.2)
              destination: destination, // ルート確認画面へ引き継ぐ用の元データ
            ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String durationText,
  ) {
    final String name =
        destination['name']?.toString() ?? '名称不明';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFFC9C4D5,
          ).withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF2E0094,
            ).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(
                  0xFFC9C4D5,
                ).withValues(alpha: 0.35),
              ),
            ),
            child: _buildThumbnail(),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Color(0xFF19005C),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EBFF),
                          borderRadius: BorderRadius.circular(
                            9999,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF19005C,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bike_rounded,
                              size: 15,
                              color: Color(0xFF19005C),
                            ),

                            const SizedBox(width: 5),

                            Flexible(
                              child: Text(
                                durationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: Color(0xFF19005C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _openDetail(context);
                        },
                        borderRadius: BorderRadius.circular(
                          9999,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '詳細を見る',
                                style: TextStyle(
                                  fontFamily: 'HankenGrotesk',
                                  fontFamilyFallback: [
                                    'NotoSansJP',
                                  ],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF19005C),
                                ),
                              ),

                              SizedBox(width: 2),

                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Color(0xFF19005C),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 検索中は結果エリアの真ん中にスピナーだけを出す
// (ホームに留まったままトーストで進捗を伝えるのではなく、
// この画面自体が「検索中」という状態を持つ)
class _SearchingIndicator extends StatelessWidget {
  const _SearchingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Color(0xFF19005C),
        ),
      ),
    );
  }
}

// 「該当なし」「位置情報エラー」「通信エラー」を1つの見た目で表現する。
// onRetryを渡すと再検索ボタンが出る(該当なしのときは下の「再提案」ボタンが
// 既にあるので付けない)
class _DestinationStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _DestinationStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 36,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(
              0xFFC9C4D5,
            ).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 42,
              color: const Color(0xFF19005C),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF19005C),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF484553),
                height: 1.5,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF19005C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'もう一度試す',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? const Color(0xFF19005C)
        : Colors.white;

    final foregroundColor = isPrimary
        ? Colors.white
        : const Color(0xFF19005C);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: const Color(0xFF19005C),
              width: 1.5,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(
                        0xFF19005C,
                      ).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: foregroundColor,
              ),

              const SizedBox(width: 7),

              Text(
                text,
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontFamilyFallback: const [
                    'NotoSansJP',
                  ],
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
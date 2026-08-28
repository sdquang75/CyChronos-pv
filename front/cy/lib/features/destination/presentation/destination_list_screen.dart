import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/place_photo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
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

  // 「情報変更」を押したときの処理
  // RideFlow(HOMEタブ専用の入れ子Navigator)からpushされてきた画面なので、
  // popすればHOMEタブのプランナー画面(入力した時間やジャンルはそのまま)に戻る
  void _goBackToHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // AppScreenFrame・下部メニューバーはHomeScreen(IndexedStackシェル)側で
    // 一括して描画されるので、ここでは自分の中身だけを組み立てる
    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: AppBottomNavigation.barHeightFor(context),
          ),
          child: Column(
            children: [
              const AppTopBar(title: 'おすすめスポット'),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildSubHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: '情報変更',
                        icon: Icons.tune_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: _goBackToHome,
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    Expanded(
                      child: AppButton(
                        label: _isLoading ? '検索中...' : '再提案',
                        icon:
                            _isLoading
                                ? Icons.hourglass_top_rounded
                                : Icons.refresh_rounded,
                        onPressed: () {
                          if (_isLoading) return;
                          _retry();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  // タイトルはAppTopBarが表示するので、ここでは説明文+空き時間バッジのみ
  Widget _buildSubHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('条件に合った目的地を選びましょう。', style: AppTypography.pageSubtitle),

        const SizedBox(height: AppSpacing.lg),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: AppColors.primary,
              ),

              const SizedBox(width: AppSpacing.sm),

              const Text('空き時間', style: AppTypography.label),

              const SizedBox(width: AppSpacing.sm),

              Text(_freeTimeText(), style: AppTypography.stat),
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

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.accentBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.35),
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
                  style: AppTypography.cardTitle,
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
                          color: AppColors.accentBg,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bike_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),

                            const SizedBox(width: 5),

                            Flexible(
                              child: Text(
                                durationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.stat.copyWith(
                                  fontSize: 11,
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
                          AppSpacing.radiusPill,
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
                                  color: AppColors.primary,
                                ),
                              ),

                              SizedBox(width: 2),

                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.primary,
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
          color: AppColors.primary,
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
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: 36,
        ),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 42,
              color: AppColors.primary,
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(fontSize: 16),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'もう一度試す',
                  icon: Icons.refresh_rounded,
                  height: 48,
                  borderRadius: 14,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../domain/recommendation_state.dart';
import '../../domain/weather_state.dart';
import '../providers/recommendation_provider.dart';
import '../providers/weather_provider.dart';
import 'weather_header_card.dart';

/// HOMEタブのルート画面(検索条件を入力しておすすめスポットを探す)。
/// RideFlowの入れ子Navigatorのルートとして使われ、目的地一覧が見つかったら
/// onFindDestinationを呼んでRideFlow側でpushしてもらう
/// (go_routerではなくコールバックにしているのは、この画面自体はIndexedStackの
/// 中に常駐していてページ遷移しないため)
class HomeTabView extends ConsumerStatefulWidget {
  const HomeTabView({super.key, required this.onFindDestination});

  final void Function(List<dynamic> places, int minutes, String type)
  onFindDestination;

  @override
  ConsumerState<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends ConsumerState<HomeTabView> {
  // Scroll Controller for Auto-Scrolling in Home Tab
  final ScrollController _scrollController = ScrollController();

  // Interactive States
  final TextEditingController _hoursController = TextEditingController(
    text: '0',
  );
  final TextEditingController _minutesController = TextEditingController(
    text: '45',
  );
  final Set<String> _selectedGenres = {'Cafe'}; // default Cafe selected

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // HomeTabViewはIndexedStackの中に常駐するので初回のみ実行される。
      // 既に取得済み/取得中なら再取得しない
      // (タブを往復するたびに天気APIとGPSを叩き直すのを防ぐ)。
      if (ref.read(weatherProvider) is WeatherInitial) {
        ref.read(weatherProvider.notifier).fetchForCurrentLocation();
      }
    });
  }

  String _selectedPlacesType() {
    if (_selectedGenres.isEmpty) {
      return 'cafe';
    }

    final selected = _selectedGenres.first;

    const typeMap = {
      // Google Placesの検索typeではない値はバックエンド側で専用条件へ変換する
      'All': 'all',
      'Cafe': 'cafe',
      'Nature': 'park',
      'Food': 'restaurant',
      'Temple': 'temple',
      'Art': 'museum',
      'Viewpoint': 'tourist_attraction',
      'Shop': 'store',
      'Landmark': 'tourist_attraction',
      'Park': 'park',
    };

    return typeMap[selected] ?? 'cafe';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _showRecommendationFeedback(RecommendationState state) {
    if (!mounted) return;

    String? message;
    switch (state) {
      case RecommendationLocating():
        message = '現在地を取得しています...';
      case RecommendationLoading():
        message = 'おすすめスポットを検索しています...';
      case RecommendationLoaded(data: final data):
        final places = data['places'] as List<dynamic>? ?? [];
        // 検索に使った空き時間(分)も一覧画面に渡す(一覧ヘッダーの「空き時間」表示に使う)
        final hours = int.tryParse(_hoursController.text) ?? 0;
        final minutes = int.tryParse(_minutesController.text) ?? 0;
        widget.onFindDestination(
          places,
          hours * 60 + minutes,
          _selectedPlacesType(),
        );
        message = 'おすすめスポットを取得しました。';
      case RecommendationLocationServiceDisabled():
        message = '位置情報サービスが無効です。端末の設定をご確認ください。';
      case RecommendationPermissionDenied():
        message = '位置情報の利用を許可してください。';
      case RecommendationPermissionDeniedForever():
        message = '位置情報の利用が拒否されています。設定アプリから許可してください。';
      case RecommendationError(message: final msg):
        message = 'エラーが発生しました: $msg';
      case RecommendationInitial():
        message = null;
    }

    if (message == null) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontFamilyFallback: ['NotoSansJP'],
          ),
        ),
        backgroundColor: const Color(0xFF2A0088),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecommendationState>(recommendationProvider, (previous, next) {
      _showRecommendationFeedback(next);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: SafeArea(bottom: false, child: _buildHomeTab()),
          ),

          // Floating CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: AppBottomNavigation.barHeightFor(context) + 16,
            child: _buildFloatingCTA(),
          ),
        ],
      ),
    );
  }

  // ================= TAB CONTENT BUILDERS =================

  // TAB 0: HOME PLANNER SCREEN
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 180, // Space for floating CTA & Bottom Bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 36),
          _buildDurationSection(),
          const SizedBox(height: 36),
          _buildGenreSection(),
        ],
      ),
    );
  }

  // ================= UI ELEMENT BUILDERS =================

  // Header for Home Screen (Without Logout icon)
  // Header for Home Screen
  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            'assets/logo_long.png',
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 32),
        const WeatherHeaderCard(),
      ],
    );
  }

  // Duration Input (hours & minutes text fields, digits only)
  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DURATION',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.7,
            color: Color(0xFF484553),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildDurationField(controller: _hoursController),
            const SizedBox(width: 8),
            const Text(
              '時間',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF191C1F),
              ),
            ),
            const SizedBox(width: 24),
            _buildDurationField(controller: _minutesController),
            const SizedBox(width: 8),
            const Text(
              '分',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontFamilyFallback: ['NotoSansJP'],
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF191C1F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationField({required TextEditingController controller}) {
    return SizedBox(
      width: 90,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'HankenGrotesk',
          fontFamilyFallback: ['NotoSansJP'],
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: Color(0xFF191C1F),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: const Color(0xFFC9C4D5).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: const Color(0xFF19005C).withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // Genre Selector (Expanded list of interests)
  Widget _buildGenreSection() {
    final genres = [
      {'id': 'All', 'label': 'すべて', 'svg': _kAllSvg},
      {'id': 'Cafe', 'label': 'カフェ', 'svg': _kCafeSvg},
      {'id': 'Nature', 'label': '自然', 'svg': _kNatureSvg},
      {'id': 'Food', 'label': 'グルメ', 'svg': _kFoodSvg},
      {'id': 'Temple', 'label': '寺院', 'svg': _kTempleSvg},
      {'id': 'Art', 'label': 'アート', 'svg': _kArtSvg},
      {'id': 'Viewpoint', 'label': '絶景', 'svg': _kViewpointSvg},
      {'id': 'Shop', 'label': 'ショッピング', 'svg': _kShopSvg},
      {'id': 'Landmark', 'label': 'ランドマーク', 'svg': _kLandmarkSvg},
      {'id': 'Park', 'label': '公園', 'svg': _kParkSvg},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INTEREST',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.7,
            color: Color(0xFF484553),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              genres.map((genre) {
                final id = genre['id'] as String;
                final label = genre['label'] as String;
                final svgStr = genre['svg'] as String;
                final isSelected = _selectedGenres.contains(id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGenres
                        ..clear()
                        ..add(id);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFF1EBFF)
                              : const Color(0xFFF2F3F8),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF19005C).withValues(alpha: 0.3)
                                : const Color(0xFFC9C4D5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.string(
                          svgStr,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            isSelected
                                ? const Color(0xFF19005C)
                                : const Color(0xFF484553),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: ['NotoSansJP'],
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 16,
                            color:
                                isSelected
                                    ? const Color(0xFF19005C)
                                    : const Color(0xFF484553),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Floating CTA Button
  Widget _buildFloatingCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: () {
            final hours = int.tryParse(_hoursController.text) ?? 0;
            final minutes = int.tryParse(_minutesController.text) ?? 0;
            final totalMinutes = hours * 60 + minutes;
            if (totalMinutes < 1) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    '時間を入力してください。',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontFamilyFallback: ['NotoSansJP'],
                    ),
                  ),
                  backgroundColor: const Color(0xFF2A0088),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              return;
            }
            ref
                .read(recommendationProvider.notifier)
                .fetchForCurrentLocation(
                  minutes: totalMinutes,
                  type: _selectedPlacesType(),
                );
          },
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF19005C),
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF19005C).withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ルートを検索',
                  style: TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontFamilyFallback: ['NotoSansJP'],
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.string(
                  _kArrowRightSvg,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom SVGs (Inline)
const _kCafeSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18.5 7.5H19.5C20.6 7.5 21.5 8.4 21.5 9.5V11.5C21.5 12.6 20.6 13.5 19.5 13.5H18.5V7.5ZM18.5 15.5V17.5C18.5 18.6 17.6 19.5 16.5 19.5H5.5C4.4 19.5 3.5 18.6 3.5 17.5V7.5C3.5 6.4 4.4 5.5 5.5 5.5H16.5C17.6 5.5 18.5 6.4 18.5 7.5V15.5Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M7.5 2.5V4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M11.5 2.5V4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M15.5 2.5V4.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kNatureSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L2 22H22L12 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 8L7 17H17L12 8Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 14V22" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kFoodSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 18.5C8.41 18.5 5.5 15.59 5.5 12C5.5 8.41 8.41 5.5 12 5.5C15.59 5.5 18.5 8.41 18.5 12C18.5 15.59 15.59 18.5 12 18.5Z" stroke="currentColor" stroke-width="2"/>
  <path d="M9 12H15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''';

const _kTempleSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M2 19.5H22" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  <path d="M4 19.5V11.5H20V19.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M1 9.5L12 3.5L23 9.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8 19.5V14.5H16V19.5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''';

const _kArtSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2C6.47715 2 2 6.47715 2 12C2 14.7255 3.09032 17.1962 4.85857 19C5.03457 19.176 5.28143 19.243 5.51857 19.18C6.39857 18.94 7.62571 18.5 8.5 18.5C9.5 18.5 10.5 19.5 10.5 20.5C10.5 21.3743 11.06 21.84 12 22Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
  <circle cx="7.5" cy="10.5" r="1.5" fill="currentColor"/>
  <circle cx="11.5" cy="7.5" r="1.5" fill="currentColor"/>
  <circle cx="16.5" cy="9.5" r="1.5" fill="currentColor"/>
  <circle cx="15.5" cy="14.5" r="1.5" fill="currentColor"/>
</svg>''';

const _kViewpointSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

const _kShopSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4H6z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <line x1="3" y1="6" x2="21" y2="6" stroke="currentColor" stroke-width="2"/>
  <path d="M16 10a4 4 0 0 1-8 0" stroke="currentColor" stroke-width="2"/>
</svg>''';

const _kLandmarkSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
</svg>''';

const _kAllSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="3" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="2"/>
  <rect x="14" y="3" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="2"/>
  <rect x="3" y="14" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="2"/>
  <rect x="14" y="14" width="7" height="7" rx="1.5" stroke="currentColor" stroke-width="2"/>
</svg>''';

const _kParkSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2a5 5 0 0 0-5 5c0 4 5 9 5 9s5-5 5-5a5 5 0 0 0-5-5z" stroke="currentColor" stroke-width="2"/>
  <path d="M3 22h18" stroke="currentColor" stroke-width="2"/>
  <path d="M12 16v6" stroke="currentColor" stroke-width="2"/>
</svg>''';

const _kArrowRightSvg =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 12H19" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M12 5L19 12L12 5.5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M19 12L12 19" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''';

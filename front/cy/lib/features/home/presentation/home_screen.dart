import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recommendation_state.dart';
import 'providers/recommendation_provider.dart';
import 'widgets/history_tab_view.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/home_tab_view.dart';
import 'widgets/profile_tab_view.dart';
import 'widgets/route_tab_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // Interactive States
  int _currentTab = 0; // 0: HOME, 1: ROUTE, 2: HISTORY, 3: PROFILE

  // Customize card state (stay duration / spare time / genre dropdowns)
  String _stayDurationMinutes = '30';
  String _spareTimeMinutes = '30';
  String? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    // Prime the location permission popup as soon as the Home screen opens
    // (foundation for the upcoming live weather card — the result isn't
    // used yet, this just gets the OS prompt out of the way early).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationServiceProvider).ensurePermissionRequested();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      case RecommendationLoaded():
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

    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 390 || size.height > 844;

    Widget content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Main Dynamic Body based on Selected Tab
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  HomeTabView(
                    scrollController: _scrollController,
                    stayDurationMinutes: _stayDurationMinutes,
                    onStayDurationChanged:
                        (id) => setState(
                          () => _stayDurationMinutes = id ?? _stayDurationMinutes,
                        ),
                    spareTimeMinutes: _spareTimeMinutes,
                    onSpareTimeChanged:
                        (id) => setState(
                          () => _spareTimeMinutes = id ?? _spareTimeMinutes,
                        ),
                    selectedGenreId: _selectedGenreId,
                    onGenreChanged:
                        (id) => setState(() => _selectedGenreId = id),
                    onFindDestination:
                        () =>
                            ref
                                .read(recommendationProvider.notifier)
                                .fetchForCurrentLocation(),
                  ),
                  const RouteTabView(),
                  const HistoryTabView(),
                  const ProfileTabView(),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar. Always pinned above the scrollable
          // content (the CTA button now scrolls with the Home tab's list).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeBottomNavBar(
              currentIndex: _currentTab,
              onTap: (index) => setState(() => _currentTab = index),
            ),
          ),
        ],
      ),
    );

    if (isLargeScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF191C1F),
        body: Center(
          child: Container(
            width: 390,
            height: 844,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}

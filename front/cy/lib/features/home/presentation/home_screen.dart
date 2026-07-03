import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/recommendation_state.dart';
import 'providers/recommendation_provider.dart';
import 'widgets/floating_cta_button.dart';
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
  // Scroll Controller for Auto-Scrolling in Home Tab
  final ScrollController _scrollController = ScrollController();

  // Interactive States
  int _selectedDuration = 90; // default 1.5 hours
  final Set<String> _selectedGenres = {'Cafe'}; // default Cafe selected
  int _currentTab = 0; // 0: HOME, 1: ROUTE, 2: HISTORY, 3: PROFILE
  bool _advancedExpanded = false;

  // Advanced Config state variables (3 sliders)
  double _speedKmh = 18.0; // Cruising Speed
  double _restMinutes = 15.0; // Rest Duration
  double _restFreqMin = 30.0; // Rest Frequency (every X minutes)

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

  void _toggleAdvanced() {
    setState(() {
      _advancedExpanded = !_advancedExpanded;
    });

    if (_advancedExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final double targetOffset = _scrollController.offset + 230.0;
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  void _onGenreToggled(String id) {
    setState(() {
      if (_selectedGenres.contains(id)) {
        _selectedGenres.remove(id);
      } else {
        _selectedGenres.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecommendationState>(recommendationProvider, (previous, next) {
      _showRecommendationFeedback(next);
    });

    final size = MediaQuery.of(context).size;
    final bool isLargeScreen = size.width > 390 || size.height > 1115;

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
                    selectedDuration: _selectedDuration,
                    onDurationSelected:
                        (dur) => setState(() => _selectedDuration = dur),
                    selectedGenres: _selectedGenres,
                    onGenreToggled: _onGenreToggled,
                    advancedExpanded: _advancedExpanded,
                    onToggleAdvanced: _toggleAdvanced,
                    speedKmh: _speedKmh,
                    onSpeedChanged: (val) => setState(() => _speedKmh = val),
                    restMinutes: _restMinutes,
                    onRestMinutesChanged:
                        (val) => setState(() => _restMinutes = val),
                    restFreqMin: _restFreqMin,
                    onRestFreqChanged:
                        (val) => setState(() => _restFreqMin = val),
                  ),
                  const RouteTabView(),
                  const HistoryTabView(),
                  const ProfileTabView(),
                ],
              ),
            ),
          ),

          // Floating CTA (Only visible on Home Tab)
          if (_currentTab == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 88.92 + 16,
              child: FloatingCtaButton(
                onTap:
                    () =>
                        ref
                            .read(recommendationProvider.notifier)
                            .fetchForCurrentLocation(),
              ),
            ),

          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 88.92,
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
            height: 1115,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'providers/recommendation_provider.dart';
import 'providers/weather_provider.dart';
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
    // Prime the location permission popup as soon as the Home screen opens,
    // then fetch the current weather for the Home tab's weather card.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationServiceProvider).ensurePermissionRequested();
      ref.read(weatherProvider.notifier).fetchForCurrentLocation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
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
                    onStayDurationChanged: (id) => setState(
                      () => _stayDurationMinutes = id ?? _stayDurationMinutes,
                    ),
                    spareTimeMinutes: _spareTimeMinutes,
                    onSpareTimeChanged: (id) => setState(
                      () => _spareTimeMinutes = id ?? _spareTimeMinutes,
                    ),
                    selectedGenreId: _selectedGenreId,
                    onGenreChanged: (id) =>
                        setState(() => _selectedGenreId = id),
                    // Home > search > destination results: hands off to the
                    // dedicated search screen instead of surfacing results
                    // inline on the Home tab.
                    onFindDestination: () => context.push('/destination'),
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
  }
}

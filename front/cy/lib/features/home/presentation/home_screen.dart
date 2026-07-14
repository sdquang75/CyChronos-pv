import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'providers/recommendation_provider.dart';
import 'providers/weather_provider.dart';
import 'widgets/history_tab_view.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/profile_tab_view.dart';
import 'widgets/ride_flow.dart';
import 'widgets/route_tab_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Interactive States
  int _currentTab = 0; // 0: EXPLORE, 1: RIDE, 2: STATS, 3: SETTINGS

  @override
  void initState() {
    super.initState();
    // Prime the location permission popup as soon as the Home screen opens,
    // then fetch the current weather for the Ride tab's weather card.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(locationServiceProvider).ensurePermissionRequested();
      ref.read(weatherProvider.notifier).fetchForCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: Stack(
        children: [
          // Main Body
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  // Placeholder pending a real Explore concept (passive
                  // discovery feed, TBD) — the search flow that used to
                  // live here moved to the Ride tab below.
                  RouteTabView(),
                  // Owns its own nested Navigator, so pushing the
                  // destination list / route confirm screens from here
                  // keeps that stack alive when switching to another tab.
                  RideFlow(),
                  HistoryTabView(),
                  ProfileTabView(),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar. Always pinned above the scrollable
          // content (the CTA button now scrolls with the Ride tab's list).
          Positioned(
            left: 0,
            right: 0,
            bottom: AppBottomNavigation.barHeight + 16,
            child: _buildFloatingCTA(),
          ),

          // 共通の画面下部メニューバー(HOME・HISTORY・SETTINGS)
          const Positioned(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cy/core/theme/app_colors.dart';
import 'package:cy/core/widgets/app_screen_frame.dart';
import 'providers/recommendation_provider.dart';
import 'providers/weather_provider.dart';
import 'widgets/explore_flow.dart';
import 'widgets/history_tab_view.dart';
import 'widgets/home_bottom_nav_bar.dart';
import 'widgets/profile_tab_view.dart';
import 'widgets/route_tab_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Interactive States
  int _currentTab = 0; // 0: HOME, 1: ROUTE, 2: HISTORY, 3: PROFILE

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
  Widget build(BuildContext context) {
    return AppScreenFrame(child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCool,
      body: Stack(
        children: [
          // Main Dynamic Body based on Selected Tab
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  // Owns its own nested Navigator, so pushing the
                  // destination list / route confirm screens from here
                  // keeps that stack alive when switching to another tab.
                  ExploreFlow(),
                  RouteTabView(),
                  HistoryTabView(),
                  ProfileTabView(),
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

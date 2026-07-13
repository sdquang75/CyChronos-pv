import 'package:flutter/material.dart';
import 'package:cy/features/destination/presentation/destination_list_screen.dart';
import 'home_tab_view.dart';

// Owns the Ride tab's own navigation stack: planner (root) → destination
// search results → route confirm, all pushed via a plain Navigator instead
// of GoRouter. Because this whole widget lives inside HomeScreen's
// IndexedStack, switching to another bottom-nav tab and back keeps this
// Navigator (and whichever screen was on top) alive instead of resetting it.
class RideFlow extends StatefulWidget {
  const RideFlow({super.key});

  @override
  State<RideFlow> createState() => _RideFlowState();
}

class _RideFlowState extends State<RideFlow> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _openDestinationList(int minutes, String type) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => DestinationListScreen(minutes: minutes, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => HomeTabView(onFindDestination: _openDestinationList),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../destination/presentation/destination_list_screen.dart';
import 'home_tab_view.dart';

/// HOMEタブ専用のナビゲーションスタックを持つ。プランナー(ルート)→
/// 目的地一覧→詳細→ルート確認は、go_routerではなくこの中の
/// 素のNavigatorでpushする。RideFlow自体はHomeScreenのIndexedStackの
/// 中に常駐しているので、他のタブに切り替えて戻ってきても
/// このNavigator(と積み上がっている画面)はそのまま残る
class RideFlow extends StatefulWidget {
  const RideFlow({super.key});

  @override
  State<RideFlow> createState() => _RideFlowState();
}

class _RideFlowState extends State<RideFlow> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _openDestinationList(List<dynamic> places, int minutes, String type) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (_) => DestinationListScreen(
              places: places,
              minutes: minutes,
              type: type,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute:
          (settings) => MaterialPageRoute(
            settings: settings,
            builder:
                (_) => HomeTabView(onFindDestination: _openDestinationList),
          ),
    );
  }
}

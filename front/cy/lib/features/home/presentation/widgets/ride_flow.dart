import 'package:flutter/material.dart';

import '../../../destination/presentation/destination_list_screen.dart';
import 'home_tab_view.dart';

/// HOMEタブ専用のナビゲーションスタックを持つ。プランナー(ルート)→
/// 目的地一覧→詳細→ルート確認は、go_routerではなくこの中の
/// 素のNavigatorでpushする。RideFlow自体はHomeScreenのIndexedStackの
/// 中に常駐しているので、他のタブに切り替えて戻ってきても
/// このNavigator(と積み上がっている画面)はそのまま残る
///
/// navigatorKeyは省略可能: 親(HomeScreen)がHOMEタブ再タップ時に
/// popUntil(ルートまで一気に戻す)したい場合はここにキーを渡す
class RideFlow extends StatefulWidget {
  const RideFlow({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<RideFlow> createState() => _RideFlowState();
}

class _RideFlowState extends State<RideFlow> {
  late final GlobalKey<NavigatorState> _navigatorKey =
      widget.navigatorKey ?? GlobalKey<NavigatorState>();

  void _openDestinationList(int minutes, String type) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (_) => DestinationListScreen(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_screen_frame.dart';
import '../../history/presentation/history_screen.dart';
import '../../history/presentation/providers/history_provider.dart';
import '../../route_confirm/presentation/providers/navigation_state_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import 'widgets/ride_flow.dart';

/// HOME・HISTORY・SETTINGSタブの入れ物(シェル)。IndexedStackで3タブを常駐させ、
/// タブを切り替えても各タブの状態(スクロール位置・入力中の検索条件・
/// RideFlowの中でpushした画面など)を保持したままにする。
/// go_routerの'/home'ルートはこのシェル1枚だけで、タブ切り替え自体は
/// ページ遷移ではなくIndexedStackのインデックス変更で行う
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 0: HOME(RideFlow), 1: HISTORY, 2: SETTINGS
  int _currentTab = 0;

  // RideFlowの入れ子Navigatorを外(このシェル)から操作するためのキー。
  // HOMEタブ再タップ時に、目的地一覧/詳細/ルート確認を全部閉じて
  // プランナー画面まで一気に戻すのに使う
  final GlobalKey<NavigatorState> _rideFlowNavigatorKey =
      GlobalKey<NavigatorState>();

  void _handleTabTap(int index) {
    // 既にHOMEタブを表示中に、もう一度HOMEを押した場合。
    // 通常はプランナー画面まで一気に戻すが、案内・走行中は誤タップで
    // ナビゲーションが終了してしまう重大な事故を防ぐため無効化する
    if (index == 0 && _currentTab == 0) {
      final isNavigating = ref.read(isTripNavigatingProvider);
      if (isNavigating) {
        // 案内中・走行中の誤タップを防止
        return;
      }
      _rideFlowNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    if (index == 1) {
      // HISTORYタブをタップした時は常に最新の履歴をサーバーから静かに同期する
      ref.read(historyProvider.notifier).loadTrips();
    }
    setState(() => _currentTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenFrame(
      child: Scaffold(
        backgroundColor: AppColors.bgCool,
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  // 自前の入れ子Navigatorを持つので、目的地一覧/詳細/ルート確認を
                  // 開いた状態のまま他のタブへ切り替えて戻ってきても維持される
                  RideFlow(navigatorKey: _rideFlowNavigatorKey),
                  const HistoryScreen(),
                  const SettingsScreen(),
                ],
              ),
            ),

            // 共通の画面下部メニューバー(HOME・HISTORY・SETTINGS)。
            // IndexedStackの上に常に浮かせておくので、RideFlow内で
            // 目的地一覧/詳細画面を開いている間も表示され続ける
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: AppBottomNavigation.barHeightFor(context),
              child: AppBottomNavigation(
                currentIndex: _currentTab,
                onTap: _handleTabTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

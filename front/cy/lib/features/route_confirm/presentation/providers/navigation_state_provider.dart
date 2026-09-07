import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 案内モード中(往路案内・滞在・復路案内)かどうかを管理するProvider。
/// HomeScreenなどの親ウィジェットが、案内中の誤操作(HOMEボタン再タップによるリセット)
/// を防ぐために参照する。
final isTripNavigatingProvider = StateProvider<bool>((ref) => false);

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 画面上部にふわっと現れて自動で消える、アプリらしい通知トースト。
/// Material標準のSnackBar(画面下端に全幅で張り付く帯)は「Webのトーストを
/// そのままアプリに移植した」ような見た目になってしまうため、既存の
/// 浮遊カード(距離/時間チップ、情報バー)と同じデザイン言語
/// (白背景・角丸・シャドウ)に揃えて自作している。
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  /// トーストを表示する。連続で呼ばれた場合は前のトーストを即座に消して
  /// 出し直す(SnackBarのclearSnackBars()相当)
  static void show(BuildContext context, String message, {bool isError = false}) {
    clear();

    final overlayState = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder:
          (_) => _ToastCard(
            message: message,
            isError: isError,
            onDismissed: () {
              if (identical(_current, entry)) {
                _current = null;
              }
              entry.remove();
            },
          ),
    );
    _current = entry;
    overlayState.insert(entry);
  }

  /// 現在表示中のトーストを即座に消去する
  static void clear() {
    _current?.remove();
    _current = null;
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.message,
    required this.isError,
    required this.onDismissed,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismissed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismissTimer = Timer(const Duration(milliseconds: 2400), _dismiss);
  }

  Future<void> _dismiss() async {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.isError ? AppColors.error : AppColors.primary;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_rounded,
                        size: 20,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            fontFamily: 'HankenGrotesk',
                            fontFamilyFallback: const ['NotoSansJP'],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

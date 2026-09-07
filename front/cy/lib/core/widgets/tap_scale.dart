import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Scales the child down slightly on press (with a light haptic tick) for a
// tactile "springy" feel, then calls [onTap] on release. Shared by any
// tappable card across the app (destination list, route summary, ...).
class TapScale extends StatefulWidget {
  const TapScale({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (value) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

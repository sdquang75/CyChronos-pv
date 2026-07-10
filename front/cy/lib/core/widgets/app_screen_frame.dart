import 'package:flutter/material.dart';

// Wraps a screen's content in the same "phone frame" HomeScreen uses, so
// every screen looks consistent across viewport sizes: full-bleed on an
// actual phone, but centered in a fixed 450x943 rounded frame with a
// shadow on wider/taller (desktop/web preview) screens.
class AppScreenFrame extends StatelessWidget {
  const AppScreenFrame({super.key, required this.child});

  final Widget child;

  // Reference phone-frame size shared by anything that needs to match it
  // (e.g. capping a modal bottom sheet's width so it doesn't stretch past
  // the frame on a wide/desktop viewport). Matches the max frame size
  // (450x943) set in the Figma design's responsive constraints, so any
  // real phone within the designed range renders full-bleed instead of
  // falling into the desktop/web preview frame.
  static const double width = 450;
  static const double height = 943;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > width || size.height > height;

    if (!isLargeScreen) return child;

    return Scaffold(
      backgroundColor: const Color(0xFF191C1F),
      body: Center(
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

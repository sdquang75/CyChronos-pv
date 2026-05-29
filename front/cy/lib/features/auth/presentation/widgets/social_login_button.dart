import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialLoginButton extends StatefulWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _pressed ? 0.95 : 1.0,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onPressed?.call();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: 64,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hovered
                    ? const Color(0xFF19005C)
                    : const Color(0xFFC9C4D5).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E0094).withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 24, height: 24, child: widget.icon),
                  const SizedBox(width: 16),
                  Text(
                    widget.label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF191C1F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

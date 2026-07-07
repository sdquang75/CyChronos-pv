import 'package:flutter/material.dart';

class SocialLoginButton extends StatefulWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
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
          onTapDown:
              widget.isLoading ? null : (_) => setState(() => _pressed = true),
          onTapUp:
              widget.isLoading
                  ? null
                  : (_) {
                    setState(() => _pressed = false);
                    widget.onPressed?.call();
                  },
          onTapCancel:
              widget.isLoading ? null : () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _hovered
                        ? const Color(0xFF8BA88E)
                        : const Color(0xFFC4C8C0).withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child:
                        widget.isLoading
                            ? const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF8BA88E),
                              ),
                            )
                            : widget.icon,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontFamilyFallback: ['NotoSansJP'],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
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

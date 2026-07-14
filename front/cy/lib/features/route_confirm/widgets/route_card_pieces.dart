import 'package:flutter/material.dart';
import 'package:cy/core/theme/app_colors.dart';

// Reusable pieces of the Figma "Confirm Route" Bottom Action Card
// (waypoint badge, distance/time metric, divider, "start"
// button). Shared between RouteConfirmScreen and DestinationListScreen so
// every route summary card looks identical wherever it appears.

class WaypointBadge extends StatelessWidget {
  const WaypointBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenChipBgLight,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'HankenGrotesk',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.24,
          color: AppColors.greenPrimary,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class RouteMetric extends StatelessWidget {
  const RouteMetric({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            letterSpacing: 0.6,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.greenPrimary,
            height: 24 / 18,
          ),
        ),
      ],
    );
  }
}

class MetricDivider extends StatelessWidget {
  const MetricDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.dividerLight);
  }
}

// Pins the primary action button (RouteStartButton) outside the scrollable
// content at a fixed bottom padding, so it lands at the same screen
// position on both Spot Details and Confirm Route regardless of how much
// text is above it — same tap spot on either screen. Bottom padding clears
// HomeBottomNavBar's floating pill, which overlays these pushed screens.
class PinnedRouteActionButton extends StatelessWidget {
  const PinnedRouteActionButton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
      child: child,
    );
  }
}

// "Actions → Button" from Figma: solid green pill/rect with a leading icon.
class RouteStartButton extends StatelessWidget {
  const RouteStartButton({
    super.key,
    required this.onTap,
    this.label = 'start',
    this.icon = Icons.map_rounded,
    this.height = 56,
  });

  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.greenPrimary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

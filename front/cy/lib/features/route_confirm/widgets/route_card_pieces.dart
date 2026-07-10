import 'package:flutter/material.dart';

// Reusable pieces of the Figma "Confirm Route" Bottom Action Card
// (waypoint badge, distance/time/elevation metric, divider, "start"
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
        color: const Color(0xFFDDE6DE),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'HankenGrotesk',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.24,
          color: Color(0xFF4A654E),
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
            color: Color(0xFF424842),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'HankenGrotesk',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF4A654E),
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
    return Container(width: 1, height: 32, color: const Color(0xFFE4E2E1));
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
  final IconData icon;
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
            color: const Color(0xFF4A654E),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B1C1C).withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
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

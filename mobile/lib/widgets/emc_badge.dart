import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

/// Reusable EMC Points badge - identical everywhere in the app.
/// Used on Featured Carousel, Content Cards, and anywhere EMC points are shown.
class EmcBadge extends StatelessWidget {
  final String points;
  
  const EmcBadge({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 14, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/EMC.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                points,
                style: const TextStyle(
                  color: PulseTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.0,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Puncte EMC',
                style: TextStyle(
                  color: PulseTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


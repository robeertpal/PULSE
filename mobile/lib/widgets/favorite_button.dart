import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

class FavoriteButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback? onTap;
  final String savedLabel;
  final String unsavedLabel;

  const FavoriteButton({
    super.key,
    required this.isSaved,
    required this.onTap,
    this.savedLabel = 'Elimină din salvate',
    this.unsavedLabel = 'Salvează',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: isSaved ? savedLabel : unsavedLabel,
        child: Opacity(
          opacity: onTap == null ? 0.62 : 1,
          child: AnimatedContainer(
            duration: PulseTheme.animFast,
            curve: PulseTheme.animCurve,
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSaved
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSaved
                    ? Colors.white.withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/icons/heart.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isSaved ? const Color(0xFFFF4B4B) : Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContentTypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String? iconAsset;
  final bool iconOnly;

  const ContentTypeBadge({
    super.key,
    required this.label,
    required this.color,
    this.iconAsset,
    this.iconOnly = false,
  }) : assert(
          !iconOnly || iconAsset != null,
          'iconAsset must be provided when iconOnly is true',
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset!,
              width: iconOnly ? 14 : 12,
              height: iconOnly ? 14 : 12,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            if (!iconOnly) const SizedBox(width: 4),
          ],
          if (!iconOnly)
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
        ],
      ),
    );
  }
}

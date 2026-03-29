import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import 'emc_badge.dart';

class ContentCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color categoryColor;
  final String iconAsset;
  final double? progress;
  final String? emcPoints;

  const ContentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.categoryColor,
    required this.iconAsset,
    this.progress,
    this.emcPoints,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      onTap: () {},
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 240,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: PulseTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PulseTheme.border.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: widget.categoryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Area with Gradient ──
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.categoryColor.withOpacity(0.12),
                        widget.categoryColor.withOpacity(0.04),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circle
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.categoryColor.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.categoryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              widget.iconAsset,
                              width: 28,
                              height: 28,
                              colorFilter: ColorFilter.mode(
                                widget.categoryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // EMC Points badge (consistent with featured cards)
                      if (widget.emcPoints != null)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: EmcBadge(points: widget.emcPoints!),
                        ),
                    ],
                  ),
                ),
                // ── Text Content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.tag.toUpperCase(),
                            style: TextStyle(
                              color: widget.categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PulseTheme.textPrimary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        // Subtitle / meta
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.categoryColor.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: PulseTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Optional progress bar
                        if (widget.progress != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: widget.progress!,
                              minHeight: 4,
                              backgroundColor: widget.categoryColor.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(widget.categoryColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

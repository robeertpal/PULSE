import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

class QuickAction {
  final String label;
  final String svgAsset;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    required this.label,
    required this.svgAsset,
    required this.color,
    this.onTap,
  });
}

class QuickActionsStrip extends StatelessWidget {
  const QuickActionsStrip({super.key});

  static final List<QuickAction> _actions = [
    QuickAction(
      label: 'AI Assistant',
      svgAsset: 'assets/icons/AI.svg',
      color: PulseTheme.primary,
    ),
    QuickAction(
      label: 'Scaner EMC',
      svgAsset: 'assets/icons/sharedwithyou.svg',
      color: PulseTheme.magazineContent,
    ),
    QuickAction(
      label: 'Puncte EMC',
      svgAsset: 'assets/icons/EMC.svg',
      color: PulseTheme.courseContent,
    ),
    QuickAction(
      label: 'Favorite',
      svgAsset: 'assets/icons/heart.svg',
      color: PulseTheme.newsContent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actions.map((action) => _QuickActionCapsule(action: action)).toList(),
      ),
    );
  }
}

class _QuickActionCapsule extends StatefulWidget {
  final QuickAction action;

  const _QuickActionCapsule({required this.action});

  @override
  State<_QuickActionCapsule> createState() => _QuickActionCapsuleState();
}

class _QuickActionCapsuleState extends State<_QuickActionCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: action.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: action.color.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  action.svgAsset,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    action.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: PulseTheme.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

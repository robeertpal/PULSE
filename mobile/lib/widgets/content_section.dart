import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import 'empty_state_card.dart';

class ContentSection extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionTap;
  final List<Widget> children;
  final String emptyMessage;
  final String emptyIconAsset;
  final Color categoryColor;

  const ContentSection({
    super.key,
    required this.title,
    this.actionText = 'Vezi toate',
    required this.onActionTap,
    required this.children,
    required this.emptyMessage,
    required this.emptyIconAsset,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Accent bar ──
                  Container(
                    width: 3.5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              // ── „Vezi toate" capsule button ──
              GestureDetector(
                onTap: onActionTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryColor.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText,
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/icons/arrow.right.svg',
                        width: 12,
                        height: 12,
                        colorFilter: ColorFilter.mode(
                          categoryColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: children.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: EmptyStateCard(
                    message: emptyMessage,
                    iconAsset: emptyIconAsset,
                    baseColor: categoryColor,
                  ),
                )
              : ListView.builder(
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.only(left: 20.0, right: 4.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    return children[index];
                  },
                ),
        ),
      ],
    );
  }
}

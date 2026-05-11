import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'empty_state_card.dart';

class ContentSection extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onActionTap;
  final List<Widget> children;
  final String emptyMessage;
  final String emptyIconAsset;
  final Color categoryColor;
  final bool editorialLayout;
  final Widget? featuredChild;

  const ContentSection({
    super.key,
    required this.title,
    this.actionText = 'Vezi toate',
    required this.onActionTap,
    required this.children,
    required this.emptyMessage,
    required this.emptyIconAsset,
    required this.categoryColor,
    this.editorialLayout = false,
    this.featuredChild,
  });

  @override
  Widget build(BuildContext context) {
    return editorialLayout
        ? _buildEditorialSection(context)
        : _buildSimpleSection(context);
  }

  Widget _buildEditorialSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Positioned(
            right: 18,
            top: 10,
            child: IgnorePointer(
              child: SvgPicture.asset(
                emptyIconAsset,
                width: 86,
                height: 86,
                colorFilter: ColorFilter.mode(
                  categoryColor.withValues(alpha: 0.12),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildHeader(context, compact: false),
              ),
              if (featuredChild != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: featuredChild!,
                ),
              ],
              if (children.isNotEmpty || featuredChild == null) ...[
                const SizedBox(height: 18),
                _buildRail(leftPadding: 20, rightPadding: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildHeader(context, compact: true),
        ),
        const SizedBox(height: 18),
        _buildRail(leftPadding: 20, rightPadding: 4),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required bool compact}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 3),
                Container(
                  width: 48,
                  height: 2,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionText.isNotEmpty) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.14),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 5),
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
      ],
    );
  }

  Widget _buildRail({
    required double leftPadding,
    required double rightPadding,
  }) {
    return SizedBox(
      height: 300,
      child: children.isEmpty
          ? Padding(
              padding: EdgeInsets.only(left: leftPadding),
              child: EmptyStateCard(
                message: emptyMessage,
                iconAsset: emptyIconAsset,
                baseColor: categoryColor,
              ),
            )
          : ListView.builder(
              clipBehavior: Clip.none,
              padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
            ),
    );
  }
}

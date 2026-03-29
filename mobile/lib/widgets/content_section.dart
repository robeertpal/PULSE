import 'package:flutter/material.dart';
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
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  foregroundColor: PulseTheme.primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
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

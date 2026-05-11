import 'package:flutter/material.dart';
import '../theme/pulse_theme.dart';

enum SkeletonLoadingType { feed, detail, list, profile }

class SkeletonLoading extends StatelessWidget {
  final SkeletonLoadingType type;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const SkeletonLoading({
    super.key,
    required this.type,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 32),
    this.scrollable = true,
  });

  const SkeletonLoading.feed({super.key, this.scrollable = true})
    : type = SkeletonLoadingType.feed,
      padding = const EdgeInsets.fromLTRB(20, 20, 20, 32);

  const SkeletonLoading.detail({super.key, this.scrollable = true})
    : type = SkeletonLoadingType.detail,
      padding = const EdgeInsets.fromLTRB(20, 16, 20, 34);

  const SkeletonLoading.list({super.key, this.scrollable = true})
    : type = SkeletonLoadingType.list,
      padding = const EdgeInsets.fromLTRB(20, 20, 20, 32);

  const SkeletonLoading.profile({super.key, this.scrollable = true})
    : type = SkeletonLoadingType.profile,
      padding = const EdgeInsets.all(20);

  @override
  Widget build(BuildContext context) {
    final children = switch (type) {
      SkeletonLoadingType.feed => _feedSkeleton(),
      SkeletonLoadingType.detail => _detailSkeleton(),
      SkeletonLoadingType.list => _listSkeleton(),
      SkeletonLoadingType.profile => _profileSkeleton(),
    };

    if (!scrollable) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: padding,
      children: children,
    );
  }

  List<Widget> _feedSkeleton() {
    return [
      const SkeletonBlock(height: 44, radius: 22),
      const SizedBox(height: 22),
      const SkeletonBlock(height: 252, radius: 28),
      const SizedBox(height: 32),
      ...List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(width: 136, height: 22, radius: 10),
              SizedBox(height: 14),
              SkeletonBlock(height: 220, radius: 28),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _detailSkeleton() {
    return const [
      SkeletonBlock(height: 280, radius: 30),
      SizedBox(height: 24),
      SkeletonBlock(width: 118, height: 20, radius: 10),
      SizedBox(height: 14),
      SkeletonBlock(height: 30, radius: 12),
      SizedBox(height: 10),
      SkeletonBlock(width: 240, height: 18, radius: 9),
      SizedBox(height: 28),
      SkeletonBlock(height: 120, radius: 24),
      SizedBox(height: 18),
      SkeletonBlock(height: 210, radius: 26),
    ];
  }

  List<Widget> _listSkeleton() {
    return [
      const SkeletonBlock(width: 180, height: 26, radius: 12),
      const SizedBox(height: 18),
      ...List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonBlock(height: 136, radius: 24),
        ),
      ),
    ];
  }

  List<Widget> _profileSkeleton() {
    return const [
      SkeletonBlock(height: 110, radius: 26),
      SizedBox(height: 18),
      SkeletonBlock(height: 76, radius: 22),
      SizedBox(height: 12),
      SkeletonBlock(height: 76, radius: 22),
      SizedBox(height: 12),
      SkeletonBlock(height: 76, radius: 22),
    ];
  }
}

class SkeletonBlock extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = PulseTheme.border.withValues(alpha: 0.46);
    final highlightColor = Colors.white.withValues(alpha: 0.74);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + (_controller.value * 2.8), 0),
              end: Alignment(-0.4 + (_controller.value * 2.8), 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}

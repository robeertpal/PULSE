import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/content_item.dart';
import '../theme/pulse_theme.dart';
import 'emc_badge.dart';

class FeaturedCard extends StatefulWidget {
  final List<ContentItem> items;
  final bool isLoading;

  const FeaturedCard({super.key, required this.items, this.isLoading = false});

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _pageController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void didUpdateWidget(covariant FeaturedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.isEmpty && widget.items.isNotEmpty) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      return;
    }

    if (widget.items.length < oldWidget.items.length &&
        widget.items.isNotEmpty) {
      _currentPage = _currentPage.clamp(0, widget.items.length - 1).toDouble();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading && widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 760.0);
        final height = constraints.maxWidth >= 700 ? 300.0 : 252.0;

        return Center(
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                SizedBox(
                  height: height,
                  child: widget.isLoading
                      ? const _FeaturedSkeleton()
                      : PageView.builder(
                          clipBehavior: Clip.none,
                          controller: _pageController,
                          itemCount: widget.items.length,
                          itemBuilder: (context, index) {
                            final item = widget.items[index];
                            final distance = (_currentPage - index).abs();
                            final scale =
                                1 - (distance * 0.045).clamp(0.0, 0.045);

                            return Transform.scale(
                              scale: scale,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: _FeaturedSlide(item: item),
                              ),
                            );
                          },
                        ),
                ),
                if (!widget.isLoading && widget.items.length > 1) ...[
                  const SizedBox(height: 14),
                  _FeaturedIndicators(
                    count: widget.items.length,
                    currentIndex: _currentPage.round().clamp(
                      0,
                      widget.items.length - 1,
                    ),
                    activeColor: _colorForType(
                      widget
                          .items[_currentPage.round().clamp(
                            0,
                            widget.items.length - 1,
                          )]
                          .contentType,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeaturedSlide extends StatelessWidget {
  final ContentItem item;

  const _FeaturedSlide({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(item.contentType);
    final imageUrl = _chooseImageUrl(item);
    final subtitle =
        item.shortDescription ??
        item.publicationDescription ??
        item.specializationName ??
        item.categoryName ??
        '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              _FeaturedImage(imageUrl: imageUrl, fallbackColor: color)
            else
              _FeaturedFallback(color: color),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.26),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.0, 0.44, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.42),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            if (item.emcCredits != null)
              Positioned(
                right: 16,
                top: 16,
                child: EmcBadge(points: '+${item.emcCredits}'),
              ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _TypeBadge(
                        label: item.tag ?? _labelForType(item.contentType),
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      if (item.publishedAt != null)
                        Flexible(
                          child: Text(
                            _formatDate(item.publishedAt!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.publicationName ?? item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedImage extends StatelessWidget {
  final String imageUrl;
  final Color fallbackColor;

  const _FeaturedImage({required this.imageUrl, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    if (_isRemote(imageUrl)) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _FeaturedFallback(color: fallbackColor);
        },
      );
    }

    if (imageUrl.startsWith('assets/') || imageUrl.startsWith('images/')) {
      final assetPath = imageUrl.startsWith('assets/')
          ? imageUrl
          : 'assets/$imageUrl';
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _FeaturedFallback(color: fallbackColor);
        },
      );
    }

    return _FeaturedFallback(color: fallbackColor);
  }
}

class _FeaturedFallback extends StatelessWidget {
  final Color color;

  const _FeaturedFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.92),
            PulseTheme.primary.withValues(alpha: 0.84),
            PulseTheme.textPrimary,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/newspaper.svg',
              width: 34,
              height: 34,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _FeaturedIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;

  const _FeaturedIndicators({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: PulseTheme.animMedium,
          curve: PulseTheme.animCurve,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : PulseTheme.border,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: PulseTheme.shimmerGradient,
        boxShadow: PulseTheme.cardShadow,
      ),
    );
  }
}

String? _chooseImageUrl(ContentItem item) {
  final thumbnail = item.thumbnailUrl?.trim();
  final hero = item.heroImageUrl?.trim();
  final logo = item.publicationLogoUrl?.trim();

  if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;
  if (hero != null && hero.isNotEmpty) return hero;
  if (logo != null && logo.isNotEmpty) return logo;
  return null;
}

bool _isRemote(String value) {
  return value.startsWith('http://') || value.startsWith('https://');
}

Color _colorForType(String type) {
  switch (type) {
    case 'course':
      return PulseTheme.courseContent;
    case 'event':
      return PulseTheme.eventContent;
    case 'publication':
      return PulseTheme.magazineContent;
    case 'news':
      return PulseTheme.newsContent;
    case 'article':
      return PulseTheme.primary;
    default:
      return PulseTheme.primary;
  }
}

String _labelForType(String type) {
  switch (type) {
    case 'course':
      return 'Curs';
    case 'event':
      return 'Eveniment';
    case 'publication':
      return 'Revistă';
    case 'news':
      return 'Știre';
    case 'article':
      return 'Articol';
    default:
      return type;
  }
}

String _formatDate(DateTime date) {
  const months = [
    'ian',
    'feb',
    'mar',
    'apr',
    'mai',
    'iun',
    'iul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

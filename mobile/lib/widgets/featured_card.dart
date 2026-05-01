import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import 'emc_badge.dart';

import '../models/content_item.dart';

class FeaturedCard extends StatefulWidget {
  final List<ContentItem> items;

  const FeaturedCard({super.key, required this.items});

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  late PageController _pageController;
  double _currentPage = 0;

  List<ContentItem> get _items => widget.items;

  Color _getPrimaryColor(String type) {
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

  String _getButtonText(String type) {
    switch (type) {
      case 'course':
        return 'Începe cursul';
      case 'event':
        return 'Vezi detalii';
      case 'publication':
        return 'Răsfoiește';
      case 'news':
        return 'Citește știrea';
      case 'article':
        return 'Citește articolul';
      default:
        return 'Vezi detalii';
    }
  }

  bool _isRemote(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  String? _chooseImageUrl(ContentItem item) {
    final thumbnail = item.thumbnailUrl?.trim();
    final hero = item.heroImageUrl?.trim();

    if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;
    if (hero != null && hero.isNotEmpty) return hero;
    return null;
  }

  String _assetPathFor(String rawUrl) {
    if (rawUrl.startsWith('assets/')) return rawUrl;
    if (rawUrl.startsWith('images/')) return 'assets/$rawUrl';
    return 'assets/images/$rawUrl';
  }

  Widget _buildBackgroundImage(ContentItem item, Color fallbackColor) {
    final imageUrl = _chooseImageUrl(item);
    if (imageUrl == null) {
      return _buildFallbackBackground(fallbackColor);
    }

    final image = _isRemote(imageUrl)
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackBackgroundContent(fallbackColor),
          )
        : Image.asset(
            _assetPathFor(imageUrl),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackBackgroundContent(fallbackColor),
          );

    return Positioned.fill(child: image);
  }

  Widget _buildFallbackBackground(Color colorPrimary) {
    return Positioned.fill(
      child: _buildFallbackBackgroundContent(colorPrimary),
    );
  }

  Widget _buildFallbackBackgroundContent(Color colorPrimary) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorPrimary,
            colorPrimary.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.78),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 270,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: _pageController,
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              // Calculate scale and opacity based on distance from current page
              double distance = (_currentPage - index).abs();
              double scale = 1.0 - (distance * 0.08).clamp(0.0, 0.08);
              double opacity = 1.0 - (distance * 0.3).clamp(0.0, 0.3);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: scale, end: scale),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildCardItem(item, index),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // â”€â”€ Page Indicators â”€â”€
        _buildPageIndicators(),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_items.length, (index) {
        double distance = (_currentPage - index).abs().clamp(0.0, 1.0);
        Color dotColor = Color.lerp(
          _getPrimaryColor(
            _items[_currentPage.round().clamp(0, _items.length - 1)]
                .contentType,
          ),
          PulseTheme.border,
          distance,
        )!;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: distance < 0.5 ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: distance < 0.5
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildCardItem(ContentItem item, int index) {
    final colorPrimary = _getPrimaryColor(item.contentType);
    final String emcPoints = item.emcCredits != null
        ? '+${item.emcCredits}'
        : '';
    final String buttonText = _getButtonText(item.contentType);
    final String tagText =
        item.tag?.toUpperCase() ?? item.contentType.toUpperCase();
    final String subtitleText =
        item.shortDescription ??
        (item.body != null && item.body!.length > 100
            ? '${item.body!.substring(0, 100)}...'
            : '');
    final String? buttonIcon = item.contentType == 'article'
        ? 'assets/icons/AI.svg'
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorPrimary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _buildBackgroundImage(item, colorPrimary),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      colorPrimary.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.74),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.14),
                      Colors.black.withValues(alpha: 0.44),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
            // EMC Badge
            if (emcPoints.isNotEmpty)
              Positioned(
                right: 16,
                top: 16,
                child: EmcBadge(points: emcPoints),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tagText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      subtitleText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Premium CTA button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show gradient AI icon or arrow based on buttonIcon
                          if (buttonIcon != null) ...[
                            _buildGradientIcon(buttonIcon, colorPrimary),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (buttonIcon == null) ...[
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              'assets/icons/arrow.right.svg',
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                colorPrimary,
                                BlendMode.srcIn,
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
          ],
        ),
      ),
    );
  }

  Widget _buildGradientIcon(String assetPath, Color primaryColor) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB), // Blue
            Color(0xFF8B5CF6), // Violet
            Color(0xFFEC4899), // Pink
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: SvgPicture.asset(assetPath, width: 20, height: 20),
    );
  }
}

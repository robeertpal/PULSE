import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/content_item.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/auth_shell.dart';
import 'login_screen.dart';
import 'register_page.dart';

class AuthWelcomeScreen extends StatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  State<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends State<AuthWelcomeScreen>
    with TickerProviderStateMixin {
  final _apiService = ApiService();
  late final AnimationController _backgroundController;
  late final AnimationController _contentRailController;
  List<_ContentPreviewItem> _contentRailItems = _fallbackPreviewItems;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _contentRailController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 66),
    )..repeat();
    _loadContentRailItems();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentRailController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadContentRailItems() async {
    try {
      final results = await Future.wait([
        _apiService.getNews(limit: 4),
        _apiService.getPublications(limit: 4),
        _apiService.getEvents(limit: 4),
        _apiService.getCourses(limit: 4),
      ]);
      final items = _interleaveContentItems(results)
          .map(_ContentPreviewItem.fromContentItem)
          .where((item) => item.title.trim().isNotEmpty)
          .take(10)
          .toList();
      if (!mounted || items.isEmpty) return;
      setState(() => _contentRailItems = items);
    } catch (_) {
      // Decorative preview only: keep the static fallback if public content fails.
    }
  }

  List<ContentItem> _interleaveContentItems(List<List<ContentItem>> groups) {
    final items = <ContentItem>[];
    final maxLength = groups.fold<int>(
      0,
      (max, group) => group.length > max ? group.length : max,
    );
    for (var index = 0; index < maxLength; index++) {
      for (final group in groups) {
        if (index < group.length) items.add(group[index]);
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AnimatedWelcomeBackground(animation: _backgroundController),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 720;
                final wide = constraints.maxWidth >= 720;
                final horizontalPadding = wide ? 36.0 : 24.0;
                final bottomPadding = compactHeight ? 74.0 : 96.0;
                final railTop = compactHeight ? 96.0 : 120.0;
                final railHeight = compactHeight ? 266.0 : 336.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 520 : 430),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: railTop,
                          height: railHeight,
                          child: _ContentPreviewRail(
                            animation: _contentRailController,
                            compact: compactHeight,
                            items: _contentRailItems,
                          ),
                        ),
                        const Positioned.fill(child: _ContentRailOverlay()),
                        Positioned(
                          top: compactHeight ? 18 : 28,
                          left: horizontalPadding,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: wide ? 76 : 63,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              132,
                              horizontalPadding,
                              bottomPadding,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _WelcomeCopy(),
                                SizedBox(height: compactHeight ? 24 : 32),
                                _WelcomeActions(
                                  onLogin: () => _open(const LoginScreen()),
                                  onCreateAccount: () =>
                                      _open(const RegisterPage()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWelcomeBackground extends StatelessWidget {
  const _AnimatedWelcomeBackground({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020617),
            Color(0xFF050B1A),
            Color(0xFF090B18),
            Color(0xFF050B1A),
          ],
          stops: [0, 0.42, 0.76, 1],
        ),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(animation.value);
          return Stack(
            fit: StackFit.expand,
            children: [
              _GlowBlob(
                color: AuthShell.pulsePurple,
                size: 300,
                opacity: 0.16,
                alignment: Alignment(-0.86 + (0.1 * t), -0.88 + (0.06 * t)),
                blur: 88,
              ),
              _GlowBlob(
                color: AuthShell.pulsePurple,
                size: 340,
                opacity: 0.18,
                alignment: Alignment(0.72 - (0.1 * t), -0.2 + (0.06 * t)),
                blur: 98,
              ),
              _GlowBlob(
                color: AuthShell.pulseOrange,
                size: 260,
                opacity: 0.11,
                alignment: Alignment(0.28 + (0.08 * t), 0.9 - (0.06 * t)),
                blur: 104,
              ),
              _GlowBlob(
                color: AuthShell.pulseViolet,
                size: 220,
                opacity: 0.1,
                alignment: Alignment(-0.48 - (0.06 * t), 0.32 + (0.08 * t)),
                blur: 96,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.58),
                    ],
                    stops: const [0.22, 1],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
    required this.alignment,
    required this.blur,
  });

  final Color color;
  final double size;
  final double opacity;
  final Alignment alignment;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentRailOverlay extends StatelessWidget {
  const _ContentRailOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.38),
              Colors.black.withValues(alpha: 0.28),
              Colors.black.withValues(alpha: 0.56),
            ],
            stops: const [0, 0.34, 0.58, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.04),
              radius: 0.86,
              colors: [
                Colors.black.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.46),
              ],
              stops: const [0.32, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentPreviewItem {
  const _ContentPreviewItem({
    required this.type,
    required this.title,
    required this.iconAsset,
    required this.accent,
    this.imageUrl,
  });

  final String type;
  final String title;
  final String iconAsset;
  final Color accent;
  final String? imageUrl;

  factory _ContentPreviewItem.fromContentItem(ContentItem item) {
    return _ContentPreviewItem(
      type: _labelForContentType(item.contentType),
      title: item.publicationName ?? item.title,
      iconAsset: _iconForContentType(item.contentType),
      accent: _colorForContentType(item.contentType),
      imageUrl: _imageUrlForContentItem(item),
    );
  }
}

const _fallbackPreviewItems = [
  _ContentPreviewItem(
    type: 'Știre',
    title: 'Noutăți medicale actualizate',
    iconAsset: 'assets/icons/newspaper.svg',
    accent: PulseTheme.newsContent,
  ),
  _ContentPreviewItem(
    type: 'Revistă',
    title: 'Publicații profesionale',
    iconAsset: 'assets/icons/books.svg',
    accent: PulseTheme.magazineContent,
  ),
  _ContentPreviewItem(
    type: 'Eveniment',
    title: 'Evenimente EMC',
    iconAsset: 'assets/icons/events.svg',
    accent: PulseTheme.eventContent,
  ),
  _ContentPreviewItem(
    type: 'Curs',
    title: 'Dezvoltare profesională',
    iconAsset: 'assets/icons/graduation.svg',
    accent: PulseTheme.courseContent,
  ),
  _ContentPreviewItem(
    type: 'Știre',
    title: 'Perspective clinice relevante',
    iconAsset: 'assets/icons/newspaper.svg',
    accent: PulseTheme.newsContent,
  ),
  _ContentPreviewItem(
    type: 'Revistă',
    title: 'Reviste și ghiduri utile',
    iconAsset: 'assets/icons/books.svg',
    accent: PulseTheme.magazineContent,
  ),
];

class _ContentPreviewRail extends StatelessWidget {
  const _ContentPreviewRail({
    required this.animation,
    required this.compact,
    required this.items,
  });

  final Animation<double> animation;
  final bool compact;
  final List<_ContentPreviewItem> items;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactScale = (screenWidth / 390).clamp(0.8, 1.0).toDouble();
    final scale = compact ? compactScale : 1.0;
    final cardWidth = (compact ? 205.0 : 252.0) * scale;
    final cardHeight = (compact ? 148.0 : 180.0) * scale;
    final gap = (compact ? 15.0 : 20.0) * scale;
    final stride = cardWidth + gap;
    final previewItems = items.isEmpty ? _fallbackPreviewItems : items;
    final cycleWidth = stride * previewItems.length;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: Center(
              child: Transform.rotate(
                angle: -0.13,
                child: SizedBox(
                  height: cardHeight + (compact ? 62 : 82),
                  width: constraints.maxWidth,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 0,
                    maxWidth: cycleWidth * 3,
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        final offset = -cycleWidth * (1 + animation.value);
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: SizedBox(
                            width: cycleWidth * 3,
                            child: Row(
                              children: [
                                for (var copy = 0; copy < 3; copy++)
                                  for (final item in previewItems) ...[
                                    _ContentPreviewCard(
                                      item: item,
                                      width: cardWidth,
                                      height: cardHeight,
                                    ),
                                    SizedBox(width: gap),
                                  ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContentPreviewCard extends StatelessWidget {
  const _ContentPreviewCard({
    required this.item,
    required this.width,
    required this.height,
  });

  final _ContentPreviewItem item;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1226).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: item.accent.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 16),
              spreadRadius: -10,
            ),
            BoxShadow(
              color: item.accent.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.imageUrl != null)
              Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _ContentPreviewImageFallback(accent: item.accent),
              )
            else
              _ContentPreviewImageFallback(accent: item.accent),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(width < 200 ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.36),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            item.iconAsset,
                            width: width < 200 ? 13 : 14,
                            height: width < 200 ? 13 : 14,
                            colorFilter: ColorFilter.mode(
                              item.accent,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width < 200 ? 10.5 : 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
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
}

class _ContentPreviewImageFallback extends StatelessWidget {
  const _ContentPreviewImageFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF111A33),
            accent.withValues(alpha: 0.34),
            const Color(0xFF070B18),
          ],
        ),
      ),
    );
  }
}

Color _colorForContentType(String type) {
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

String _labelForContentType(String type) {
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

String _iconForContentType(String type) {
  switch (type) {
    case 'course':
      return 'assets/icons/graduation.svg';
    case 'event':
      return 'assets/icons/events.svg';
    case 'publication':
      return 'assets/icons/books.svg';
    case 'news':
    case 'article':
    default:
      return 'assets/icons/newspaper.svg';
  }
}

String? _imageUrlForContentItem(ContentItem item) {
  bool isUsable(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  if (isUsable(item.thumbnailUrl)) return item.thumbnailUrl;
  if (isUsable(item.heroImageUrl)) return item.heroImageUrl;
  if (isUsable(item.publicationLogoUrl)) return item.publicationLogoUrl;
  return null;
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Educație medicală.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.96),
            fontSize: 39,
            height: 1.04,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => AuthShell.pulseGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: const Text(
            'Conectată cu tine.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 39,
              height: 1.04,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Articole, reviste, cursuri și evenimente într-o experiență calmă, profesională, creată pentru ritmul tău medical.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 15.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onCreateAccount, required this.onLogin});

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AuthPrimaryButton(label: 'Autentificare', onPressed: onLogin),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AuthSecondaryButton(
            label: 'Creează cont',
            light: true,
            onPressed: onCreateAccount,
          ),
        ),
      ],
    );
  }
}

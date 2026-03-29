import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import 'emc_badge.dart';

class FeaturedItemModel {
  final String tag;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color colorPrimary;
  final Color colorLight;
  final String emcPoints;
  final String? buttonIcon; // Optional SVG asset path for the CTA button

  FeaturedItemModel({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.colorPrimary,
    required this.colorLight,
    required this.emcPoints,
    this.buttonIcon,
  });
}

class FeaturedCard extends StatefulWidget {
  const FeaturedCard({super.key});

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  late PageController _pageController;
  double _currentPage = 0;

  final List<FeaturedItemModel> _items = [
    FeaturedItemModel(
      tag: 'NOU',
      title: 'Ghiduri Europene de Cardiologie 2026',
      subtitle: 'Rezumatul complet al noilor recomandări privind tratamentul pacienților cu insuficiență cardiacă.',
      buttonText: 'Citește rezumatul AI',
      colorPrimary: PulseTheme.primary,
      colorLight: PulseTheme.primaryLight,
      emcPoints: '+10',
      buttonIcon: 'assets/icons/AI.svg',
    ),
    FeaturedItemModel(
      tag: 'CURS',
      title: 'Urgente Majore în Pediatrie',
      subtitle: 'Curs EMC interactiv - câștigă 12 puncte prin parcurgerea modulelor video.',
      buttonText: 'Începe cursul',
      colorPrimary: PulseTheme.courseContent,
      colorLight: PulseTheme.courseContent.withOpacity(0.7),
      emcPoints: '+12',
    ),
    FeaturedItemModel(
      tag: 'EVENIMENT',
      title: 'Congresul Național de Medicină',
      subtitle: 'Rezervă-ți locul acum pentru cel mai important eveniment medical al anului, desfășurat offline și online.',
      buttonText: 'Vezi detalii',
      colorPrimary: PulseTheme.eventContent,
      colorLight: PulseTheme.eventContent.withOpacity(0.7),
      emcPoints: '+30',
    ),
    FeaturedItemModel(
      tag: 'REVISTĂ',
      title: 'Medicina Modernă - Ediția Martie',
      subtitle: 'Articole de top, interviuri exclusive, studii clinice noi și inovații tehnologice în sănătate.',
      buttonText: 'Răsfoiește',
      colorPrimary: PulseTheme.magazineContent,
      colorLight: PulseTheme.magazineContent.withOpacity(0.7),
      emcPoints: '+5',
    ),
  ];

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
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
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
        // ── Page Indicators ──
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
          _items[_currentPage.round().clamp(0, _items.length - 1)].colorPrimary,
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
                      color: dotColor.withOpacity(0.4),
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

  Widget _buildCardItem(FeaturedItemModel item, int index) {
    // Parallax offset for decorative circles
    double parallaxOffset = (_currentPage - index) * 30;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.colorPrimary,
            item.colorLight,
            item.colorPrimary.withOpacity(0.85),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: item.colorPrimary.withOpacity(0.35),
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
            // Parallax decorative circles
            Positioned(
              right: -40 + parallaxOffset,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -20 - parallaxOffset * 0.5,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Subtle noise / texture layer
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                      Colors.black.withOpacity(0.08),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // EMC Badge
            Positioned(
              right: 16,
              top: 16,
              child: EmcBadge(points: item.emcPoints),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.tag,
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
                      item.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: item.colorPrimary,
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
                          if (item.buttonIcon != null) ...[
                            _buildGradientIcon(item.buttonIcon!, item.colorPrimary),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            item.buttonText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (item.buttonIcon == null) ...[
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              'assets/icons/arrow.right.svg',
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                item.colorPrimary,
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
      child: SvgPicture.asset(
        assetPath,
        width: 20,
        height: 20,
      ),
    );
  }
}

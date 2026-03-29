import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import '../widgets/home_header.dart';
import '../widgets/featured_card.dart';
import '../widgets/content_section.dart';
import '../widgets/content_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;  // Bottom nav index
  int _feedTab = 0;         // 0 = Acasă, 1 = Pentru tine
  late PageController _feedPageController;
  late AnimationController _entranceController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  static const int _sectionCount = 6;

  @override
  void initState() {
    super.initState();
    _feedPageController = PageController();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimations = List.generate(_sectionCount, (index) {
      double start = (index * 0.12).clamp(0.0, 0.8);
      double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(_sectionCount, (index) {
      double start = (index * 0.12).clamp(0.0, 0.8);
      double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _feedPageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  // ────────────── Feed Tab Switcher (Acasă / Pentru tine) ──────────────

  Widget _buildFeedTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: PulseTheme.border.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            _buildFeedTab(0, 'assets/icons/house.svg', 'Acasă'),
            _buildFeedTab(1, 'assets/icons/sharedwithyou.svg', 'Pentru tine'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab(int index, String iconPath, String label) {
    final bool isActive = _feedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_feedTab != index) {
            _feedPageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? PulseTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  isActive ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.6),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────── Acasă Feed ──────────────

  Widget _buildAcasaFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured Carousel
        _animatedSection(2, const FeaturedCard()),

        const SizedBox(height: 36),

        // Cursuri Section
        _animatedSection(3, ContentSection(
          title: 'Cursuri',
          emptyMessage: 'Cursurile vor apărea aici',
          emptyIconAsset: 'assets/icons/graduation.svg',
          categoryColor: PulseTheme.courseContent,
          onActionTap: () {},
          children: const [
            ContentCard(
              title: 'Comunicarea medic-pacient',
              subtitle: '12 credite EMC',
              tag: 'Curs Online',
              categoryColor: PulseTheme.courseContent,
              iconAsset: 'assets/icons/graduation.svg',
              emcPoints: '+12',
              progress: 0.35,
            ),
            ContentCard(
              title: 'Antiobioterapia în 2026',
              subtitle: '8 credite EMC',
              tag: 'Webinar',
              categoryColor: PulseTheme.courseContent,
              iconAsset: 'assets/icons/graduation.svg',
              emcPoints: '+8',
            ),
          ],
        )),

        const SizedBox(height: 24),

        // Reviste Section
        _animatedSection(4, ContentSection(
          title: 'Reviste',
          emptyMessage: 'Nu există reviste disponibile momentan',
          emptyIconAsset: 'assets/icons/books.svg',
          categoryColor: PulseTheme.magazineContent,
          onActionTap: () {},
          children: const [],
        )),

        const SizedBox(height: 24),

        // Știri Medicale
        _animatedSection(5, ContentSection(
          title: 'Știri Medicale',
          emptyMessage: 'Știrile medicale vor apărea aici',
          emptyIconAsset: 'assets/icons/newspaper.svg',
          categoryColor: PulseTheme.newsContent,
          onActionTap: () {},
          children: const [
            ContentCard(
              title: 'Ministerul Sănătății lansează noul sistem informatic',
              subtitle: 'Acum 2 ore',
              tag: 'Sistem',
              categoryColor: PulseTheme.newsContent,
              iconAsset: 'assets/icons/newspaper.svg',
            ),
            ContentCard(
              title: 'Noi medicamente compensate aprobate ieri',
              subtitle: 'Acum 5 ore',
              tag: 'Farma',
              categoryColor: PulseTheme.newsContent,
              iconAsset: 'assets/icons/newspaper.svg',
            ),
          ],
        )),

        const SizedBox(height: 100),
      ],
    );
  }

  // ────────────── Pentru Tine Feed (AI Curated) ──────────────

  Widget _buildPentruTineFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // AI Intro Card
        _animatedSection(2, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF7C3AED),
                  Color(0xFFEC4899),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                // AI Icon with glass circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/AI.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selectat de AI pentru tine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bazat pe specialitatea și interesele tale',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),

        const SizedBox(height: 28),

        // Recomandate pentru tine - Cursuri
        _animatedSection(3, ContentSection(
          title: 'Recomandate',
          emptyMessage: 'Recomandările vor apărea aici',
          emptyIconAsset: 'assets/icons/sharedwithyou.svg',
          categoryColor: PulseTheme.primary,
          onActionTap: () {},
          children: const [
            ContentCard(
              title: 'Ghid Practic: Managementul Durerii Cronice',
              subtitle: '15 credite EMC',
              tag: 'Curs Recomandat',
              categoryColor: PulseTheme.primary,
              iconAsset: 'assets/icons/graduation.svg',
              emcPoints: '+15',
            ),
            ContentCard(
              title: 'Imunoterapia în Oncologie — Update 2026',
              subtitle: '10 credite EMC',
              tag: 'Webinar Recomandat',
              categoryColor: PulseTheme.primary,
              iconAsset: 'assets/icons/graduation.svg',
              emcPoints: '+10',
            ),
          ],
        )),

        const SizedBox(height: 24),

        // Articole relevante
        _animatedSection(4, ContentSection(
          title: 'Articole relevante',
          emptyMessage: 'Articolele relevante vor apărea aici',
          emptyIconAsset: 'assets/icons/newspaper.svg',
          categoryColor: PulseTheme.courseContent,
          onActionTap: () {},
          children: const [
            ContentCard(
              title: 'Rezistența la antibiotice — Strategii noi 2026',
              subtitle: 'Acum 3 ore',
              tag: 'Relevant',
              categoryColor: PulseTheme.courseContent,
              iconAsset: 'assets/icons/newspaper.svg',
            ),
            ContentCard(
              title: 'Inteligența artificială în diagnosticul imagistic',
              subtitle: 'Acum 1 zi',
              tag: 'Trending',
              categoryColor: PulseTheme.courseContent,
              iconAsset: 'assets/icons/AI.svg',
            ),
          ],
        )),

        const SizedBox(height: 24),

        // Evenimente sugerate
        _animatedSection(5, ContentSection(
          title: 'Evenimente sugerate',
          emptyMessage: 'Evenimentele sugerate vor apărea aici',
          emptyIconAsset: 'assets/icons/events.svg',
          categoryColor: PulseTheme.eventContent,
          onActionTap: () {},
          children: const [
            ContentCard(
              title: 'Simpozionul de Medicină Internă — Cluj-Napoca',
              subtitle: '15 Aprilie 2026',
              tag: 'Sugerat',
              categoryColor: PulseTheme.eventContent,
              iconAsset: 'assets/icons/events.svg',
              emcPoints: '+20',
            ),
          ],
        )),

        const SizedBox(height: 100),
      ],
    );
  }

  // ────────────── Main Home Content ──────────────

  Widget _buildHomeContent() {
    return SafeArea(
      child: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  _animatedSection(0, const HomeHeader(
                    doctorName: 'Andrei',
                    avatarUrl: '',
                  )),

                  // 2. Feed Tab Switcher (Acasă / Pentru tine)
                  _animatedSection(1, Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildFeedTabSwitcher(),
                  )),
                ],
              ),
            ),
          ];
        },
        body: PageView(
          controller: _feedPageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _feedTab = index;
            });
          },
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildAcasaFeed(),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildPentruTineFeed(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PulseTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pagină în construcție',
              style: TextStyle(
                fontSize: 14,
                color: PulseTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;
    switch (_selectedIndex) {
      case 0:
        activeBody = _buildHomeContent();
        break;
      case 1:
        activeBody = _buildPlaceholder('Cursuri');
        break;
      case 2:
        activeBody = _buildPlaceholder('Reviste');
        break;
      case 3:
        activeBody = _buildPlaceholder('Evenimente');
        break;
      case 4:
        activeBody = _buildPlaceholder('Știri');
        break;
      default:
        activeBody = _buildHomeContent();
    }

    return Scaffold(
      backgroundColor: PulseTheme.background,
      extendBody: true,
      bottomNavigationBar: _buildGlassBottomNav(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: activeBody,
        ),
      ),
    );
  }

  // ────────────── Glassmorphism Bottom Navigation ──────────────

  Widget _buildGlassBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12, top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(0, 'assets/icons/house.svg', 'Acasă'),
                  _buildNavItem(1, 'assets/icons/graduation.svg', 'Cursuri'),
                  _buildNavItem(2, 'assets/icons/books.svg', 'Reviste'),
                  _buildNavItem(3, 'assets/icons/events.svg', 'Evenimente'),
                  _buildNavItem(4, 'assets/icons/newspaper.svg', 'Știri'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? PulseTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isSelected ? PulseTheme.primary : PulseTheme.textSecondary.withOpacity(0.7),
                BlendMode.srcIn,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: PulseTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: -0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

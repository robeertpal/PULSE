import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';
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

  final ApiService _apiService = ApiService();
  List<ContentItem> _articles = [];
  List<ContentItem> _coursesEvents = [];
  List<ContentItem> _news = [];
  bool _isLoading = true;
  String? _errorMessage;

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
    
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getArticles(),
        _apiService.getCoursesEvents(),
        _apiService.getNews(),
      ]);

      if (mounted) {
        setState(() {
          _articles = results[0];
          _coursesEvents = results[1];
          _news = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "A apărut o eroare la încărcarea datelor";
        });
      }
    }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 2;
            return Stack(
              children: [
                // ── Sliding pill indicator ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: _feedTab == 0 ? 0 : tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: PulseTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Tab labels (on top of pill) ──
                Row(
                  children: [
                    _buildFeedTab(0, 'assets/icons/house.svg', 'Acasă'),
                    _buildFeedTab(1, 'assets/icons/sharedwithyou.svg', 'Pentru tine'),
                  ],
                ),
              ],
            );
          },
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
            setState(() {
              _feedTab = index;
            });
            _feedPageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          }
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: const TextStyle(fontSize: 0),
                child: SvgPicture.asset(
                  iconPath,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isActive ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.6),
                    BlendMode.srcIn,
                  ),
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

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ────────────── Acasă Feed ──────────────

  Widget _buildAcasaFeed() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100.0),
          child: CircularProgressIndicator(color: PulseTheme.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            children: [
              Text(_errorMessage!, style: const TextStyle(color: PulseTheme.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Reîncearcă"),
              )
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured Carousel
        _animatedSection(2, const FeaturedCard()),

        const SizedBox(height: 36),

        // Cursuri Section
        _animatedSection(3, ContentSection(
          title: 'Cursuri și Evenimente',
          emptyMessage: 'Cursurile vor apărea aici',
          emptyIconAsset: 'assets/icons/graduation.svg',
          categoryColor: PulseTheme.courseContent,
          onActionTap: () => _navigateToTab(1), // Navighează către Cursuri
          children: _coursesEvents.map((item) => ContentCard.fromModel(item)).toList(),
        )),

        const SizedBox(height: 24),

        // Reviste Section
        _animatedSection(4, ContentSection(
          title: 'Reviste',
          emptyMessage: 'Nu există reviste disponibile momentan',
          emptyIconAsset: 'assets/icons/books.svg',
          categoryColor: PulseTheme.magazineContent,
          onActionTap: () => _navigateToTab(2), // Navighează către Reviste
          children: const [],
        )),

        const SizedBox(height: 24),

        // Știri Medicale
        _animatedSection(5, ContentSection(
          title: 'Știri Medicale',
          emptyMessage: 'Știrile medicale vor apărea aici',
          emptyIconAsset: 'assets/icons/newspaper.svg',
          categoryColor: PulseTheme.newsContent,
          onActionTap: () => _navigateToTab(4), // Navighează către Știri
          children: _news.map((item) => ContentCard.fromModel(item)).toList(),
        )),

        const SizedBox(height: 100),
      ],
    );
  }

  // ────────────── Pentru Tine Feed (AI Curated) ──────────────

  Widget _buildPentruTineFeed() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 100.0),
          child: CircularProgressIndicator(color: PulseTheme.primary),
        ),
      );
    }

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
          onActionTap: () => _navigateToTab(1), // Navighează către Cursuri
          children: _articles.where((i) => i.isFeatured).map((i) => ContentCard.fromModel(i)).toList(),
        )),

        const SizedBox(height: 24),

        // Articole relevante
        _animatedSection(4, ContentSection(
          title: 'Articole relevante',
          emptyMessage: 'Articolele relevante vor apărea aici',
          emptyIconAsset: 'assets/icons/newspaper.svg',
          categoryColor: PulseTheme.courseContent,
          onActionTap: () => _navigateToTab(4), // Navighează către Articole (Știri)
          children: _articles.map((i) => ContentCard.fromModel(i)).toList(),
        )),

        const SizedBox(height: 24),

        // Evenimente sugerate
        _animatedSection(5, ContentSection(
          title: 'Evenimente sugerate',
          emptyMessage: 'Evenimentele sugerate vor apărea aici',
          emptyIconAsset: 'assets/icons/events.svg',
          categoryColor: PulseTheme.eventContent,
          onActionTap: () => _navigateToTab(3), // Navighează către Evenimente
          children: _coursesEvents.take(1).map((i) => ContentCard.fromModel(i)).toList(),
        )),

        const SizedBox(height: 100),
      ],
    );
  }

  // ────────────── Main Home Content ──────────────

  Widget _buildHomeContent() {
    return NestedScrollView(
      physics: const BouncingScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feed Tab Switcher (Acasă / Pentru tine)
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
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      extendBody: true,
      bottomNavigationBar: _buildGlassBottomNav(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Partea de acces de sus (Template global)
            _animatedSection(0, const HomeHeader(
              doctorName: 'Andrei',
              avatarUrl: '',
            )),
            // Conținutul paginii cu tranziții
            Expanded(
              child: FadeIndexedStack(
                duration: const Duration(milliseconds: 300),
                index: _selectedIndex,
                children: [
                  _buildHomeContent(),
                  _buildPlaceholder('Cursuri'),
                  _buildPlaceholder('Reviste'),
                  _buildPlaceholder('Evenimente'),
                  _buildPlaceholder('Știri'),
                ],
              ),
            ),
          ],
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
        if (_selectedIndex == index) {
          // Dacă apeși iar pe "Acasă" și ești pe alt sub-tab, te duce la sub-tabul principal
          if (index == 0 && _feedTab != 0) {
            setState(() {
              _feedTab = 0;
            });
            if (_feedPageController.hasClients) {
              _feedPageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              );
            }
          }
          return;
        }
        
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

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  late List<bool> _active;

  @override
  void initState() {
    super.initState();
    _active = List.generate(widget.children.length, (i) => i == widget.index);
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _active[oldWidget.index] = true;
      _active[widget.index] = true;
      
      Future.delayed(widget.duration, () {
        if (mounted) {
          setState(() {
            for (int i = 0; i < _active.length; i++) {
              if (i != widget.index) _active[i] = false;
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.children.length, (i) {
        final isSelected = widget.index == i;
        final isActive = _active[i];
        
        return IgnorePointer(
          ignoring: !isSelected,
          child: Offstage(
            offstage: !isActive,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: widget.duration,
              curve: Curves.easeOutCubic,
              child: TickerMode(
                enabled: isSelected,
                child: widget.children[i],
              ),
            ),
          ),
        );
      }),
    );
  }
}

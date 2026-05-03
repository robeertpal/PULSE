import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/pulse_theme.dart';
import '../models/ad_item.dart';
import '../models/content_item.dart';
import '../models/filter_option.dart';
import '../services/api_service.dart';
import 'saved_content_screen.dart';
import '../widgets/home_header.dart';
import '../widgets/featured_card.dart';
import '../widgets/content_section.dart';
import '../widgets/content_card.dart';
import '../widgets/advertisement_feed_slot.dart';
import '../widgets/premium_loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0; // Bottom nav index
  late AnimationController _entranceController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  final ApiService _apiService = ApiService();
  List<ContentItem> _courses = [];
  List<ContentItem> _events = [];
  List<ContentItem> _publications = [];
  List<ContentItem> _news = [];
  List<ContentItem> _featuredItems = [];
  List<FilterOption> _categories = [];
  List<FilterOption> _specializations = [];
  Map<String, List<AdItem>> _adsByPlacement = {};
  final Set<int> _selectedCategoryIds = {};
  final Set<int> _selectedSpecializationIds = {};
  Set<int> _savedContentIds = {};
  bool _isLoading = true;
  bool _isFeaturedLoading = true;
  int _contentRequestId = 0;
  String? _errorMessage;

  static const int _sectionCount = 10;
  static const List<String> _homeAdPlacements = [
    'home_after_news',
    'home_after_publications',
    'home_after_events',
    'home_after_courses',
  ];

  @override
  void initState() {
    super.initState();
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
    _loadFilterOptions();
    _loadSavedContentIds();
  }

  List<int> get _categoryFilterIds => _selectedCategoryIds.toList()..sort();

  List<int> get _specializationFilterIds =>
      _selectedSpecializationIds.toList()..sort();

  bool get _hasActiveFilters =>
      _selectedCategoryIds.isNotEmpty || _selectedSpecializationIds.isNotEmpty;

  Future<void> _loadData() async {
    if (!mounted) return;
    final requestId = ++_contentRequestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _loadFeaturedContent(requestId);
    _loadAds();
    _loadSavedContentIds();

    try {
      final categoryIds = _categoryFilterIds;
      final specializationIds = _specializationFilterIds;
      final results = await Future.wait([
        _apiService.getNews(
          limit: 10,
          categoryIds: categoryIds,
          specializationIds: specializationIds,
        ),
        _apiService.getPublications(
          limit: 10,
          categoryIds: categoryIds,
          specializationIds: specializationIds,
        ),
        _apiService.getEvents(
          limit: 10,
          categoryIds: categoryIds,
          specializationIds: specializationIds,
        ),
        _apiService.getCourses(
          limit: 10,
          categoryIds: categoryIds,
          specializationIds: specializationIds,
        ),
      ]);

      if (mounted && requestId == _contentRequestId) {
        setState(() {
          _news = results[0];
          _publications = results[1];
          _events = results[2];
          _courses = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && requestId == _contentRequestId) {
        setState(() {
          _isLoading = false;
          _errorMessage = "A apărut o eroare la încărcarea datelor";
        });
      }
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getSpecializations(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0];
          _specializations = results[1];
        });
      }
    } catch (e) {
      debugPrint('Error loading content filters: $e');
    }
  }

  Future<void> _loadSavedContentIds() async {
    try {
      final ids = await _apiService.getSavedContentIds();
      if (mounted) {
        setState(() {
          _savedContentIds = ids;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved content ids: $e');
    }
  }

  void _showSavedFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleSavedContent(int contentItemId) async {
    final wasSaved = _savedContentIds.contains(contentItemId);

    setState(() {
      if (wasSaved) {
        _savedContentIds.remove(contentItemId);
      } else {
        _savedContentIds.add(contentItemId);
      }
    });

    try {
      if (wasSaved) {
        await _apiService.unsaveContent(contentItemId);
        _showSavedFeedback('Eliminat din salvate');
      } else {
        await _apiService.saveContent(contentItemId);
        _showSavedFeedback('Salvat');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedContentIds.add(contentItemId);
        } else {
          _savedContentIds.remove(contentItemId);
        }
      });
      _showSavedFeedback('Nu am putut actualiza salvarea');
    }
  }

  Future<void> _openSavedContent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedContentScreen()),
    );
    _loadSavedContentIds();
  }

  Widget _savedContentCard(ContentItem item) {
    return ContentCard.fromModel(
      item,
      isSaved: _savedContentIds.contains(item.id),
      onSaveToggle: _toggleSavedContent,
      onDetailClosed: _loadSavedContentIds,
    );
  }

  void _toggleCategory(int id) {
    setState(() {
      if (!_selectedCategoryIds.add(id)) {
        _selectedCategoryIds.remove(id);
      }
    });
    _loadData();
  }

  void _toggleSpecialization(int id) {
    setState(() {
      if (!_selectedSpecializationIds.add(id)) {
        _selectedSpecializationIds.remove(id);
      }
    });
    _loadData();
  }

  void _resetFilters() {
    if (!_hasActiveFilters) return;
    setState(() {
      _selectedCategoryIds.clear();
      _selectedSpecializationIds.clear();
    });
    _loadData();
  }

  Future<void> _loadAds() async {
    try {
      final entries = await Future.wait(
        _homeAdPlacements.map((placement) async {
          try {
            final ads = await _apiService.fetchAds(
              placement: placement,
              limit: 1,
            );
            return MapEntry(placement, ads);
          } catch (e) {
            debugPrint('Error loading ads for $placement: $e');
            return MapEntry(placement, <AdItem>[]);
          }
        }),
      );

      if (mounted) {
        setState(() {
          _adsByPlacement = Map.fromEntries(entries);
        });
      }
    } catch (e) {
      debugPrint('Error loading home ads: $e');
    }
  }

  Future<void> _loadFeaturedContent(int requestId) async {
    if (!mounted) return;
    setState(() {
      _isFeaturedLoading = true;
    });

    try {
      final items = await _apiService.getFeaturedContent(
        limit: 3,
        categoryIds: _categoryFilterIds,
        specializationIds: _specializationFilterIds,
      );
      if (mounted && requestId == _contentRequestId) {
        setState(() {
          _featuredItems = items.take(3).toList();
          _isFeaturedLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured carousel: $e');
      if (mounted && requestId == _contentRequestId) {
        setState(() {
          _featuredItems = [];
          _isFeaturedLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  Widget _buildFilterChip({
    required FilterOption option,
    required bool selected,
    required ValueChanged<int> onSelected,
  }) {
    return AnimatedContainer(
      duration: PulseTheme.animFast,
      curve: PulseTheme.animCurve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: PulseTheme.primary.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ]
            : const [],
      ),
      child: FilterChip(
        label: Text(
          option.name,
          overflow: TextOverflow.ellipsis,
        ),
        selected: selected,
        onSelected: (_) => onSelected(option.id),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        backgroundColor: const Color(0xFFF8FAFC),
        selectedColor: PulseTheme.primary.withValues(alpha: 0.1),
        side: BorderSide(
          color: selected
              ? PulseTheme.primary.withValues(alpha: 0.72)
              : PulseTheme.border.withValues(alpha: 0.78),
          width: selected ? 1.3 : 1,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        labelStyle: TextStyle(
          color: selected ? PulseTheme.primaryDark : PulseTheme.textSecondary,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<FilterOption> options,
    required Set<int> selectedIds,
    required ValueChanged<int> onSelected,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: PulseTheme.primary.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: PulseTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final option = options[index];
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: _buildFilterChip(
                  option: option,
                  selected: selectedIds.contains(option.id),
                  onSelected: onSelected,
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemCount: options.length,
          ),
        ),
      ],
    );
  }

  Widget _buildContentFilters() {
    if (_categories.isEmpty && _specializations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: PulseTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: PulseTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtre',
                    style: TextStyle(
                      color: PulseTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _hasActiveFilters ? _resetFilters : null,
                  style: TextButton.styleFrom(
                    foregroundColor: PulseTheme.primary,
                    disabledForegroundColor: PulseTheme.textTertiary,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Sterge filtre'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Restrange continutul dupa interesul tau clinic.',
              style: TextStyle(
                color: PulseTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            _buildFilterRow(
              label: 'Categorii',
              options: _categories,
              selectedIds: _selectedCategoryIds,
              onSelected: _toggleCategory,
            ),
            if (_categories.isNotEmpty && _specializations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  height: 1,
                  color: PulseTheme.borderLight.withValues(alpha: 0.92),
                ),
              ),
            _buildFilterRow(
              label: 'Specializari',
              options: _specializations,
              selectedIds: _selectedSpecializationIds,
              onSelected: _toggleSpecialization,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  int _tabIndexForContentType(String? type) {
    switch (type) {
      case 'course':
        return 1;
      case 'publication':
        return 2;
      case 'event':
        return 3;
      case 'news':
      case 'article':
        return 4;
      default:
        return 0;
    }
  }

  Future<void> _handleAdTap(AdItem ad) async {
    if (ad.relatedContentItemId != null) {
      final targetTab = _tabIndexForContentType(ad.relatedContentType);
      if (targetTab != 0) _navigateToTab(targetTab);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ad.relatedContentTitle?.isNotEmpty == true
                ? 'Detaliile pentru "${ad.relatedContentTitle}" vor fi disponibile în curând.'
                : 'Detalii disponibile în curând.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ctaUrl = ad.ctaUrl?.trim();
    if (ctaUrl != null && ctaUrl.isNotEmpty) {
      final uri = Uri.tryParse(ctaUrl);
      if (uri != null) {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      }
    }
  }

  // Acasă Feed

  Widget _buildAcasaFeed() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 150.0),
        child: PremiumLoadingIndicator(text: 'Se pregătește feed-ul...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: PulseTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Reîncearcă"),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildContentFilters(),

        _animatedSection(
          1,
          FeaturedCard(items: _featuredItems, isLoading: _isFeaturedLoading),
        ),

        if (_isFeaturedLoading || _featuredItems.isNotEmpty)
          const SizedBox(height: 30),

        // Știri Section
        _animatedSection(
          2,
          ContentSection(
            title: 'Știri',
            emptyMessage: 'Nu există încă știri publicate.',
            emptyIconAsset: 'assets/icons/newspaper.svg',
            categoryColor: PulseTheme.newsContent,
            onActionTap: () => _navigateToTab(4),
            children: _news.map(_savedContentCard).toList(),
          ),
        ),

        AdvertisementFeedSlot(
          ads: _adsByPlacement['home_after_news'] ?? const <AdItem>[],
          onAdTap: _handleAdTap,
        ),

        // Reviste Section
        _animatedSection(
          3,
          ContentSection(
            title: 'Reviste',
            emptyMessage: 'Nu există încă reviste publicate.',
            emptyIconAsset: 'assets/icons/books.svg',
            categoryColor: PulseTheme.magazineContent,
            onActionTap: () => _navigateToTab(2),
            children: _publications.map(_savedContentCard).toList(),
          ),
        ),

        AdvertisementFeedSlot(
          ads: _adsByPlacement['home_after_publications'] ?? const <AdItem>[],
          onAdTap: _handleAdTap,
        ),

        // Evenimente Section
        _animatedSection(
          4,
          ContentSection(
            title: 'Evenimente',
            emptyMessage: 'Nu există încă evenimente publicate.',
            emptyIconAsset: 'assets/icons/events.svg',
            categoryColor: PulseTheme.eventContent,
            onActionTap: () => _navigateToTab(3),
            children: _events.map(_savedContentCard).toList(),
          ),
        ),

        AdvertisementFeedSlot(
          ads: _adsByPlacement['home_after_events'] ?? const <AdItem>[],
          onAdTap: _handleAdTap,
        ),

        // Cursuri Section
        _animatedSection(
          5,
          ContentSection(
            title: 'Cursuri',
            emptyMessage: 'Nu există încă cursuri publicate.',
            emptyIconAsset: 'assets/icons/graduation.svg',
            categoryColor: PulseTheme.courseContent,
            onActionTap: () => _navigateToTab(1),
            children: _courses.map(_savedContentCard).toList(),
          ),
        ),

        AdvertisementFeedSlot(
          ads: _adsByPlacement['home_after_courses'] ?? const <AdItem>[],
          onAdTap: _handleAdTap,
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Main Home Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: PulseTheme.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: _buildAcasaFeed(),
      ),
    );
  }

  Widget _buildCategoryContent({
    required String title,
    required String emptyMessage,
    required String emptyIconAsset,
    required Color categoryColor,
    required List<ContentItem> items,
  }) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 150.0),
        child: PremiumLoadingIndicator(text: 'Se pregătește feed-ul...'),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: PulseTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text("Reîncearcă"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: PulseTheme.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 100.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentFilters(),
              ContentSection(
                title: title,
                actionText: '',
                emptyMessage: emptyMessage,
                emptyIconAsset: emptyIconAsset,
                categoryColor: categoryColor,
                onActionTap: () {},
                children: items.map(_savedContentCard).toList(),
              ),
            ],
          ),
        ),
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
            _animatedSection(
              0,
              HomeHeader(
                doctorName: 'Andrei',
                avatarUrl: '',
                onSavedTap: _openSavedContent,
              ),
            ),
            // Conținutul paginii cu tranziții
            Expanded(
              child: FadeIndexedStack(
                duration: const Duration(milliseconds: 300),
                index: _selectedIndex,
                children: [
                  _buildHomeContent(),
                  _buildCategoryContent(
                    title: 'Cursuri',
                    emptyMessage: 'Nu există încă cursuri publicate.',
                    emptyIconAsset: 'assets/icons/graduation.svg',
                    categoryColor: PulseTheme.courseContent,
                    items: _courses,
                  ),
                  _buildCategoryContent(
                    title: 'Reviste',
                    emptyMessage: 'Nu există încă reviste publicate.',
                    emptyIconAsset: 'assets/icons/books.svg',
                    categoryColor: PulseTheme.magazineContent,
                    items: _publications,
                  ),
                  _buildCategoryContent(
                    title: 'Evenimente',
                    emptyMessage: 'Nu există încă evenimente publicate.',
                    emptyIconAsset: 'assets/icons/events.svg',
                    categoryColor: PulseTheme.eventContent,
                    items: _events,
                  ),
                  _buildCategoryContent(
                    title: 'Știri',
                    emptyMessage: 'Nu există încă știri publicate.',
                    emptyIconAsset: 'assets/icons/newspaper.svg',
                    categoryColor: PulseTheme.newsContent,
                    items: _news,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Glassmorphism Bottom Navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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
          color: isSelected
              ? PulseTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
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
                isSelected
                    ? PulseTheme.primary
                    : PulseTheme.textSecondary.withValues(alpha: 0.7),
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
              child: TickerMode(enabled: isSelected, child: widget.children[i]),
            ),
          ),
        );
      }),
    );
  }
}

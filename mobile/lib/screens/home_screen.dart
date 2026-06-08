import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/pulse_theme.dart';
import '../models/ad_item.dart';
import '../models/content_item.dart';
import '../models/filter_option.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'login_screen.dart';
import 'content_detail_screen.dart';
import 'content_submissions_screen.dart';
import 'notifications_screen.dart';
import 'publication_issues_screen.dart';
import 'profile_screen.dart';
import 'my_courses_screen.dart';
import 'my_publications_screen.dart';
import 'saved_content_screen.dart';
import 'tickets_screen.dart';
import 'transactions_screen.dart';
import '../widgets/featured_card.dart';
import '../widgets/content_section.dart';
import '../widgets/content_card.dart';
import '../widgets/advertisement_feed_slot.dart';
import '../widgets/auth_shell.dart';
import '../widgets/pulse_animated_background.dart';
import '../widgets/skeleton_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showOnboardingWelcome = false});

  final bool showOnboardingWelcome;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const Color _darkCanvas = Color(0xFF090A10);
  static const Color _darkCanvasAlt = Color(0xFF111018);
  static const Color _darkViolet = Color(0xFF1B1017);
  static const Color _darkSurface = Color(0xFF15131B);
  static const Color _darkText = Color(0xFFFFFAFC);
  static const Color _darkMuted = Color(0xFFCFC4D0);
  static const Color _neonBlue = Color(0xFFFF8A3D);
  static const Color _neonPurple = Color(0xFFFF2D72);

  int _selectedIndex = 0; // Bottom nav index
  int _selectedHomeTab = 0;
  late AnimationController _entranceController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  final PageController _homeTabPageController = PageController(initialPage: 0);

  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();
  List<ContentItem> _courses = [];
  List<ContentItem> _events = [];
  List<ContentItem> _publications = [];
  List<ContentItem> _news = [];
  List<ContentItem> _featuredItems = [];
  List<ContentItem> _forYouItems = [];
  List<FilterOption> _categories = [];
  List<FilterOption> _specializations = [];
  Map<String, List<AdItem>> _adsByPlacement = {};
  Map<int, String> _forYouReasons = {};
  final Set<int> _selectedCategoryIds = {};
  final Set<int> _selectedSpecializationIds = {};
  Set<int> _savedContentIds = {};
  bool _isLoading = true;
  bool _isFeaturedLoading = true;
  bool _isForYouLoading = true;
  bool _forYouGeneratedWithAi = false;
  bool _filtersExpanded = false;
  int _contentRequestId = 0;
  bool _didShowOnboardingWelcome = false;
  String? _errorMessage;
  String? _forYouErrorMessage;
  String _doctorName = 'Medic';
  String? _doctorAvatarUrl;
  int _unreadNotificationsCount = 0;

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
    _loadDoctorName();
    _loadUnreadNotificationsCount();
    _loadForYouRecommendations();

    if (widget.showOnboardingWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOnboardingWelcomeDialogOnce();
      });
    }
  }

  Future<void> _showOnboardingWelcomeDialogOnce() async {
    if (!mounted || _didShowOnboardingWelcome) return;
    _didShowOnboardingWelcome = true;
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    final cachedName = await _authStorage.getUserName();
    final displayName = (cachedName != null && cachedName.trim().isNotEmpty)
        ? cachedName.trim()
        : _doctorName.trim();
    final firstName = displayName.isNotEmpty && displayName != 'Medic'
        ? displayName.split(RegExp(r'\s+')).first
        : '';
    final title = firstName.isNotEmpty
        ? 'Bun venit, $firstName!'
        : 'Bun venit în PULSE!';

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Închide',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.transparent,
              child: FrostedAuthCard(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 410),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AuthShell.pulseGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AuthShell.pulsePurple.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AuthShell.textPrimary,
                          fontSize: 24,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Contul tău este pregătit. Am personalizat experiența pe baza intereselor selectate.',
                        style: TextStyle(
                          color: AuthShell.textSecondary,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AuthPrimaryButton(
                        label: 'Începem',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final count = await _apiService.getUnreadNotificationCount();
    if (!mounted) return;
    setState(() {
      _unreadNotificationsCount = count;
    });
  }

  Future<void> _loadDoctorName() async {
    // 1. Încărcăm numele din cache (AuthStorage) pentru afișare instantanee
    final cachedName = await _authStorage.getUserName();
    if (cachedName != null && cachedName.trim().isNotEmpty) {
      if (mounted) {
        setState(() {
          _doctorName = cachedName;
        });
      }
    }

    // 2. Interogăm profilul din API pentru a asigura sincronizarea numelui la zi
    try {
      final profileData = await _apiService.getMyProfile();
      final freshName = profileData['display_name'] as String?;
      final avatarUrl = _extractProfileImageUrl(profileData);
      if (freshName != null && freshName.trim().isNotEmpty) {
        await _authStorage.saveUserName(freshName.trim());
      }
      if (mounted) {
        setState(() {
          if (freshName != null && freshName.trim().isNotEmpty) {
            _doctorName = freshName.trim();
          }
          _doctorAvatarUrl = avatarUrl;
        });
      }
    } catch (e) {
      debugPrint('Eroare la obținerea numelui medicului din API: $e');
    }
  }

  String? _extractProfileImageUrl(Map<String, dynamic> data) {
    final keys = [
      'avatar_url',
      'photo_url',
      'profile_image_url',
      'profile_photo_url',
      'image_url',
      'picture',
    ];

    String? readFrom(Map<String, dynamic> source) {
      for (final key in keys) {
        final value = source[key]?.toString().trim();
        if (value != null &&
            value.isNotEmpty &&
            (value.startsWith('http://') || value.startsWith('https://'))) {
          return value;
        }
      }
      return null;
    }

    final direct = readFrom(data);
    if (direct != null) return direct;

    final profile = data['profile'];
    if (profile is Map<String, dynamic>) return readFrom(profile);
    return null;
  }

  List<int> get _categoryFilterIds => _selectedCategoryIds.toList()..sort();

  List<int> get _specializationFilterIds =>
      _selectedSpecializationIds.toList()..sort();

  bool get _hasActiveFilters =>
      _selectedCategoryIds.isNotEmpty || _selectedSpecializationIds.isNotEmpty;

  int get _activeFilterCount =>
      _selectedCategoryIds.length + _selectedSpecializationIds.length;

  bool get _hasAnyHomeContent =>
      _featuredItems.isNotEmpty ||
      _news.isNotEmpty ||
      _publications.isNotEmpty ||
      _events.isNotEmpty ||
      _courses.isNotEmpty;

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

  Future<void> _loadForYouRecommendations() async {
    if (!mounted) return;
    setState(() {
      _isForYouLoading = true;
      _forYouErrorMessage = null;
    });

    try {
      final result = await _apiService.getForYouRecommendations(limit: 20);
      final rawItems = result['items'];
      final parsedItems = <ContentItem>[];
      final parsedReasons = <int, String>{};

      if (rawItems is List) {
        for (final rawItem in rawItems) {
          if (rawItem is! Map<String, dynamic>) continue;
          final contentJson = rawItem['content_item'];
          if (contentJson is! Map<String, dynamic>) continue;
          final item = ContentItem.fromJson(contentJson);
          parsedItems.add(item);
          final reason = rawItem['reason']?.toString().trim();
          if (reason != null && reason.isNotEmpty) {
            parsedReasons[item.id] = reason;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _forYouItems = parsedItems;
        _forYouReasons = parsedReasons;
        _forYouGeneratedWithAi = result['generated_with_ai'] == true;
        _isForYouLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isForYouLoading = false;
        _forYouErrorMessage =
            'Nu am putut încărca recomandările personalizate.';
      });
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

  Future<void> _openTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionsScreen()),
    );
  }

  Future<void> _openTickets() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TicketsScreen()),
    );
  }

  Future<void> _openMyPublications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyPublicationsScreen()),
    );
  }

  Future<void> _openMyCourses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyCoursesScreen()),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
    _loadUnreadNotificationsCount();
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  Future<void> _openContentSubmissions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContentSubmissionsScreen()),
    );
  }

  Future<void> _logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('Logout request failed: $e');
    }

    await _authStorage.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _verticalContentCard(ContentItem item, {String? infoText}) {
    return SizedBox(
      width: double.infinity,
      height: 260,
      child: ContentCard.fromModel(
        item,
        isSaved: _savedContentIds.contains(item.id),
        onSaveToggle: _toggleSavedContent,
        onDetailClosed: _loadSavedContentIds,
        cardWidth: double.infinity,
        margin: EdgeInsets.zero,
        darkMode: true,
        infoText: infoText,
      ),
    );
  }

  Map<String, dynamic> _forYouFeedbackMetadata(ContentItem item) {
    return {
      'content_type': item.contentType,
      if (item.categoryId != null) 'category_id': item.categoryId,
      if (item.categoryName != null) 'category_name': item.categoryName,
      if (item.specializationId != null)
        'specialization_id': item.specializationId,
      if (item.specializationName != null)
        'specialization_name': item.specializationName,
      if (item.authorName != null) 'author_name': item.authorName,
      'source': 'for_you_feedback',
    };
  }

  void _sendForYouFeedback(ContentItem item, String actionType) {
    unawaited(
      _apiService.trackUserActivity(
        actionType: actionType,
        contentItemId: item.id,
        metadata: _forYouFeedbackMetadata(item),
      ),
    );
  }

  void _handleForYouFeedback(ContentItem item, String actionType) {
    if (actionType == 'content_not_interested') {
      setState(() {
        _forYouItems.removeWhere((candidate) => candidate.id == item.id);
        _forYouReasons.remove(item.id);
      });
      _showSavedFeedback('Am ascuns aceast\u0103 recomandare');
    } else if (actionType == 'content_more_like_this') {
      _showSavedFeedback('Vom afi\u0219a mai multe recomand\u0103ri similare');
    }
    _sendForYouFeedback(item, actionType);
  }

  Widget _buildForYouFeedbackMenu(ContentItem item) {
    return PopupMenuButton<String>(
      tooltip: 'Feedback recomandare',
      color: const Color(0xFF15131B),
      elevation: 12,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      onSelected: (value) => _handleForYouFeedback(item, value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'content_more_like_this',
          child: Row(
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 18,
                color: PulseTheme.primaryLight,
              ),
              SizedBox(width: 10),
              Text(
                'Mai multe ca acesta',
                style: TextStyle(
                  color: PulseTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'content_not_interested',
          child: Row(
            children: [
              Icon(
                Icons.block_rounded,
                size: 18,
                color: PulseTheme.textSecondary,
              ),
              SizedBox(width: 10),
              Text(
                'Nu m\u0103 intereseaz\u0103',
                style: TextStyle(
                  color: PulseTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  List<ContentItem> _withoutFeaturedItems(List<ContentItem> items) {
    if (_featuredItems.isEmpty) return items;
    final featuredKeys = _featuredItems.map(_contentIdentityKey).toSet();
    return items
        .where((item) => !featuredKeys.contains(_contentIdentityKey(item)))
        .toList();
  }

  String _contentIdentityKey(ContentItem item) =>
      '${item.contentType}:${item.id}';

  Future<void> _openContentItem(ContentItem item) async {
    if (item.contentType == 'publication') {
      final publicationId = item.publicationId ?? item.id;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PublicationIssuesScreen(
            publicationId: publicationId,
            contentItemId: item.id,
            publicationName: item.publicationName ?? item.title,
            contentTitle: item.title,
            contentShortDescription: item.shortDescription,
            contentBody: item.body,
            contentHeroImageUrl: item.heroImageUrl,
            contentThumbnailUrl: item.thumbnailUrl,
            contentPublishedAt: item.publishedAt,
            publicationDescription: item.publicationDescription,
            publicationLogoUrl: item.publicationLogoUrl,
            emcCreditsText: item.publicationEmcCreditsText,
            creditationText: item.publicationCreditationText,
            indexingText: item.publicationIndexingText,
            subscriptionUrl: item.publicationSubscriptionUrl ?? item.contentUrl,
            authors: item.publicationAuthors,
          ),
        ),
      );
      _loadSavedContentIds();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(
          contentItemId: item.id,
          initiallySaved: _savedContentIds.contains(item.id),
        ),
      ),
    );
    _loadSavedContentIds();
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
    _homeTabPageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  BoxDecoration _glassDecoration({
    double radius = 24,
    double opacity = 0.10,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: _darkSurface.withValues(alpha: 0.64 + opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.10),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          blurRadius: 28,
          offset: const Offset(0, 16),
          spreadRadius: -16,
        ),
        BoxShadow(
          color: _neonPurple.withValues(alpha: 0.14),
          blurRadius: 26,
          spreadRadius: -18,
        ),
      ],
    );
  }

  void _selectHomeTab(int index) {
    if (_selectedHomeTab == index) return;
    setState(() {
      _selectedHomeTab = index;
    });
    _homeTabPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleHomeTabPageChanged(int index) {
    if (_selectedHomeTab == index) return;
    setState(() {
      _selectedHomeTab = index;
    });
  }

  Future<void> _showFilterDropdown() async {
    var categoriesExpanded = false;
    var specializationsExpanded = false;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Închide filtrele',
      barrierColor: Colors.black.withValues(alpha: 0.24),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final size = MediaQuery.sizeOf(context);
            final panelWidth = (size.width - 28).clamp(280.0, 360.0).toDouble();

            return SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, right: 14, left: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: panelWidth,
                          maxHeight: size.height * 0.62,
                        ),
                        child: Container(
                          width: panelWidth,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          decoration: _glassDecoration(
                            radius: 24,
                            opacity: 0.10,
                            borderColor: PulseTheme.primaryLight.withValues(
                              alpha: 0.22,
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Filtre',
                                        style: TextStyle(
                                          color: _darkText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    _buildActiveFilterBadge(),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildFilterDropdownSection(
                                  title: 'Categorii',
                                  expanded: categoriesExpanded,
                                  options: _categories,
                                  selectedIds: _selectedCategoryIds,
                                  onToggle: () {
                                    setDialogState(() {
                                      categoriesExpanded = !categoriesExpanded;
                                    });
                                  },
                                  onSelected: (id) {
                                    _toggleCategory(id);
                                    setDialogState(() {});
                                  },
                                ),
                                const SizedBox(height: 8),
                                _buildFilterDropdownSection(
                                  title: 'Specializări',
                                  expanded: specializationsExpanded,
                                  options: _specializations,
                                  selectedIds: _selectedSpecializationIds,
                                  onToggle: () {
                                    setDialogState(() {
                                      specializationsExpanded =
                                          !specializationsExpanded;
                                    });
                                  },
                                  onSelected: (id) {
                                    _toggleSpecialization(id);
                                    setDialogState(() {});
                                  },
                                ),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        _resetFilters();
                                        setDialogState(() {});
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            PulseTheme.primaryLight,
                                        minimumSize: const Size(0, 34),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      icon: const Icon(Icons.close, size: 15),
                                      label: const Text('Șterge filtre'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildHeaderIconButton({
    IconData? icon,
    String? iconAsset,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _darkCanvas.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PulseTheme.primaryLight.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Center(
              child: iconAsset != null
                  ? SvgPicture.asset(
                      iconAsset,
                      width: 17,
                      height: 17,
                      colorFilter: const ColorFilter.mode(
                        _darkText,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(icon, color: _darkText, size: 18),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: PulseTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _darkSurface, width: 1.4),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdownSection({
    required String title,
    required bool expanded,
    required List<FilterOption> options,
    required Set<int> selectedIds,
    required VoidCallback onToggle,
    required ValueChanged<int> onSelected,
  }) {
    final selectedCount = options.where((option) {
      return selectedIds.contains(option.id);
    }).length;

    return Container(
      decoration: BoxDecoration(
        color: _darkCanvas.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PulseTheme.primaryLight.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selectedCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _neonPurple.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _neonBlue.withValues(alpha: 0.26),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$selectedCount',
                          style: const TextStyle(
                            color: _darkText,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: PulseTheme.animFast,
                      curve: PulseTheme.animCurve,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _darkMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: PulseTheme.animMedium,
            curve: PulseTheme.animCurve,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                    child: options.isEmpty
                        ? const Text(
                            'Nu exist\u0103 op\u021biuni disponibile.',
                            style: TextStyle(
                              color: _darkMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: options.map((option) {
                              return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 170,
                                ),
                                child: _buildFilterChip(
                                  option: option,
                                  selected: selectedIds.contains(option.id),
                                  onSelected: onSelected,
                                ),
                              );
                            }).toList(),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompactHomeMenu() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Inchide meniul',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        void closeAndRun(VoidCallback callback) {
          Navigator.of(dialogContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) callback();
          });
        }

        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 48, right: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: _glassDecoration(
                      radius: 22,
                      opacity: 0.12,
                      borderColor: _neonPurple.withValues(alpha: 0.22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactMenuItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Profilul meu',
                          onTap: () => closeAndRun(_openProfile),
                        ),
                        _buildCompactMenuItem(
                          iconAsset: 'assets/icons/heart.svg',
                          label: 'Salvate',
                          onTap: () => closeAndRun(_openSavedContent),
                        ),
                        _buildCompactMenuItem(
                          iconAsset: 'assets/icons/wallet.svg',
                          label: 'Tranzacțiile mele',
                          onTap: () => closeAndRun(_openTransactions),
                        ),
                        _buildCompactMenuItem(
                          iconAsset: 'assets/icons/events.svg',
                          label: 'Biletele mele',
                          onTap: () => closeAndRun(_openTickets),
                        ),
                        _buildCompactMenuItem(
                          iconAsset: 'assets/icons/books.svg',
                          label: 'Abonamentele mele',
                          onTap: () => closeAndRun(_openMyPublications),
                        ),
                        _buildCompactMenuItem(
                          iconAsset: 'assets/icons/graduation.svg',
                          label: 'Cursurile mele',
                          onTap: () => closeAndRun(_openMyCourses),
                        ),
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        _buildCompactMenuItem(
                          iconAsset:
                              'assets/icons/rectangle.portrait.and.arrow.forward.svg',
                          label: 'Logout',
                          danger: true,
                          onTap: () => closeAndRun(_logout),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildCompactMenuItem({
    IconData? icon,
    String? iconAsset,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    assert(icon != null || iconAsset != null);
    final color = danger ? Colors.redAccent : _darkText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: iconAsset != null
                      ? SvgPicture.asset(
                          iconAsset,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                        )
                      : Icon(icon, color: color, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar() {
    final avatarUrl = _doctorAvatarUrl?.trim();

    return GestureDetector(
      onTap: _openProfile,
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: PulseTheme.avatarRingGradient,
          boxShadow: [
            BoxShadow(
              color: PulseTheme.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildHeaderAvatarFallback();
                  },
                )
              : _buildHeaderAvatarFallback(),
        ),
      ),
    );
  }

  Widget _buildHeaderAvatarFallback() {
    return Container(
      color: _darkCanvas,
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(
            color: _darkText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildStickyHomeHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _darkSurface.withValues(alpha: 0.86),
            border: Border(
              bottom: BorderSide(
                color: PulseTheme.primaryLight.withValues(alpha: 0.14),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
              BoxShadow(
                color: PulseTheme.primary.withValues(alpha: 0.12),
                blurRadius: 22,
                spreadRadius: -18,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 2),
                child: Row(
                  children: [
                    _buildHeaderAvatar(),
                    const Spacer(),
                    _buildHeaderIconButton(
                      iconAsset: 'assets/icons/bell.svg',
                      onTap: _openNotifications,
                      badgeCount: _unreadNotificationsCount,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderIconButton(
                      icon: Icons.tune_rounded,
                      onTap: _showFilterDropdown,
                      badgeCount: _activeFilterCount,
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderIconButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: _showCompactHomeMenu,
                    ),
                  ],
                ),
              ),
              _buildHomeTabSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTabSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: _glassDecoration(
              radius: 20,
              opacity: 0.05,
              borderColor: PulseTheme.primaryLight.withValues(alpha: 0.18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHomeTabOption(
                    label: 'ACASĂ',
                    icon: Icons.home_rounded,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildHomeTabOption(
                    label: 'FOR YOU',
                    icon: Icons.auto_awesome_rounded,
                    index: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTabOption({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedHomeTab == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectHomeTab(index),
      child: AnimatedContainer(
        duration: PulseTheme.animFast,
        curve: PulseTheme.animCurve,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected ? PulseTheme.primaryGradient : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PulseTheme.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -12,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: PulseTheme.animFast,
            curve: PulseTheme.animCurve,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : _darkMuted.withValues(alpha: 0.66),
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              letterSpacing: 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : _darkMuted.withValues(alpha: 0.62),
                    ),
                    const SizedBox(width: 6),
                    Text(label),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: PulseTheme.animFast,
                  curve: PulseTheme.animCurve,
                  width: isSelected ? 24 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.92)
                        : null,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.38),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForYouContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _neonPurple.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: _neonPurple.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 16),
              spreadRadius: -16,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: PulseTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _neonPurple.withValues(alpha: 0.42),
                    blurRadius: 26,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'For You',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkText,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Recomandări personalizate',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _neonBlue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Explorează articole, cursuri și reviste pentru a primi recomandări personalizate.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkMuted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouRecommendationsContent() {
    if (_isForYouLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 170, height: 24, radius: 10),
            SizedBox(height: 10),
            SkeletonBlock(width: 260, height: 16, radius: 8),
            SizedBox(height: 22),
            SkeletonBlock(height: 300, radius: 28),
          ],
        ),
      );
    }

    if (_forYouErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        child: _buildForYouMessageCard(
          icon: Icons.auto_awesome,
          title: 'For You',
          message: _forYouErrorMessage!,
          actionLabel: 'Reîncearcă',
          onAction: _loadForYouRecommendations,
        ),
      );
    }

    if (_forYouItems.isEmpty) {
      return _buildForYouContent();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: PulseTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _neonPurple.withValues(alpha: 0.42),
                        blurRadius: 22,
                        spreadRadius: -7,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'For You',
                        style: TextStyle(
                          color: _darkText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _forYouGeneratedWithAi
                            ? 'Recomandări cu explicații AI'
                            : 'Recomandări personalizate',
                        style: const TextStyle(
                          color: _darkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(_forYouItems.length, (index) {
                final item = _forYouItems[index];
                final reason = _forYouReasons[item.id];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _forYouItems.length - 1 ? 0 : 18,
                  ),
                  child: _buildForYouRecommendation(item, reason),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouMessageCard({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _neonPurple.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: _neonPurple.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: PulseTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _neonPurple.withValues(alpha: 0.42),
                  blurRadius: 26,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _darkMuted,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: PulseTheme.primary,
                side: BorderSide(
                  color: PulseTheme.primary.withValues(alpha: 0.24),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForYouRecommendation(ContentItem item, String? reason) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _verticalContentCard(
            item,
            infoText: reason?.trim().isNotEmpty == true
                ? reason!.trim()
                : 'Recomandat pe baza intereselor \u0219i activit\u0103\u021bii recente.',
          ),
        ),
        Positioned(top: 12, right: 12, child: _buildForYouFeedbackMenu(item)),
      ],
    );
  }

  Widget _buildVerticalContentFeed({
    required String title,
    required String emptyMessage,
    required String emptyIconAsset,
    required Color categoryColor,
    required List<ContentItem> items,
  }) {
    final countLabel = items.length == 1
        ? '1 material disponibil'
        : '${items.length} materiale disponibile';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.26),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    emptyIconAsset,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      categoryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items.isEmpty
                          ? 'Feed vertical premium'
                          : 'Feed vertical · $countLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 54,
            height: 2,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withValues(alpha: 0.38),
                  blurRadius: 14,
                  spreadRadius: -3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            _buildForYouMessageCard(
              icon: Icons.search_off_rounded,
              title: title,
              message: emptyMessage,
            )
          else
            Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 18,
                  ),
                  child: _verticalContentCard(item),
                );
              }),
            ),
        ],
      ),
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
        label: Text(option.name, overflow: TextOverflow.ellipsis),
        selected: selected,
        onSelected: (_) => onSelected(option.id),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        backgroundColor: Colors.white.withValues(alpha: 0.07),
        selectedColor: _neonPurple.withValues(alpha: 0.20),
        side: BorderSide(
          color: selected
              ? _neonBlue.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.14),
          width: selected ? 1.3 : 1,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        labelStyle: TextStyle(
          color: selected ? _darkText : _darkMuted,
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
          child: Text(
            label,
            style: const TextStyle(
              color: _darkText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: _buildFilterChip(
                option: option,
                selected: selectedIds.contains(option.id),
                onSelected: onSelected,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _activeFilterSummary() {
    final labels = <String>[];
    if (labels.length <= 2) return labels.join(' • ');
    return '${labels.take(2).join(' • ')} +${labels.length - 2}';
  }

  Widget _buildActiveFilterBadge() {
    if (!_hasActiveFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _neonPurple.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _neonBlue.withValues(alpha: 0.24)),
      ),
      child: Text(
        _activeFilterCount == 1
            ? '1 filtru activ'
            : '$_activeFilterCount filtre active',
        style: const TextStyle(
          color: _darkText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildContentFilters() {
    if (_selectedIndex != 0 ||
        _selectedHomeTab != 0 ||
        !_filtersExpanded ||
        (_categories.isEmpty && _specializations.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _filtersExpanded = !_filtersExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _neonPurple.withValues(alpha: 0.18),
                              border: Border.all(
                                color: _neonBlue.withValues(alpha: 0.18),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: _darkText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Filtre',
                              style: TextStyle(
                                color: _darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _buildActiveFilterBadge(),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _filtersExpanded ? 0.5 : 0,
                            duration: PulseTheme.animFast,
                            curve: PulseTheme.animCurve,
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: _darkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: PulseTheme.animMedium,
                  curve: PulseTheme.animCurve,
                  alignment: Alignment.topCenter,
                  child: _filtersExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Restrânge conținutul după interesul tău clinic.',
                                style: TextStyle(
                                  color: _darkMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildFilterRow(
                              label: 'Categorii',
                              options: _categories,
                              selectedIds: _selectedCategoryIds,
                              onSelected: _toggleCategory,
                            ),
                            if (_categories.isNotEmpty &&
                                _specializations.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                            _buildFilterRow(
                              label: 'Specializări',
                              options: _specializations,
                              selectedIds: _selectedSpecializationIds,
                              onSelected: _toggleSpecialization,
                            ),
                            if (_hasActiveFilters) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _resetFilters,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _neonBlue,
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Șterge filtre'),
                                ),
                              ),
                            ],
                          ],
                        )
                      : _hasActiveFilters
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(52, 6, 12, 2),
                          child: Text(
                            _activeFilterSummary(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _darkMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _neonPurple.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: PulseTheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _hasActiveFilters
                  ? 'Nu există conținut pentru filtrele selectate.'
                  : 'Nu există conținut publicat momentan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _darkText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: _neonBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Șterge filtre'),
              ),
            ],
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
      return const SkeletonLoading.feed(scrollable: false);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            children: [
              Text(_errorMessage!, style: const TextStyle(color: _darkMuted)),
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

    final newsSectionItems = _withoutFeaturedItems(_news).take(3).toList();
    final publicationSectionItems = _withoutFeaturedItems(
      _publications,
    ).take(3).toList();
    final eventSectionItems = _withoutFeaturedItems(_events).take(3).toList();
    final courseSectionItems = _withoutFeaturedItems(_courses).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _animatedSection(
          1,
          FeaturedCard(
            items: _featuredItems,
            isLoading: _isFeaturedLoading,
            autoSlide: true,
            savedContentIds: _savedContentIds,
            onSaveToggle: _toggleSavedContent,
            onItemTap: _openContentItem,
            darkMode: true,
            height: 210,
            viewportFraction: 0.94,
          ),
        ),

        if (_isFeaturedLoading || _featuredItems.isNotEmpty)
          const SizedBox(height: 24),

        if (!_isFeaturedLoading && !_hasAnyHomeContent)
          _animatedSection(2, _buildHomeEmptyState()),

        // Știri Section
        if (newsSectionItems.isNotEmpty) ...[
          _animatedSection(
            2,
            ContentSection(
              title: 'Știri',
              emptyMessage: 'Nu există încă știri publicate.',
              emptyIconAsset: 'assets/icons/newspaper.svg',
              categoryColor: PulseTheme.newsContent,
              editorialLayout: true,
              darkMode: true,
              featuredChild: FeaturedCard(
                items: newsSectionItems,
                savedContentIds: _savedContentIds,
                onSaveToggle: _toggleSavedContent,
                onItemTap: _openContentItem,
                darkMode: true,
                height: 204,
                viewportFraction: 0.92,
              ),
              onActionTap: () => _navigateToTab(4),
              children: const [],
            ),
          ),

          AdvertisementFeedSlot(
            ads: _adsByPlacement['home_after_news'] ?? const <AdItem>[],
            onAdTap: _handleAdTap,
          ),
        ],

        // Reviste Section
        if (publicationSectionItems.isNotEmpty) ...[
          _animatedSection(
            3,
            ContentSection(
              title: 'Reviste',
              emptyMessage: 'Nu există încă reviste publicate.',
              emptyIconAsset: 'assets/icons/books.svg',
              categoryColor: PulseTheme.magazineContent,
              editorialLayout: true,
              darkMode: true,
              featuredChild: FeaturedCard(
                items: publicationSectionItems,
                savedContentIds: _savedContentIds,
                onSaveToggle: _toggleSavedContent,
                onItemTap: _openContentItem,
                darkMode: true,
                height: 204,
                viewportFraction: 0.92,
              ),
              onActionTap: () => _navigateToTab(2),
              children: const [],
            ),
          ),

          AdvertisementFeedSlot(
            ads: _adsByPlacement['home_after_publications'] ?? const <AdItem>[],
            onAdTap: _handleAdTap,
          ),
        ],

        // Evenimente Section
        if (eventSectionItems.isNotEmpty) ...[
          _animatedSection(
            4,
            ContentSection(
              title: 'Evenimente',
              emptyMessage: 'Nu există încă evenimente publicate.',
              emptyIconAsset: 'assets/icons/events.svg',
              categoryColor: PulseTheme.eventContent,
              editorialLayout: true,
              darkMode: true,
              featuredChild: FeaturedCard(
                items: eventSectionItems,
                savedContentIds: _savedContentIds,
                onSaveToggle: _toggleSavedContent,
                onItemTap: _openContentItem,
                darkMode: true,
                height: 204,
                viewportFraction: 0.92,
              ),
              onActionTap: () => _navigateToTab(3),
              children: const [],
            ),
          ),

          AdvertisementFeedSlot(
            ads: _adsByPlacement['home_after_events'] ?? const <AdItem>[],
            onAdTap: _handleAdTap,
          ),
        ],

        // Cursuri Section
        if (courseSectionItems.isNotEmpty) ...[
          _animatedSection(
            5,
            ContentSection(
              title: 'Cursuri',
              emptyMessage: 'Nu există încă cursuri publicate.',
              emptyIconAsset: 'assets/icons/graduation.svg',
              categoryColor: PulseTheme.courseContent,
              editorialLayout: true,
              darkMode: true,
              featuredChild: FeaturedCard(
                items: courseSectionItems,
                savedContentIds: _savedContentIds,
                onSaveToggle: _toggleSavedContent,
                onItemTap: _openContentItem,
                darkMode: true,
                height: 204,
                viewportFraction: 0.92,
              ),
              onActionTap: () => _navigateToTab(1),
              children: const [],
            ),
          ),

          AdvertisementFeedSlot(
            ads: _adsByPlacement['home_after_courses'] ?? const <AdItem>[],
            onAdTap: _handleAdTap,
          ),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Main Home Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHomeContent() {
    return PageView(
      controller: _homeTabPageController,
      onPageChanged: _handleHomeTabPageChanged,
      children: [
        RefreshIndicator(
          color: _darkText,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildContentFilters(), _buildAcasaFeed()],
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildForYouRecommendationsContent()],
          ),
        ),
      ],
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
      return const SkeletonLoading.list(scrollable: false);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            children: [
              Text(_errorMessage!, style: const TextStyle(color: _darkMuted)),
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
          child: _buildVerticalContentFeed(
            title: title,
            emptyMessage: emptyMessage,
            emptyIconAsset: emptyIconAsset,
            categoryColor: categoryColor,
            items: items,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkCanvas,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildPostariMeleButton(),
      bottomNavigationBar: _buildGlassBottomNav(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_darkCanvas, _darkCanvasAlt, _darkViolet],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: PulseAnimatedBackground()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (_selectedIndex == 0) _buildStickyHomeHeader(),
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
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Glassmorphism Bottom Navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPostariMeleButton() {
    return Tooltip(
      message: 'Postările mele',
      child: Semantics(
        label: 'Postările mele',
        button: true,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: PulseTheme.primaryGradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: _neonPurple.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _openContentSubmissions,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                color: _darkSurface.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _neonPurple.withValues(alpha: 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: _neonPurple.withValues(alpha: 0.16),
                    blurRadius: 24,
                    spreadRadius: -14,
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
          color: isSelected ? null : Colors.transparent,
          gradient: isSelected ? PulseTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _neonPurple.withValues(alpha: 0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isSelected ? _darkText : _darkMuted.withValues(alpha: 0.62),
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
                          color: _darkText,
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

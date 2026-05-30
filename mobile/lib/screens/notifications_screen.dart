import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../widgets/home_header.dart';
import '../theme/pulse_theme.dart';
import '../widgets/emc_badge.dart';
import 'content_detail_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'saved_content_screen.dart';

enum NotificationType {
  emc,
  course,
  event,
  article,
  news,
  publication,
  system,
  account,
}

class NotificationItem {
  final int id;
  final int notificationId;
  final String title;
  final String body;
  final String time;
  final String notificationType;
  final NotificationType type;
  final String categoryCode;
  final String categoryName;
  final String? imageUrl;
  final int? contentItemId;
  bool isRead;
  final int? emcPoints;

  NotificationItem({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.time,
    required this.notificationType,
    required this.type,
    required this.categoryCode,
    required this.categoryName,
    this.imageUrl,
    this.contentItemId,
    this.isRead = false,
    this.emcPoints,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final categoryCode = (json['category_code'] as String?) ?? '';
    final notificationType = (json['notification_type'] as String?) ?? '';
    return NotificationItem(
      id: _readInt(json['user_notification_id']) ?? _readInt(json['id']) ?? 0,
      notificationId: _readInt(json['notification_id']) ?? 0,
      title: (json['title'] as String?) ?? 'Notificare',
      body: (json['description'] as String?) ?? '',
      time: _formatRelativeTime(json['delivered_at'] ?? json['assigned_at']),
      notificationType: notificationType,
      type: _mapType(notificationType, categoryCode),
      categoryCode: categoryCode,
      categoryName:
          (json['category_name'] as String?) ??
          _fallbackCategoryName(categoryCode),
      imageUrl: json['image_url'] as String?,
      contentItemId: _readInt(json['content_item_id']),
      isRead: json['is_read'] == true || json['read_at'] != null,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static NotificationType _mapType(
    String notificationType,
    String categoryCode,
  ) {
    if (categoryCode == 'emc') return NotificationType.emc;
    if (categoryCode == 'course') return NotificationType.course;
    if (categoryCode == 'event') return NotificationType.event;
    if (categoryCode == 'article') return NotificationType.article;
    if (categoryCode == 'news') return NotificationType.news;
    if (categoryCode == 'publication') return NotificationType.publication;
    if (notificationType == 'account') return NotificationType.account;
    return NotificationType.system;
  }

  static String _fallbackCategoryName(String code) {
    const names = {
      'emc': 'Puncte EMC',
      'profile': 'Profil',
      'security': 'Securitate',
      'subscription': 'Abonament',
      'maintenance': 'Mentenanță',
      'announcement': 'Anunț',
      'update': 'Actualizare',
      'news': 'Știri',
      'article': 'Articole',
      'event': 'Evenimente',
      'course': 'Cursuri',
      'publication': 'Reviste',
    };
    return names[code] ?? 'Notificare';
  }

  static String _formatRelativeTime(dynamic value) {
    if (value is! String || value.isEmpty) return 'Acum';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Acum';
    if (diff.inMinutes < 60) return 'Acum ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Acum ${diff.inHours} ore';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return 'Acum ${diff.inDays} zile';
    return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Toate', 'Necitite', 'Puncte EMC'];
  final Set<int> _expandedIds = {};
  final ApiService _apiService = ApiService();
  final AuthStorage _authStorage = AuthStorage();
  String _doctorName = 'Medic';
  int _emcPoints = 0;
  bool _isLoadingNotifications = true;
  String? _notificationsError;
  final List<NotificationItem> _allNotifications = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadDoctorName();
    _loadNotifications();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 0) return _allNotifications;
    if (_selectedFilterIndex == 1) {
      return _allNotifications.where((n) => !n.isRead).toList();
    }
    if (_selectedFilterIndex == 2) {
      return _allNotifications
          .where((n) => n.type == NotificationType.emc)
          .toList();
    }
    return _allNotifications;
  }

  Future<void> _loadDoctorName() async {
    final cachedName = await _authStorage.getUserName();
    if (cachedName != null && cachedName.trim().isNotEmpty && mounted) {
      setState(() {
        _doctorName = cachedName.trim();
      });
    }

    try {
      final profileData = await _apiService.getMyProfile();
      final freshName = profileData['display_name'] as String?;
      final totalEmcPoints = _readTotalEmcPoints(profileData);
      if (freshName != null && freshName.trim().isNotEmpty) {
        await _authStorage.saveUserName(freshName.trim());
      }
      if (mounted) {
        setState(() {
          if (freshName != null && freshName.trim().isNotEmpty) {
            _doctorName = freshName.trim();
          }
          _emcPoints = totalEmcPoints;
        });
      }
    } catch (e) {
      debugPrint('Eroare la obținerea numelui medicului din API: $e');
    }
  }

  int _readTotalEmcPoints(Map<String, dynamic> profileData) {
    final directValue = profileData['total_emc_points'];
    if (directValue is int) return directValue;
    if (directValue is num) return directValue.toInt();
    if (directValue is String) return int.tryParse(directValue) ?? 0;

    final profile = profileData['profile'];
    if (profile is Map<String, dynamic>) {
      final profileValue = profile['total_emc_points'];
      if (profileValue is int) return profileValue;
      if (profileValue is num) return profileValue.toInt();
      if (profileValue is String) return int.tryParse(profileValue) ?? 0;
    }
    return 0;
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
      _notificationsError = null;
    });
    try {
      final rows = await _apiService.getNotifications();
      final items = rows.map(NotificationItem.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _allNotifications
          ..clear()
          ..addAll(items);
        _isLoadingNotifications = false;
      });
      _animController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingNotifications = false;
        _notificationsError = 'Nu am putut încărca notificările.';
      });
    }
  }

  Future<void> _openContent(NotificationItem item) async {
    final contentItemId = item.contentItemId;
    if (contentItemId == null) return;
    await _markRead(item.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentItemId: contentItemId),
      ),
    );
  }

  Future<void> _openProfileFromNotification(NotificationItem item) async {
    await _markRead(item.id);
    if (!mounted) return;
    await _openProfile();
  }

  Future<void> _markRead(int userNotificationId) async {
    final idx = _allNotifications.indexWhere((n) => n.id == userNotificationId);
    if (idx == -1 || _allNotifications[idx].isRead) return;
    setState(() {
      _allNotifications[idx].isRead = true;
    });
    try {
      await _apiService.markNotificationRead(userNotificationId);
    } catch (e) {
      debugPrint('Nu am putut marca notificarea citită: $e');
    }
  }

  Future<void> _openSavedContent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SavedContentScreen()),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
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

  void _toggleExpand(int id) {
    int? userNotificationIdToMark;
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
        final idx = _allNotifications.indexWhere((n) => n.id == id);
        if (idx != -1 && !_allNotifications[idx].isRead) {
          _allNotifications[idx].isRead = true;
          userNotificationIdToMark = _allNotifications[idx].id;
        }
      }
    });
    if (userNotificationIdToMark != null) {
      _apiService.markNotificationRead(userNotificationIdToMark!).catchError((
        e,
      ) {
        debugPrint('Nu am putut marca notificarea citită: $e');
      });
    }
    HapticFeedback.lightImpact();
  }

  void _deleteNotification(int id) {
    setState(() {
      _allNotifications.removeWhere((n) => n.id == id);
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredNotifications;

    return Scaffold(
      backgroundColor: PulseTheme.background,
      body: Stack(
        children: [
          // Background ambient elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PulseTheme.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  doctorName: _doctorName,
                  avatarUrl: '',
                  emcPoints: _emcPoints,
                  onNotificationsTap: () {},
                  onSavedTap: _openSavedContent,
                  onProfileTap: _openProfile,
                  onLogoutTap: _logout,
                  darkMode: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: SvgPicture.asset(
                          'assets/icons/arrow.backward.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            PulseTheme.textPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            PulseTheme.primaryGradient.createShader(bounds),
                        child: const Text(
                          'Notificări',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Conținutul paginii cu scroll
                Expanded(
                  child: RefreshIndicator(
                    color: PulseTheme.primary,
                    onRefresh: _loadNotifications,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        _buildFilters(),
                        if (_isLoadingNotifications)
                          _buildLoadingState()
                        else if (_notificationsError != null)
                          _buildErrorState()
                        else if (items.isEmpty)
                          _buildEmptyState()
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final notification = items[index];
                                return _buildAnimatedNotificationCard(
                                  notification,
                                  index,
                                );
                              }, childCount: items.length),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Removed SliverAppBar as we are using a fixed standard layout now

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: PulseTheme.border.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _filters.length;
              return Stack(
                children: [
                  // Sliding pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    left: _selectedFilterIndex * tabWidth,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: PulseTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tab labels (on top of pill)
                  Row(
                    children: List.generate(_filters.length, (index) {
                      final bool isActive = _selectedFilterIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedFilterIndex != index) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                              _animController.forward(from: 0.0);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  color: isActive
                                      ? PulseTheme.textPrimary
                                      : PulseTheme.textSecondary.withValues(
                                          alpha: 0.6,
                                        ),
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PulseTheme.primary.withValues(alpha: 0.05),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/bell.svg',
                  width: 40,
                  height: 40,
                  colorFilter: ColorFilter.mode(
                    PulseTheme.primary.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nu ai notificări',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: PulseTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aici vei găsi toate alertele importante\nși actualizările de pe platformă.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: PulseTheme.textSecondary.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: CircularProgressIndicator(color: PulseTheme.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _notificationsError ?? 'A apărut o eroare.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PulseTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadNotifications,
                child: const Text('Încearcă din nou'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNotificationCard(NotificationItem item, int index) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: _buildNotificationCard(item, index),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, int index) {
    final bool isExpanded = _expandedIds.contains(item.id);
    Color iconColor;
    String iconPath;
    final isContentNotification = item.notificationType == 'content';
    final contentBadgeIconPath = _contentBadgeIconPath(item.categoryCode);

    switch (item.type) {
      case NotificationType.emc:
        iconColor = const Color(0xFF8B5CF6);
        iconPath = 'assets/icons/EMC.svg';
        break;
      case NotificationType.course:
        iconColor = const Color(0xFF3B82F6);
        iconPath = 'assets/icons/graduation.svg';
        break;
      case NotificationType.event:
        iconColor = const Color(0xFF10B981);
        iconPath = 'assets/icons/events.svg';
        break;
      case NotificationType.article:
        iconColor = const Color(0xFF2563EB);
        iconPath = 'assets/icons/book.pages.svg';
        break;
      case NotificationType.news:
        iconColor = const Color(0xFFEF4444);
        iconPath = 'assets/icons/newspaper.svg';
        break;
      case NotificationType.publication:
        iconColor = const Color(0xFF7C3AED);
        iconPath = 'assets/icons/books.svg';
        break;
      case NotificationType.account:
        iconColor = const Color(0xFF059669);
        iconPath = 'assets/icons/person.text.rectangle.fill.svg';
        break;
      case NotificationType.system:
        iconColor = const Color(0xFFF59E0B);
        iconPath = 'assets/icons/bell.svg';
        break;
    }

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(item.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: GestureDetector(
        onTap: () => _toggleExpand(item.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: item.isRead
                ? PulseTheme.surface
                : PulseTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            boxShadow: item.isRead
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Circular local fallback with category badge overlay
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        iconColor.withValues(alpha: 0.16),
                                        iconColor.withValues(alpha: 0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child:
                                      isContentNotification &&
                                          (item.imageUrl ?? '').isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Center(
                                                    child: SvgPicture.asset(
                                                      iconPath,
                                                      width: 24,
                                                      height: 24,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                            iconColor,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                                  ),
                                        )
                                      : Center(
                                          child: SvgPicture.asset(
                                            iconPath,
                                            width: 24,
                                            height: 24,
                                            colorFilter: ColorFilter.mode(
                                              iconColor,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                ),
                                if (isContentNotification &&
                                    contentBadgeIconPath != null)
                                  Positioned(
                                    top: -5,
                                    left: -5,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: PulseTheme.surface.withValues(
                                          alpha: 0.86,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.72,
                                          ),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.10,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          contentBadgeIconPath,
                                          width: 13,
                                          height: 13,
                                          colorFilter: ColorFilter.mode(
                                            iconColor,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    scale: !item.isRead ? 1.0 : 0.0,
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: item.isRead
                                              ? PulseTheme.surface
                                              : PulseTheme.surfaceElevated,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content Title Area
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 54),
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.time,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: item.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                      color: item.isRead
                                          ? PulseTheme.textPrimary.withValues(
                                              alpha: 0.8,
                                            )
                                          : PulseTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item.categoryName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: iconColor,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: item.isRead
                                          ? FontWeight.w700
                                          : FontWeight.w800,
                                      color: item.isRead
                                          ? PulseTheme.textPrimary.withValues(
                                              alpha: 0.8,
                                            )
                                          : PulseTheme.textPrimary,
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Body Content expanding under the image
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        firstCurve: Curves.easeOutCubic,
                        secondCurve: Curves.easeOutCubic,
                        sizeCurve: Curves.easeOutCubic,
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox(
                          width: double.infinity,
                          height: 0,
                        ),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((item.type == NotificationType.course ||
                                      item.type == NotificationType.event) &&
                                  item.emcPoints != null) ...[
                                EmcBadge(points: '+${item.emcPoints}'),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                item.body,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: item.isRead
                                      ? PulseTheme.textSecondary.withValues(
                                          alpha: 0.7,
                                        )
                                      : PulseTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              if (isContentNotification ||
                                  item.type == NotificationType.emc) ...[
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: isContentNotification
                                      ? () => _openContent(item)
                                      : () =>
                                            _openProfileFromNotification(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: PulseTheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isContentNotification
                                              ? 'Află mai multe'
                                              : 'Vezi profilul',
                                          style: const TextStyle(
                                            color: PulseTheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        SvgPicture.asset(
                                          'assets/icons/arrow.right.svg',
                                          width: 14,
                                          height: 14,
                                          colorFilter: const ColorFilter.mode(
                                            PulseTheme.primary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ],
                                    ),
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
        ),
      ),
    );
  }

  String? _contentBadgeIconPath(String categoryCode) {
    switch (categoryCode) {
      case 'news':
        return 'assets/icons/newspaper.svg';
      case 'article':
        return 'assets/icons/book.pages.svg';
      case 'event':
        return 'assets/icons/calendar.svg';
      case 'course':
        return 'assets/icons/graduation.svg';
      case 'publication':
        return 'assets/icons/books.svg';
      default:
        return null;
    }
  }
}

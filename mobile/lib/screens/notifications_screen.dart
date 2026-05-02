
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/home_header.dart';
import '../theme/pulse_theme.dart';
import '../widgets/emc_badge.dart';

enum NotificationType { emc, course, system, event }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final NotificationType type;
  final String imageUrl;
  bool isRead;
  final int? emcPoints;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.imageUrl,
    this.isRead = false,
    this.emcPoints,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Toate', 'Necitite', 'Puncte EMC'];
  final Set<String> _expandedIds = {};

  // Mock Date
  final List<NotificationItem> _allNotifications = [
    NotificationItem(
      id: '1',
      title: 'Au fost adăugate 15 Puncte EMC!',
      body: 'Felicitări pentru finalizarea modulului "Managementul Durerii Cronice". Punctele au fost adăugate în portofoliul tău profesional.',
      time: 'Acum 2 ore',
      type: NotificationType.emc,
      imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&q=80&w=100',
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Curs nou disponibil',
      body: 'Te-ar putea interesa un nou curs: "Imunoterapia în Oncologie - Update 2026".',
      time: 'Acum 5 ore',
      type: NotificationType.course,
      imageUrl: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=100',
      isRead: false,
      emcPoints: 12,
    ),
    NotificationItem(
      id: '3',
      title: 'Actualizare sistem PULSE',
      body: 'Platforma a fost actualizată pentru a fi mai fluidă și mai stabilă. Verifică noile secțiuni!',
      time: 'Ieri, 14:30',
      type: NotificationType.system,
      imageUrl: 'https://images.unsplash.com/photo-1551076805-e18690c5e53b?auto=format&fit=crop&q=80&w=100',
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Reminder Eveniment',
      body: 'Simpozionul de Medicină Internă începe mâine dimineață la ora 09:00. Pregătește-te de conferință!',
      time: '29 Martie',
      type: NotificationType.event,
      imageUrl: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&q=80&w=100',
      isRead: true,
      emcPoints: 5,
    ),
  ];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 0) return _allNotifications;
    if (_selectedFilterIndex == 1) return _allNotifications.where((n) => !n.isRead).toList();
    if (_selectedFilterIndex == 2) return _allNotifications.where((n) => n.type == NotificationType.emc).toList();
    if (_selectedFilterIndex == 3) return _allNotifications.where((n) => n.type == NotificationType.system).toList();
    return _allNotifications;
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
        final idx = _allNotifications.indexWhere((n) => n.id == id);
        if (idx != -1 && !_allNotifications[idx].isRead) {
          _allNotifications[idx].isRead = true;
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  void _deleteNotification(String id) {
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
                // Același header ca pe pagina principală
                const HomeHeader(
                  doctorName: 'Robert',
                ),
                
                // Back Button & Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                          colorFilter: const ColorFilter.mode(PulseTheme.textPrimary, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => PulseTheme.primaryGradient.createShader(bounds),
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
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      _buildFilters(),
                      if (items.isEmpty)
                        _buildEmptyState()
                      else
                        SliverPadding(
                          padding: const EdgeInsets.only(bottom: 40),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final notification = items[index];
                                return _buildAnimatedNotificationCard(notification, index);
                              },
                              childCount: items.length,
                            ),
                          ),
                        ),
                    ],
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
                                  color: isActive ? PulseTheme.textPrimary : PulseTheme.textSecondary.withValues(alpha: 0.6),
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
                  colorFilter: ColorFilter.mode(PulseTheme.primary.withValues(alpha: 0.5), BlendMode.srcIn),
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

  Widget _buildAnimatedNotificationCard(NotificationItem item, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
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
            )
          ],
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
      ),
      child: GestureDetector(
        onTap: () => _toggleExpand(item.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: item.isRead ? PulseTheme.surface : PulseTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            boxShadow: item.isRead
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
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
                          // Circular Image with category badge overlay
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
                                    image: DecorationImage(
                                      image: NetworkImage(item.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  left: -4,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: iconColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: item.isRead ? PulseTheme.surface : PulseTheme.surfaceElevated, width: 2.5),
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        iconPath,
                                        width: 14,
                                        height: 14,
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                                        border: Border.all(color: item.isRead ? PulseTheme.surface : PulseTheme.surfaceElevated, width: 2.5),
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
                                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w600,
                                      color: item.isRead ? PulseTheme.textPrimary.withValues(alpha: 0.8) : PulseTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                                      color: item.isRead ? PulseTheme.textPrimary.withValues(alpha: 0.8) : PulseTheme.textPrimary,
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
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        firstChild: const SizedBox(width: double.infinity, height: 0),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((item.type == NotificationType.course || item.type == NotificationType.event) && item.emcPoints != null) ...[
                                EmcBadge(points: '+${item.emcPoints}'),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                item.body,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: item.isRead ? PulseTheme.textSecondary.withValues(alpha: 0.7) : PulseTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: PulseTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Află mai multe',
                                      style: TextStyle(
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
                                      colorFilter: const ColorFilter.mode(PulseTheme.primary, BlendMode.srcIn),
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
  }
}

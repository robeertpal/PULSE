import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

enum NotificationType { emc, course, system, event }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Toate', 'Necitite', 'Puncte EMC', 'Sistem'];

  // Mock Date
  final List<NotificationItem> _allNotifications = [
    NotificationItem(
      id: '1',
      title: 'Au fost adăugate 15 Puncte EMC!',
      body: 'Felicitări pentru finalizarea modulului "Managementul Durerii Cronice". Punctele au fost adăugate în portofoliul tău profesional.',
      time: 'Acum 2 ore',
      type: NotificationType.emc,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Curs nou disponibil',
      body: 'Te-ar putea interesa un nou curs: "Imunoterapia în Oncologie - Update 2026".',
      time: 'Acum 5 ore',
      type: NotificationType.course,
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Actualizare sistem PULSE',
      body: 'Platforma a fost actualizată pentru a fi mai fluidă și mai stabilă. Verifică noile secțiuni!',
      time: 'Ieri',
      type: NotificationType.system,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'Reminder Eveniment',
      body: 'Simpozionul de Medicină Internă începe mâine dimineață la ora 09:00. Pregătește-te de conferință!',
      time: '29 Martie',
      type: NotificationType.event,
      isRead: true,
    ),
  ];

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilterIndex == 0) {
      return _allNotifications;
    } else if (_selectedFilterIndex == 1) {
      return _allNotifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilterIndex == 2) {
      return _allNotifications.where((n) => n.type == NotificationType.emc).toList();
    } else if (_selectedFilterIndex == 3) {
      return _allNotifications.where((n) => n.type == NotificationType.system).toList();
    }
    return _allNotifications;
  }

  void _markAsRead(int index) {
    setState(() {
      _filteredNotifications[index].isRead = true;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _allNotifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredNotifications;

    return Scaffold(
      backgroundColor: PulseTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Modern Sliver App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverAppBar(
            backgroundColor: PulseTheme.background.withValues(alpha: 0.9),
            elevation: 0,
            pinned: true,
            expandedHeight: 130,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: PulseTheme.textPrimary),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                const SizedBox(width: 8),
              ],
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate fade based on scroll offset.
                    final top = constraints.biggest.height;
                    double titleOp = 1.0 - ((top - kToolbarHeight) / (130 - kToolbarHeight));
                    titleOp = titleOp.clamp(0.0, 1.0);

                    return Stack(
                      children: [
                        Positioned(
                          left: 60,
                          bottom: 16,
                          child: Opacity(
                            opacity: titleOp,
                            child: const Text(
                              'Notificări',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: PulseTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 16,
                          child: Opacity(
                            opacity: 1.0 - titleOp,
                            child: const Text(
                              'Notificări',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                color: PulseTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Filter Pills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final bool isSelected = _selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? PulseTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? PulseTheme.primary : PulseTheme.border,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: PulseTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : PulseTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Notifications List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/bell.svg',
                      width: 64,
                      height: 64,
                      colorFilter: ColorFilter.mode(PulseTheme.textSecondary.withValues(alpha: 0.3), BlendMode.srcIn),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aici este liniște',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PulseTheme.textPrimary.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nu ai nicio notificare pentru acest filtru.',
                      style: TextStyle(fontSize: 15, color: PulseTheme.textSecondary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notification = items[index];
                  return _buildNotificationCard(notification, index);
                },
                childCount: items.length,
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, int index) {
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
      onDismissed: (direction) {
        _deleteNotification(item.id);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () {
          if (!item.isRead) _markAsRead(_filteredNotifications.indexOf(item));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white.withValues(alpha: 0.6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isRead ? Colors.white.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: item.isRead
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: item.isRead ? PulseTheme.textPrimary.withValues(alpha: 0.8) : PulseTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        // Unread Dot
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444), // Active notification dot
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: item.isRead ? PulseTheme.textSecondary.withValues(alpha: 0.7) : PulseTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: PulseTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


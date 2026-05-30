import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

class HomeHeader extends StatefulWidget {
  final String doctorName;
  final String avatarUrl;
  final int emcPoints;
  final int savedCount;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSavedTap;
  final VoidCallback? onLogoutTap;
  final VoidCallback? onProfileTap;

  final bool compactMode;
  final bool darkMode;

  const HomeHeader({
    super.key,
    required this.doctorName,
    this.avatarUrl = '',
    this.emcPoints = 0,
    this.savedCount = 0,
    this.unreadNotificationsCount = 0,
    this.onNotificationsTap,
    this.onSavedTap,
    this.onLogoutTap,
    this.onProfileTap,
    this.compactMode = false,
    this.darkMode = false,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bună dimineața';
    if (hour < 18) return 'Bună ziua';
    return 'Bună seara';
  }

  @override
  Widget build(BuildContext context) {
    final primaryText = widget.darkMode ? Colors.white : PulseTheme.textPrimary;
    final secondaryText = widget.darkMode
        ? const Color(0xFFB9C5E4)
        : PulseTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Top Row: Avatar + Greeting | Actions â”€â”€
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with premium gradient ring
              GestureDetector(
                onTap: widget.onProfileTap,
                child: _buildAvatar(),
              ),
              const SizedBox(width: 14),
              // Greeting + Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeGreeting(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Dr. ${widget.doctorName}',
                      style: TextStyle(
                        fontSize: widget.darkMode ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // â”€â”€ Right side action icons â”€â”€
              _buildEmcChip(),
              if (!widget.compactMode) ...[
                const SizedBox(width: 10),
                _buildIconButton(
                  'assets/icons/heart.svg',
                  onTap: widget.onSavedTap ?? () {},
                  badgeCount: widget.savedCount,
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  'assets/icons/bell.svg',
                  onTap: widget.onNotificationsTap ?? () {},
                  badgeCount: widget.unreadNotificationsCount,
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  'assets/icons/ellipsis.svg',
                  onTap: () => _showPremiumMenu(context),
                  iconSize: 4,
                ),
              ],
            ],
          ),
          if (!widget.compactMode) ...[
            const SizedBox(height: 16),
            Text(
              'Explorează noutățile medicale de azi.',
              style: TextStyle(
                color: secondaryText,
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // â”€â”€ Premium Avatar with gradient ring â”€â”€
  Widget _buildAvatar() {
    return Container(
      width: widget.darkMode ? 42 : 48,
      height: widget.darkMode ? 42 : 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PulseTheme.avatarRingGradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.darkMode ? const Color(0xFF0B1530) : PulseTheme.surface,
        ),
        child: ClipOval(
          child: widget.avatarUrl.isNotEmpty
              ? Image.network(
                  widget.avatarUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildAvatarPlaceholder(),
                )
              : _buildAvatarPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final iconColor = widget.darkMode
        ? const Color(0xFFB9C5E4)
        : PulseTheme.textSecondary;

    return Center(
      child: SvgPicture.asset(
        'assets/icons/people.svg',
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  // â”€â”€ EMC Points Chip â”€â”€
  Widget _buildEmcChip() {
    final textColor = widget.darkMode ? Colors.white : PulseTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.darkMode
            ? Colors.white.withValues(alpha: 0.08)
            : PulseTheme.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: widget.darkMode
            ? Border.all(color: Colors.white.withValues(alpha: 0.10))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/EMC.svg', width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            '${widget.emcPoints}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Small icon button (bell, menu) â”€â”€
  Widget _buildIconButton(
    String iconPath, {
    required VoidCallback onTap,
    double iconSize = 20,
    int badgeCount = 0,
  }) {
    final iconColor = widget.darkMode ? Colors.white : PulseTheme.textPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: widget.darkMode
              ? Colors.white.withValues(alpha: 0.08)
              : PulseTheme.border.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: widget.darkMode
              ? Border.all(color: Colors.white.withValues(alpha: 0.12))
              : null,
          boxShadow: widget.darkMode
              ? [
                  BoxShadow(
                    color: PulseTheme.primary.withValues(alpha: 0.16),
                    blurRadius: 18,
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: SvgPicture.asset(
                iconPath,
                height: iconSize,
                width: iconSize,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: badgeCount > 9 ? 3 : 7,
                top: 5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: widget.darkMode
                          ? const Color(0xFF0B1530)
                          : PulseTheme.surface,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Premium Dropdown Menu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showPremiumMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Închide',
      barrierColor: Colors.black.withValues(alpha: 0.07),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 64, right: 20),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownItem(
                            context,
                            'Profilul meu',
                            'assets/icons/people.svg',
                            onTap: widget.onProfileTap,
                          ),
                          _buildDropdownItem(
                            context,
                            'Cursurile mele',
                            'assets/icons/graduation.svg',
                          ),
                          _buildDropdownItem(
                            context,
                            'Revistele mele',
                            'assets/icons/books.svg',
                          ),
                          _buildDropdownItem(
                            context,
                            'Biletele mele',
                            'assets/icons/events.svg',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 6.0,
                            ),
                            child: Divider(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          _buildDropdownItem(
                            context,
                            'Favorite',
                            'assets/icons/heart.svg',
                            onTap: widget.onSavedTap,
                          ),
                          if (widget.onLogoutTap != null)
                            _buildLogoutItem(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final fadeAnimation = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(curvedAnimation);
        final scaleAnimation = Tween<double>(
          begin: 0.96,
          end: 1,
        ).animate(curvedAnimation);
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.04, -0.015),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: Alignment.topRight,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownItem(
    BuildContext context,
    String title,
    String iconPath, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        if (onTap != null) {
          Future.delayed(const Duration(milliseconds: 200), onTap);
          return;
        }
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          Navigator.of(this.context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(title)),
                body: Center(
                  child: Text(
                    'Pagina $title\nEste în faza de dezvoltare',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        });
      },
      splashColor: PulseTheme.primary.withValues(alpha: 0.1),
      highlightColor: PulseTheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    PulseTheme.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: PulseTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Future.delayed(const Duration(milliseconds: 200), () {
          widget.onLogoutTap?.call();
        });
      },
      splashColor: Colors.red.withValues(alpha: 0.1),
      highlightColor: Colors.red.withValues(alpha: 0.05),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Center(
                child: Icon(Icons.logout, size: 20, color: Colors.redAccent),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ieșire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

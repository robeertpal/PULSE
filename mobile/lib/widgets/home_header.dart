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
  final VoidCallback? onTransactionsTap;
  final VoidCallback? onTicketsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final bool filtersExpanded;
  final bool showFilterButton;

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
    this.onTransactionsTap,
    this.onTicketsTap,
    this.onProfileTap,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.filtersExpanded = false,
    this.showFilterButton = false,
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
    final isCompactMobile = MediaQuery.sizeOf(context).width < 430;
    final primaryText = widget.darkMode ? Colors.white : PulseTheme.textPrimary;
    final secondaryText = widget.darkMode
        ? const Color(0xFFB9C5E4)
        : PulseTheme.textSecondary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompactMobile ? 14 : 20,
        isCompactMobile ? 6 : 10,
        isCompactMobile ? 14 : 20,
        isCompactMobile ? 4 : 8,
      ),
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
              SizedBox(width: isCompactMobile ? 9 : 14),
              // Greeting + Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeGreeting(),
                      style: TextStyle(
                        fontSize: isCompactMobile ? 11 : 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(height: isCompactMobile ? 0 : 1),
                    Text(
                      'Dr. ${widget.doctorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompactMobile
                            ? 14.5
                            : (widget.darkMode ? 17 : 20),
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
                SizedBox(width: isCompactMobile ? 5 : 10),
                _buildIconButton(
                  'assets/icons/heart.svg',
                  onTap: widget.onSavedTap ?? () {},
                  badgeCount: widget.savedCount,
                ),
                SizedBox(width: isCompactMobile ? 5 : 8),
                _buildIconButton(
                  'assets/icons/bell.svg',
                  onTap: widget.onNotificationsTap ?? () {},
                  badgeCount: widget.unreadNotificationsCount,
                ),
                SizedBox(width: isCompactMobile ? 5 : 8),
                _buildIconButton(
                  'assets/icons/ellipsis.svg',
                  onTap: () => _showPremiumMenu(context),
                  iconSize: 4,
                ),
              ],
            ],
          ),
          if (!widget.compactMode) ...[
            SizedBox(height: isCompactMobile ? 6 : 12),
            Text(
              'Explorează noutățile medicale de azi.',
              style: TextStyle(
                color: secondaryText,
                fontWeight: FontWeight.w500,
                fontSize: isCompactMobile ? 11.5 : 13.5,
                letterSpacing: -0.1,
              ),
            ),
            if (widget.showFilterButton && widget.onFilterTap != null) ...[
              SizedBox(height: isCompactMobile ? 6 : 8),
              Align(
                alignment: Alignment.centerRight,
                child: _buildFilterButton(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // â”€â”€ Premium Avatar with gradient ring â”€â”€
  Widget _buildAvatar() {
    final isCompactMobile = MediaQuery.sizeOf(context).width < 430;
    final size = isCompactMobile ? 34.0 : (widget.darkMode ? 42.0 : 48.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PulseTheme.avatarRingGradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            blurRadius: isCompactMobile ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompactMobile ? 2 : 2.5),
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
    final isCompactMobile = MediaQuery.sizeOf(context).width < 430;
    final iconColor = widget.darkMode
        ? const Color(0xFFB9C5E4)
        : PulseTheme.textSecondary;

    return Center(
      child: SvgPicture.asset(
        'assets/icons/people.svg',
        width: isCompactMobile ? 17 : 22,
        height: isCompactMobile ? 17 : 22,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  // â”€â”€ EMC Points Chip â”€â”€
  Widget _buildEmcChip() {
    final isCompactMobile = MediaQuery.sizeOf(context).width < 430;
    final textColor = widget.darkMode ? Colors.white : PulseTheme.textPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactMobile ? 8 : 12,
        vertical: isCompactMobile ? 6 : 8,
      ),
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
          SvgPicture.asset(
            'assets/icons/EMC.svg',
            width: isCompactMobile ? 13 : 16,
            height: isCompactMobile ? 13 : 16,
          ),
          SizedBox(width: isCompactMobile ? 4 : 6),
          Text(
            '${widget.emcPoints}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: isCompactMobile ? 12 : 14,
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
    final isCompactMobile = MediaQuery.sizeOf(context).width < 430;
    final iconColor = widget.darkMode ? Colors.white : PulseTheme.textPrimary;
    final buttonSize = isCompactMobile ? 32.0 : 38.0;
    final effectiveIconSize = iconSize == 4
        ? iconSize
        : (isCompactMobile ? 17.0 : iconSize);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: buttonSize,
        height: buttonSize,
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
                height: effectiveIconSize,
                width: effectiveIconSize,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                right: isCompactMobile ? 2 : (badgeCount > 9 ? 3 : 7),
                top: isCompactMobile ? 3 : 5,
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

  Widget _buildFilterButton() {
    final isCompactMobile = MediaQuery.sizeOf(context).width < 430;
    final borderColor = widget.filtersExpanded
        ? PulseTheme.primaryLight.withValues(alpha: 0.52)
        : Colors.white.withValues(alpha: 0.14);
    final backgroundColor = widget.filtersExpanded
        ? PulseTheme.primary.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: widget.onFilterTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: PulseTheme.animFast,
        curve: PulseTheme.animCurve,
        padding: EdgeInsets.symmetric(
          horizontal: isCompactMobile ? 10 : 12,
          vertical: isCompactMobile ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: widget.darkMode
              ? backgroundColor
              : PulseTheme.border.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.darkMode ? borderColor : PulseTheme.border,
          ),
          boxShadow: widget.darkMode
              ? [
                  BoxShadow(
                    color: PulseTheme.primaryLight.withValues(alpha: 0.12),
                    blurRadius: 18,
                    spreadRadius: -10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              color: widget.darkMode ? Colors.white : PulseTheme.textPrimary,
              size: isCompactMobile ? 15 : 17,
            ),
            SizedBox(width: isCompactMobile ? 5 : 7),
            Text(
              'Filtreaz\u0103',
              style: TextStyle(
                color: widget.darkMode ? Colors.white : PulseTheme.textPrimary,
                fontSize: isCompactMobile ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            if (widget.activeFilterCount > 0) ...[
              SizedBox(width: isCompactMobile ? 5 : 7),
              Container(
                constraints: BoxConstraints(
                  minWidth: isCompactMobile ? 16 : 18,
                ),
                height: isCompactMobile ? 16 : 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  gradient: PulseTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.activeFilterCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
            SizedBox(width: isCompactMobile ? 2 : 4),
            AnimatedRotation(
              turns: widget.filtersExpanded ? 0.5 : 0,
              duration: PulseTheme.animFast,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.darkMode
                    ? const Color(0xFFB9C5E4)
                    : PulseTheme.textSecondary,
                size: isCompactMobile ? 15 : 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Închide',
      barrierColor: Colors.black.withValues(
        alpha: widget.darkMode ? 0.34 : 0.07,
      ),
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
                        color: widget.darkMode
                            ? PulseTheme.surface.withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.darkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.6),
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
                            'Abonamentele mele',
                            'assets/icons/books.svg',
                          ),
                          _buildDropdownItem(
                            context,
                            'Tranzacțiile mele',
                            'assets/icons/wallet.svg',
                            onTap: widget.onTransactionsTap,
                          ),
                          _buildDropdownItem(
                            context,
                            'Biletele mele',
                            'assets/icons/events.svg',
                            onTap: widget.onTicketsTap,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 6.0,
                            ),
                            child: Divider(
                              height: 1,
                              color: widget.darkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
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

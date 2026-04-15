import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import '../screens/notifications_screen.dart';

class HomeHeader extends StatefulWidget {
  final String doctorName;
  final String avatarUrl;
  final int emcPoints;

  const HomeHeader({
    super.key,
    required this.doctorName,
    this.avatarUrl = '',
    this.emcPoints = 142,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // â”€â”€ Top Row: Avatar + Greeting | Actions â”€â”€
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with premium gradient ring
              GestureDetector(
                onTap: () {},
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: PulseTheme.textSecondary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Dr. ${widget.doctorName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: PulseTheme.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // â”€â”€ Right side action icons â”€â”€
              _buildEmcChip(),
              const SizedBox(width: 10),
              _buildIconButton(
                'assets/icons/bell.svg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                hasBadge: true,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                'assets/icons/ellipsis.svg',
                onTap: () => _showPremiumMenu(context),
                iconSize: 4,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Explorează noutățile medicale de azi.',
            style: TextStyle(
              color: PulseTheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Premium Avatar with gradient ring â”€â”€
  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: PulseTheme.surface,
        ),
        child: ClipOval(
          child: widget.avatarUrl.isNotEmpty
              ? Image.network(widget.avatarUrl, fit: BoxFit.cover)
              : Center(
                  child: SvgPicture.asset(
                    'assets/icons/people.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      PulseTheme.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // â”€â”€ EMC Points Chip â”€â”€
  Widget _buildEmcChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PulseTheme.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/EMC.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.emcPoints}',
            style: const TextStyle(
              color: PulseTheme.textPrimary,
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
  Widget _buildIconButton(String iconPath, {required VoidCallback onTap, double iconSize = 20, bool hasBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: PulseTheme.border.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Center(
              child: SvgPicture.asset(
                iconPath,
                height: iconSize,
                width: iconSize,
                colorFilter: const ColorFilter.mode(
                  PulseTheme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            if (hasBadge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: PulseTheme.surface, width: 1.5),
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
      barrierColor: Colors.black.withValues(alpha: 0.05),
      transitionDuration: const Duration(milliseconds: 250),
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
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
                          _buildDropdownItem(context, 'Profilul meu', 'assets/icons/people.svg'),
                          _buildDropdownItem(context, 'Cursurile mele', 'assets/icons/graduation.svg'),
                          _buildDropdownItem(context, 'Revistele mele', 'assets/icons/books.svg'),
                          _buildDropdownItem(context, 'Biletele mele', 'assets/icons/events.svg'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                            child: Divider(height: 1, color: Colors.black.withValues(alpha: 0.06)),
                          ),
                          _buildDropdownItem(context, 'Favorite', 'assets/icons/heart.svg'),
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
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDropdownItem(BuildContext context, String title, String iconPath) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
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
}

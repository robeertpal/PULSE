import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

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

class _HomeHeaderState extends State<HomeHeader> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    // Play shimmer once on load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _shimmerController.forward();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bună dimineața';
    if (hour < 18) return 'Bună ziua';
    return 'Bună seara';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar: Menu + Logo | Notification + Avatar ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showPremiumMenu(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/icons/ellipsis.svg',
                        height: 4,
                        width: 4,
                        colorFilter: const ColorFilter.mode(
                          PulseTheme.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/in-app-logo.png',
                    height: 55,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // EMC Points Mini Badge
                  _buildEmcMiniCard(),
                  const SizedBox(width: 16),
                  // Notification bell with subtle ring
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: PulseTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: PulseTheme.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/bell.svg',
                        height: 22,
                        width: 22,
                        colorFilter: const ColorFilter.mode(
                          PulseTheme.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar with gradient ring
                  _buildAvatarWithRing(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // ── Greeting Section ──
          Text(
            '${_getTimeGreeting()},',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              color: PulseTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Dr. ${widget.doctorName}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 6),
          // Shimmer subtitle
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment(_shimmerAnimation.value - 1, 0),
                    end: Alignment(_shimmerAnimation.value, 0),
                    colors: const [
                      PulseTheme.textSecondary,
                      PulseTheme.primary,
                      PulseTheme.textSecondary,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                child: child!,
              );
            },
            child: Text(
              'Explorează noutățile medicale de azi.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white, // ShaderMask needs white text
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmcMiniCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/EMC.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.emcPoints}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithRing() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PulseTheme.avatarRingGradient,
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: PulseTheme.surface,
          border: Border.all(color: PulseTheme.surface, width: 1.5),
        ),
        child: ClipOval(
          child: widget.avatarUrl.isNotEmpty
              ? Image.network(widget.avatarUrl, fit: BoxFit.cover)
              : Center(
                  child: SvgPicture.asset(
                    'assets/icons/people.svg',
                    width: 20,
                    height: 20,
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

  // ────────────────── Premium Menu (preserved from previous) ──────────────────

  void _showPremiumMenu(BuildContext context) {
    int selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: PulseTheme.background.withOpacity(0.75),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 16, bottom: 24),
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text(
                      'mai multe',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: PulseTheme.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildVerticalNavItem(context, 0, selectedIndex, 'Punctele mele EMC', 'assets/icons/EMC.svg', setState),
                    const SizedBox(height: 8),
                    _buildVerticalNavItem(context, 1, selectedIndex, 'Cursurile mele', 'assets/icons/graduation.svg', setState),
                    const SizedBox(height: 8),
                    _buildVerticalNavItem(context, 2, selectedIndex, 'Revistele mele', 'assets/icons/books.svg', setState),
                    const SizedBox(height: 8),
                    _buildVerticalNavItem(context, 3, selectedIndex, 'Biletele mele', 'assets/icons/events.svg', setState),
                    const SizedBox(height: 8),
                    _buildVerticalNavItem(context, 4, selectedIndex, 'Favorite', 'assets/icons/heart.svg', setState),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PulseTheme.primary.withOpacity(0.1),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Închide',
                          style: TextStyle(
                            color: PulseTheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVerticalNavItem(BuildContext context, int index, int selectedIndex, String title, String iconPath, StateSetter setState) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context);
          Navigator.push(
            context,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24 : 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.black.withOpacity(0.04) : Colors.transparent,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    isSelected ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.8),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.8),
                  fontFamily: 'Avenir',
                ),
                child: Text(title),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isSelected ? 1.0 : 0.0,
              child: SvgPicture.asset(
                'assets/icons/arrow.right.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  PulseTheme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
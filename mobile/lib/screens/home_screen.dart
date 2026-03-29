import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import '../widgets/home_header.dart';
import '../widgets/featured_card.dart';
import '../widgets/content_section.dart';
import '../widgets/content_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with personalized greeting
              const HomeHeader(
                doctorName: 'Andrei', // Placeholder name
                avatarUrl: '', // Testing empty state avatar
              ),
              
              const SizedBox(height: 16),
              
              // 2. Hero Section / Featured Area
              const FeaturedCard(),
              
              const SizedBox(height: 32),
              
              // 3. Magazines Section (Reviste) - Showing Empty State Placeholder
              ContentSection(
                title: 'Reviste',
                emptyMessage: 'Nu există reviste disponibile momentan',
                emptyIconAsset: 'assets/icons/books.svg',
                categoryColor: PulseTheme.magazineContent,
                onActionTap: () {},
                children: const [], // Empty list triggers the elegant empty state
              ),
              
              const SizedBox(height: 16),
              
              // 4. Courses Section (Cursuri) - Showing Mock Cards
              ContentSection(
                title: 'Cursuri',
                emptyMessage: 'Cursurile vor apărea aici',
                emptyIconAsset: 'assets/icons/graduation.svg',
                categoryColor: PulseTheme.courseContent,
                onActionTap: () {},
                children: const [
                  ContentCard(
                    title: 'Comunicarea medic-pacient',
                    subtitle: '12 credite EMC',
                    tag: 'Curs Online',
                    categoryColor: PulseTheme.courseContent,
                    iconAsset: 'assets/icons/graduation.svg',
                  ),
                  ContentCard(
                    title: 'Antiobioterapia în 2026',
                    subtitle: '8 credite EMC',
                    tag: 'Webinar',
                    categoryColor: PulseTheme.courseContent,
                    iconAsset: 'assets/icons/graduation.svg',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 5. Events Section (Evenimente) - Showing Empty State Placeholder
              ContentSection(
                title: 'Evenimente',
                emptyMessage: 'Evenimentele viitoare vor fi afișate aici',
                emptyIconAsset: 'assets/icons/events.svg',
                categoryColor: PulseTheme.eventContent,
                onActionTap: () {},
                children: const [],
              ),
              
              const SizedBox(height: 16),
              
              // 6. News Section (Știri) - Showing Mock Cards
              ContentSection(
                title: 'Știri Medicale',
                emptyMessage: 'Știrile medicale vor apărea aici',
                emptyIconAsset: 'assets/icons/newspaper.svg',
                categoryColor: PulseTheme.newsContent,
                onActionTap: () {},
                children: const [
                  ContentCard(
                    title: 'Ministerul Sănătății lansează noul sistem informatic',
                    subtitle: 'Acum 2 ore',
                    tag: 'Sistem',
                    categoryColor: PulseTheme.newsContent,
                    iconAsset: 'assets/icons/newspaper.svg',
                  ),
                  ContentCard(
                    title: 'Noi medicamente compensate aprobate ieri',
                    subtitle: 'Acum 5 ore',
                    tag: 'Farma',
                    categoryColor: PulseTheme.newsContent,
                    iconAsset: 'assets/icons/newspaper.svg',
                  ),
                ],
              ),
              
              const SizedBox(height: 72), // Extra padding for floating bar
            ],
          ),
        ),
      );
  }

  Widget _buildPlaceholder(String title) {
    return SafeArea(
      child: Center(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;
    switch (_selectedIndex) {
      case 0:
        activeBody = _buildHomeContent();
        break;
      case 1:
        activeBody = _buildPlaceholder('Cursuri');
        break;
      case 2:
        activeBody = _buildPlaceholder('Reviste');
        break;
      case 3:
        activeBody = _buildPlaceholder('Evenimente');
        break;
      case 4:
        activeBody = _buildPlaceholder('Știri');
        break;
      default:
        activeBody = _buildHomeContent();
    }

    return Scaffold(
      backgroundColor: PulseTheme.background,
      extendBody: true, // Allows scrolling behind the bottom nav
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, 'assets/icons/house.svg', null, 'Acasă'),
              _buildNavItem(1, 'assets/icons/graduation.svg', null, 'Cursuri'),
              _buildNavItem(2, 'assets/icons/books.svg', null, 'Reviste'),
              _buildNavItem(3, 'assets/icons/events.svg', null, 'Evenimente'),
              _buildNavItem(4, 'assets/icons/newspaper.svg', null, 'Știri'),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: activeBody,
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String? iconPath, IconData? iconData, String label) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent, // Animate gracefully to transparent
          borderRadius: BorderRadius.circular(30), // Keep the pill shape intact during animation
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.black.withOpacity(0.04) : Colors.transparent,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.8),
                  BlendMode.srcIn,
                ),
              )
            else if (iconData != null)
              Icon(
                iconData,
                size: 24,
                color: isSelected ? PulseTheme.textPrimary : PulseTheme.textSecondary.withOpacity(0.8),
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
                          color: PulseTheme.textPrimary, // Dark, refined text
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.2,
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

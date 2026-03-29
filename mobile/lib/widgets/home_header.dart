import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

class HomeHeader extends StatelessWidget {
  final String doctorName;
  final String avatarUrl;

  const HomeHeader({
    super.key,
    required this.doctorName,
    this.avatarUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    behavior: HitTestBehavior.opaque, // Permite click pe zonele transparente din Padding/Container
                    child: Container(
                      width: 50, // O zonă de 50 de pixeli este uriașă și super ușor de apăsat cu degetul
                      height: 50,
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/icons/ellipsis.svg',
                        height: 5,
                        width: 5,
                        colorFilter: const ColorFilter.mode(
                          PulseTheme.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/in-app-logo.png',
                    height: 52, // Ajustat ușor să balanseze vizual butonul de meniu
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/bell.svg',
                    height: 28,
                    width: 28,
                    colorFilter: const ColorFilter.mode(
                      PulseTheme.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SvgPicture.asset(
                    'assets/icons/people.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      PulseTheme.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Salut, Dr. $doctorName',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Explorează noutățile medicale de azi',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showPremiumMenu(BuildContext context) {
    int selectedIndex = 0; // Meniul pornește cu prima opțiune activă

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Redus pentru un blur mai blând
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: PulseTheme.background.withOpacity(0.75), // Am redus și opacitatea ca să se vadă mai bine efectul de sticlă
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
                    // Lista verticală care emulează perfect comportamentul barei de navigație de jos
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
        // Așteptăm să se termine animația de "Pilulă albă" apoi navigăm!
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context); // Închide meniul de sticlă
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
          color: isSelected ? Colors.white : Colors.transparent, // Aceeași pilulă albă ca și jos
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
            // Container fix (SizedBox) apără iconițele să nu strice alinierea laterală a textului din dreapta lor.
            SizedBox(
              width: 30, // Forțăm lățime fixă de box pentru toate SVg-urile, indiferent cât de late sunt
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
              child: const Icon(
                Icons.chevron_right_rounded,
                color: PulseTheme.textPrimary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
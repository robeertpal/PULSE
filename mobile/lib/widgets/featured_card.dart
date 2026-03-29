import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

class FeaturedItemModel {
  final String tag;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color colorPrimary;
  final Color colorLight;
  final String emcPoints;

  FeaturedItemModel({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.colorPrimary,
    required this.colorLight,
    required this.emcPoints,
  });
}

class FeaturedCard extends StatefulWidget {
  const FeaturedCard({super.key});

  @override
  State<FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<FeaturedCard> {
  late PageController _pageController;

  final List<FeaturedItemModel> _items = [
    FeaturedItemModel(
      tag: 'NOU',
      title: 'Ghiduri Europene de Cardiologie 2026',
      subtitle: 'Rezumatul complet al noilor recomandări privind tratamentul pacienților cu insuficiență cardiacă.',
      buttonText: 'Citește rezumatul AI',
      colorPrimary: PulseTheme.primary,
      colorLight: PulseTheme.primaryLight,
      emcPoints: '+10',
    ),
    FeaturedItemModel(
      tag: 'CURS',
      title: 'Urgente Majore în Pediatrie',
      subtitle: 'Curs EMC interactiv - câștigă 12 puncte prin parcurgerea modulelor video.',
      buttonText: 'Începe cursul',
      colorPrimary: PulseTheme.courseContent,
      colorLight: PulseTheme.courseContent.withOpacity(0.7),
      emcPoints: '+12',
    ),
    FeaturedItemModel(
      tag: 'EVENIMENT',
      title: 'Congresul Național de Medicină',
      subtitle: 'Rezervă-ți locul acum pentru cel mai important eveniment medical al anului, desfășurat offline și online.',
      buttonText: 'Vezi detalii',
      colorPrimary: PulseTheme.eventContent,
      colorLight: PulseTheme.eventContent.withOpacity(0.7),
      emcPoints: '+30',
    ),
    FeaturedItemModel(
      tag: 'REVISTĂ',
      title: 'Medicina Modernă - Ediția Martie',
      subtitle: 'Articole de top, interviuri exclusive, studii clinice noi și inovații tehnologice în sănătate.',
      buttonText: 'Răsfoiește',
      colorPrimary: PulseTheme.magazineContent,
      colorLight: PulseTheme.magazineContent.withOpacity(0.7),
      emcPoints: '+5',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.88 permite afișarea cardului central și un mic colț ("peek") din stânga/dreapta
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250, // Fix height for consistent carousel
      child: PageView.builder(
        clipBehavior: Clip.none, // Permite extinderea umbrelor în afara delimitării cardului
        controller: _pageController,
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildCardItem(item),
          );
        },
      ),
    );
  }

  Widget _buildCardItem(FeaturedItemModel item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.colorPrimary,
            item.colorLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: item.colorPrimary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Simple geometric decoration logic to make it look premium
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: _buildBadge(item.emcPoints),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      item.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: item.colorPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      item.buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Widget _buildBadge(String points) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Fundal alb pur, elegant
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/EMC.svg', // Iconița folosită direct, exact cu forma și culorile ei!
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                points,
                style: const TextStyle(
                  color: PulseTheme.textPrimary, // Negru curat, lizibil
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Puncte EMC',
                style: TextStyle(
                  color: PulseTheme.textSecondary, // Gri discret
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

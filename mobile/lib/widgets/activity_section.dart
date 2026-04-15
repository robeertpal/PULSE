import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';

class MockActivityItem {
  final String title;
  final String date;
  final int points;
  final String type;

  MockActivityItem({
    required this.title,
    required this.date,
    required this.points,
    required this.type,
  });
}

class ActivitySection extends StatelessWidget {
  ActivitySection({super.key});

  final List<MockActivityItem> _mockActivities = [
    MockActivityItem(
      title: 'Ecografie Abdominală Avansată',
      date: 'Azi, 14:30',
      points: 15,
      type: 'Curs Finalizat',
    ),
    MockActivityItem(
      title: 'Congresul Național de Cardiologie',
      date: 'Ieri, 09:00',
      points: 20,
      type: 'Eveniment',
    ),
    MockActivityItem(
      title: 'Comunicarea cu pacientul dificil',
      date: '2 Martie 2026',
      points: 5,
      type: 'Articol parcurs',
    ),
    MockActivityItem(
      title: 'Ghid de bune practici în chirurgie',
      date: '28 Februarie 2026',
      points: 10,
      type: 'Revistă citită',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: PulseTheme.border.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Istoric Activitate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PulseTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Punctele tale EMC obținute recent.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: PulseTheme.textSecondary,
                      letterSpacing: -0.1,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              Text(
                'Vezi tot',
                style: TextStyle(
                  color: PulseTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 16),
        
        // Activity List
        Column(
          children: _mockActivities.map((activity) => _buildActivityCard(activity)).toList(),
        ),
      ],
    ),
   );
  }

  Widget _buildActivityCard(MockActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PulseTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseTheme.border.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PulseTheme.border.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                _getIconForType(activity.type),
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  PulseTheme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: PulseTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PulseTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity.date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: PulseTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Points Badge
          Container(
            width: 74,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1), // Green light
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '+',
                  style: TextStyle(
                    color: Color(0xFF059669), // Darker green
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 2),
                SvgPicture.asset(
                  'assets/icons/EMC.svg',
                  width: 12,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF059669),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${activity.points}',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIconForType(String type) {
    if (type.toLowerCase().contains('curs')) {
      return 'assets/icons/graduation.svg';
    } else if (type.toLowerCase().contains('eveniment')) {
      return 'assets/icons/events.svg';
    } else if (type.toLowerCase().contains('revist')) {
      return 'assets/icons/books.svg';
    }
    return 'assets/icons/newspaper.svg';
  }
}


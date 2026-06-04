import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'profile_screen.dart';

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _orange = Color(0xFFF97316);

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Dată necunoscută';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Ian',
        'Feb',
        'Mar',
        'Apr',
        'Mai',
        'Iun',
        'Iul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = ticket['event_title'] as String? ?? 'Eveniment PULSE';
    final dateStr = ticket['start_date'] as String?;
    final ticketCode = ticket['ticket_code'] as String?;

    final venueName = ticket['venue_name'] as String?;
    final cityName = ticket['city_name'] as String?;

    String location = '';
    if (venueName != null && venueName.isNotEmpty) {
      location = venueName;
      if (cityName != null && cityName.isNotEmpty) {
        location += ', $cityName';
      }
    } else if (cityName != null && cityName.isNotEmpty) {
      location = cityName;
    } else {
      location = 'Online / Fără locație';
    }

    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  ProfileBackButton(onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 16),
                  Expanded(child: ProfileGradientHeading('Detalii bilet')),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/events.svg',
                                  width: 34,
                                  height: 34,
                                  colorFilter: const ColorFilter.mode(
                                    _orange,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'assets/icons/calendar.svg',
                                  'Dată și oră',
                                  _formatDate(dateStr),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow(
                                  'assets/icons/location.svg',
                                  'Locație',
                                  location,
                                ),
                              ],
                            ),
                          ),

                          if (ticketCode != null) ...[
                            Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: QrImageView(
                                      data: ticketCode,
                                      version: QrVersions.auto,
                                      size: 200,
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Cod bilet',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      textBaseline: TextBaseline.alphabetic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ticketCode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String iconAsset, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.38),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

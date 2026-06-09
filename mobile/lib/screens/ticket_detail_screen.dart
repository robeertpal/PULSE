import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'content_detail_screen.dart';
import 'profile_screen.dart';

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  static const Color _black = Color(0xFFFFFBFE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceSoft = Color(0xFFF7F2F8);
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

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _readText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  void _openContentDetail(BuildContext context, int contentItemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentItemId: contentItemId),
      ),
    );
  }

  Widget _buildProfileStyleButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        height: 50,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF4FA3), Color(0xFFFF8A2A)],
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(17),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(17),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white54,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection({
    required String title,
    required String? description,
    required String? imageUrl,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _surfaceSoft,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/events.svg',
                      width: 42,
                      height: 42,
                      colorFilter: const ColorFilter.mode(
                        _orange,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                if (imageUrl == null) ...[
                  SvgPicture.asset(
                    'assets/icons/events.svg',
                    width: 36,
                    height: 36,
                    colorFilter: const ColorFilter.mode(
                      _orange,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = ticket['event_title'] as String? ?? 'Eveniment PULSE';
    final description = _readText(ticket['short_description']);
    final imageUrl =
        _readText(ticket['hero_image_url']) ??
        _readText(ticket['thumbnail_url']);
    final dateStr = ticket['start_date'] as String?;
    final ticketCode = ticket['ticket_code'] as String?;
    final contentItemId = _readInt(ticket['content_item_id']);

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
                    _buildHeroSection(
                      title: title,
                      description: description,
                      imageUrl: imageUrl,
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 18),
                    _buildProfileStyleButton(
                      label: 'Vezi detalii',
                      onPressed: contentItemId == null
                          ? null
                          : () => _openContentDetail(context, contentItemId),
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

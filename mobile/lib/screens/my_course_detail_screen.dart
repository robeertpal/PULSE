import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/pulse_theme.dart';
import 'content_detail_screen.dart';
import 'profile_screen.dart';

class MyCourseDetailScreen extends StatelessWidget {
  const MyCourseDetailScreen({super.key, required this.course});

  final Map<String, dynamic> course;

  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _surfaceSoft = Color(0xFF181818);
  static const Color _courseColor = PulseTheme.courseContent;
  static const String _courseIcon = 'assets/icons/graduation.svg';
  static const String _calendarIcon = 'assets/icons/calendar.svg';
  static const String _buildingIcon = 'assets/icons/building.svg';
  static const String _emcIcon = 'assets/icons/EMC.svg';

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

  DateTime? _parseCourseDate(Object? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDate(Object? value) {
    final dt = _parseCourseDate(value);
    if (dt == null) return 'Dată indisponibilă';
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
    final day = dt.day.toString().padLeft(2, '0');
    return '$day ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatPeriod(Object? startDate, Object? endDate) {
    final hasStart = _parseCourseDate(startDate) != null;
    final hasEnd = _parseCourseDate(endDate) != null;
    if (hasStart && hasEnd) {
      return 'de la ${_formatDate(startDate)} până la ${_formatDate(endDate)}';
    }
    if (hasStart) return 'de la ${_formatDate(startDate)}';
    if (hasEnd) return 'până la ${_formatDate(endDate)}';
    return 'Perioadă indisponibilă';
  }

  int _calculatePeriodProgress(Object? startDate, Object? endDate) {
    final start = _parseCourseDate(startDate);
    final end = _parseCourseDate(endDate);
    if (start == null || end == null) {
      final raw = course['progress_percent'];
      if (raw is num) return raw.toInt().clamp(0, 100).toInt();
      return (int.tryParse(raw?.toString() ?? '') ?? 0).clamp(0, 100).toInt();
    }

    final now = DateTime.now();
    if (!now.isAfter(start)) return 0;
    if (!now.isBefore(end)) return 100;

    final total = end.difference(start).inSeconds;
    if (total <= 0) return 100;

    final elapsed = now.difference(start).inSeconds;
    final progress = (elapsed / total) * 100;
    return progress.clamp(0, 100).round();
  }

  String _statusLabel(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'enrolled':
        return 'Înscris';
      case 'completed':
        return 'Finalizat';
      case 'in_progress':
        return 'În desfășurare';
      case 'cancelled':
        return 'Anulat';
      case 'published':
        return 'Publicat';
      case 'closed':
        return 'Închis';
      case 'archived':
        return 'Arhivat';
      default:
        return _readText(value) ?? 'Status indisponibil';
    }
  }

  void _openPublicCourse(BuildContext context, int contentItemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentItemId: contentItemId),
      ),
    );
  }

  Widget _assetIcon(String asset, {double size = 18, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
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
          gradient: enabled ? PulseTheme.primaryGradient : null,
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

  Widget _buildProgress(int progress) {
    final clamped = progress.clamp(0, 100);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres curs',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$clamped%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_courseColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String iconAsset, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _assetIcon(
            iconAsset,
            size: 18,
            color: Colors.white.withValues(alpha: 0.42),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard({
    required Object? validFrom,
    required Object? validUntil,
    required String? provider,
    required Object? emcCredits,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildInfoRow(
              _calendarIcon,
              'Perioada cursului',
              _formatPeriod(validFrom, validUntil),
            ),
            Divider(height: 32, color: Colors.white.withValues(alpha: 0.06)),
            _buildInfoRow(
              _buildingIcon,
              'Provider',
              provider ?? 'Provider indisponibil',
            ),
            Divider(height: 32, color: Colors.white.withValues(alpha: 0.06)),
            _buildInfoRow(
              _emcIcon,
              'Puncte EMC',
              emcCredits == null
                  ? 'Puncte EMC indisponibile'
                  : '$emcCredits credite EMC',
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
        _assetIcon(
          iconAsset,
          size: 20,
          color: Colors.white.withValues(alpha: 0.38),
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

  @override
  Widget build(BuildContext context) {
    final title = _readText(course['course_title']) ?? 'Curs PULSE';
    final description = _readText(course['short_description']);
    final provider = _readText(course['provider']);
    final emcCredits = course['emc_credits'];
    final validFrom = course['valid_from'];
    final validUntil = course['valid_until'];
    final status = _statusLabel(course['status']);
    final contentItemId = _readInt(course['content_item_id']);
    final imageUrl =
        _readText(course['hero_image_url']) ??
        _readText(course['thumbnail_url']);
    final progress = _calculatePeriodProgress(validFrom, validUntil);

    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        leadingWidth: 72,
        titleSpacing: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: ProfileBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const ProfileGradientHeading('Detalii curs'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                            child: _assetIcon(
                              _courseIcon,
                              size: 42,
                              color: _courseColor,
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
                          _assetIcon(
                            _courseIcon,
                            size: 36,
                            color: _courseColor,
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
            ),
            const SizedBox(height: 18),
            _buildProgress(progress),
            const SizedBox(height: 18),
            _buildCourseInfoCard(
              validFrom: validFrom,
              validUntil: validUntil,
              provider: provider,
              emcCredits: emcCredits,
            ),
            const SizedBox(height: 10),
            _buildDetailRow(_courseIcon, 'Status', status),
            const SizedBox(height: 18),
            _buildProfileStyleButton(
              label: 'Vezi detalii',
              onPressed: contentItemId == null
                  ? null
                  : () => _openPublicCourse(context, contentItemId),
            ),
          ],
        ),
      ),
    );
  }
}

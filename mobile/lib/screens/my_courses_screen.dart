import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/skeleton_loading.dart';
import 'my_course_detail_screen.dart';
import 'profile_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _courseColor = PulseTheme.courseContent;
  static const String _courseIcon = 'assets/icons/graduation.svg';
  static const String _calendarIcon = 'assets/icons/calendar.svg';
  static const String _emcIcon = 'assets/icons/EMC.svg';

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getMyCourses();
      if (!mounted) return;
      setState(() {
        _courses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDate(Object? isoDate) {
    if (isoDate == null) return 'Dată indisponibilă';
    try {
      final dt = DateTime.parse(isoDate.toString()).toLocal();
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
    } catch (_) {
      return isoDate.toString();
    }
  }

  void _openCourse(Map<String, dynamic> course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyCourseDetailScreen(course: course),
      ),
    );
  }

  DateTime? _parseCourseDate(Object? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  Widget _assetIcon(String asset, {double size = 16, Color? color}) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  String _formatPeriod(Object? startDate, Object? endDate) {
    final start = _parseCourseDate(startDate);
    final end = _parseCourseDate(endDate);
    if (start != null && end != null) {
      return 'de la ${_formatDate(startDate)} până la ${_formatDate(endDate)}';
    }
    if (start != null) return 'de la ${_formatDate(startDate)}';
    if (end != null) return 'până la ${_formatDate(endDate)}';
    return 'Perioadă indisponibilă';
  }

  String _statusLabel(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'enrolled':
        return 'Curs înscris';
      case 'completed':
        return 'Curs finalizat';
      case 'in_progress':
        return 'Curs în desfășurare';
      default:
        return 'Curs PULSE';
    }
  }

  int _calculatePeriodProgress(Map<String, dynamic> course) {
    final start = _parseCourseDate(course['valid_from']);
    final end = _parseCourseDate(course['valid_until']);
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

  Widget _buildMetaRow(String iconAsset, String text) {
    return Row(
      children: [
        _assetIcon(
          iconAsset,
          size: 14,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int progress) {
    final clamped = progress.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progres',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$clamped%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(_courseColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final title = course['course_title'] as String? ?? 'Curs PULSE';
    final status = _statusLabel(course['status']);
    final emcCredits = course['emc_credits'];
    final period = _formatPeriod(course['valid_from'], course['valid_until']);
    final progress = _calculatePeriodProgress(course);

    return GestureDetector(
      onTap: () => _openCourse(course),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: _assetIcon(
                        _courseIcon,
                        size: 24,
                        color: _courseColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (emcCredits != null) ...[
                          const SizedBox(height: 6),
                          _buildMetaRow(_emcIcon, '$emcCredits credite EMC'),
                        ],
                        const SizedBox(height: 6),
                        _buildMetaRow(_calendarIcon, period),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _openCourse(course),
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: _assetIcon(
                            'assets/icons/arrow.right.svg',
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildProgressBar(progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SkeletonBlock(height: 210, radius: 20),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _assetIcon(
              _courseIcon,
              size: 48,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 16),
            const Text(
              'A apărut o eroare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loadCourses,
              style: TextButton.styleFrom(foregroundColor: _courseColor),
              child: const Text('Încearcă din nou'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _assetIcon(
              _courseIcon,
              size: 52,
              color: _courseColor.withValues(alpha: 0.86),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nu ești înscris la niciun curs încă.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cursurile la care te înscrii vor apărea aici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const ProfileGradientHeading('Cursurile mele'),
      ),
      body: _isLoading
          ? _buildSkeletons()
          : _errorMessage != null
          ? _buildErrorState()
          : _courses.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _courseColor,
              backgroundColor: _surface,
              onRefresh: _loadCourses,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(_courses[index]);
                },
              ),
            ),
    );
  }
}

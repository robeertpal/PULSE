import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/profile_ui_helpers.dart';
import '../widgets/skeleton_loading.dart';
import 'content_detail_screen.dart';

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
  static const String _buildingIcon = 'assets/icons/building.svg';
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
    final contentItemId = course['content_item_id'];
    final parsed = contentItemId is int
        ? contentItemId
        : int.tryParse(contentItemId?.toString() ?? '');
    if (parsed == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentItemId: parsed),
      ),
    );
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

  Widget _buildMetaRow(String iconAsset, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildProgress(int progress) {
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
    final description = course['short_description'] as String?;
    final provider = course['provider'] as String?;
    final emcCredits = course['emc_credits'];
    final enrolledAt = course['enrolled_at'];
    final progressRaw = course['progress_percent'];
    final progress = progressRaw is num
        ? progressRaw.toInt()
        : int.tryParse(progressRaw?.toString() ?? '') ?? 0;

    return Container(
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
                      if (description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.54),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (provider?.trim().isNotEmpty == true)
              _buildMetaRow(_buildingIcon, provider!.trim()),
            if (provider?.trim().isNotEmpty == true) const SizedBox(height: 8),
            _buildMetaRow(
              _calendarIcon,
              'Înscris din ${_formatDate(enrolledAt)}',
            ),
            if (emcCredits != null) ...[
              const SizedBox(height: 8),
              _buildMetaRow(_emcIcon, '$emcCredits credite EMC'),
            ],
            const SizedBox(height: 16),
            _buildProgress(progress),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_courseColor, Color(0xFFF97316)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _openCourse(course),
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Center(
                      child: Text(
                        'Vezi cursul',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

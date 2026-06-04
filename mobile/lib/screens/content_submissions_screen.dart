import 'package:flutter/material.dart';

import '../models/content_submission.dart';
import '../services/api_service.dart';
import '../theme/pulse_theme.dart';
import '../widgets/pulse_animated_background.dart';
import 'content_submission_form_screen.dart';

class ContentSubmissionsScreen extends StatefulWidget {
  const ContentSubmissionsScreen({super.key});

  @override
  State<ContentSubmissionsScreen> createState() =>
      _ContentSubmissionsScreenState();
}

class _ContentSubmissionsScreenState extends State<ContentSubmissionsScreen> {
  final ApiService _apiService = ApiService();
  List<ContentSubmission> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _apiService.getMyContentSubmissions();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openForm({int? submissionId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            ContentSubmissionFormScreen(submissionId: submissionId),
      ),
    );
    if (changed == true || submissionId != null) {
      await _loadSubmissions();
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'published' => const Color(0xFF22C55E),
      'approved' => const Color(0xFF38BDF8),
      'submitted' || 'under_review' => PulseTheme.primaryLight,
      'needs_changes' => const Color(0xFFF59E0B),
      'rejected' => const Color(0xFFEF4444),
      _ => PulseTheme.textSecondary,
    };
  }

  String _typeLabel(String type) {
    return switch (type) {
      'article' => 'Articol',
      'news' => 'Stire',
      'course' => 'Curs',
      'event' => 'Eveniment',
      _ => type,
    };
  }

  Widget _buildSubmissionCard(ContentSubmission item) {
    final statusColor = _statusColor(item.status);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openForm(submissionId: item.id),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: PulseTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                [
                  _typeLabel(item.contentType),
                  if (item.categoryName?.trim().isNotEmpty == true)
                    item.categoryName!,
                  if (item.specializationName?.trim().isNotEmpty == true)
                    item.specializationName!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PulseTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.summary?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  item.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
              if (item.reviewNotes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    item.reviewNotes!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PulseTheme.primaryLight),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: PulseTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _loadSubmissions,
                child: const Text('Reincearca'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: PulseTheme.primaryLight,
      onRefresh: _loadSubmissions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Text(
              'Trimite articole, stiri, cursuri sau evenimente catre echipa editoriala PULSE. Contributiile apar public doar dupa review.',
              style: TextStyle(
                color: PulseTheme.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Text(
                'Nu ai contributii trimise momentan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PulseTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildSubmissionCard(item),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(title: const Text('Contributiile mele')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: PulseTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Trimite continut'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: PulseAnimatedBackground()),
          SafeArea(child: _buildBody()),
        ],
      ),
    );
  }
}

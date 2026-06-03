import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';

const Color _medicalTeal = Color(0xFF0F766E);

class AiSummaryInlineSection extends StatelessWidget {
  final String? summary;
  final List<String> keyPoints;
  final String? disclaimer;
  final String? error;

  const AiSummaryInlineSection({
    super.key,
    required this.summary,
    required this.keyPoints,
    required this.disclaimer,
    required this.error,
  });

  bool get _hasSummary => summary?.trim().isNotEmpty == true;
  bool get _hasError => error?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    if (!_hasSummary && !_hasError) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _medicalTeal.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _medicalTeal.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 14),
            color: _medicalTeal.withValues(alpha: 0.12),
          ),
          if (_hasError) _AiSummaryErrorState(error: error),
          if (_hasSummary)
            _AiSummaryContent(
              summary: summary!.trim(),
              keyPoints: keyPoints,
              disclaimer: disclaimer,
            ),
        ],
      ),
    );
  }
}

class AiSummaryButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGenerate;

  const AiSummaryButton({
    super.key,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onGenerate,
        style: FilledButton.styleFrom(
          backgroundColor: PulseTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PulseTheme.primary.withValues(alpha: 0.62),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.auto_awesome_outlined, size: 19),
            const SizedBox(width: 9),
            Text(
              isLoading ? 'Se generează rezumatul...' : 'Generează rezumat AI',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiSummaryContent extends StatelessWidget {
  final String summary;
  final List<String> keyPoints;
  final String? disclaimer;

  const _AiSummaryContent({
    required this.summary,
    required this.keyPoints,
    required this.disclaimer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: _medicalTeal, size: 20),
            SizedBox(width: 8),
            Text(
              'Rezumat AI',
              style: TextStyle(
                color: PulseTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          summary.trim(),
          style: const TextStyle(
            color: PulseTheme.textPrimary,
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (keyPoints.isNotEmpty) ...[
          const SizedBox(height: 15),
          const Text(
            'Idei cheie',
            style: TextStyle(
              color: PulseTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          ...keyPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 9),
                    decoration: const BoxDecoration(
                      color: _medicalTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (disclaimer?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(
            disclaimer!.trim(),
            style: const TextStyle(
              color: PulseTheme.textTertiary,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _AiSummaryErrorState extends StatelessWidget {
  final String? error;

  const _AiSummaryErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PulseTheme.newsContent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PulseTheme.newsContent.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: PulseTheme.newsContent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error ?? 'Rezumatul nu a putut fi generat. Încearcă din nou.',
              style: const TextStyle(
                color: PulseTheme.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

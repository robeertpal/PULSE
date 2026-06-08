import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../theme/pulse_theme.dart';

class EmcActivityScreen extends StatefulWidget {
  const EmcActivityScreen({super.key});

  @override
  State<EmcActivityScreen> createState() => _EmcActivityScreenState();
}

class _EmcActivityScreenState extends State<EmcActivityScreen> {
  static const _backIcon = 'assets/icons/arrow.backward.svg';
  static const _emcIcon = 'assets/icons/EMC.svg';
  static const _courseIcon = 'assets/icons/graduation.svg';
  static const _eventIcon = 'assets/icons/events.svg';
  static const _publicationIcon = 'assets/icons/book.pages.svg';
  static const _manualIcon = 'assets/icons/signature.svg';

  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _pink = Color(0xFFFF4FA3);
  static const Color _orange = Color(0xFFFF8A2A);
  static const LinearGradient _accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_pink, _orange],
  );

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<_EmcActivityItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await _apiService.getMyEmcActivity();
      if (!mounted) return;
      setState(() {
        _items = rows.map(_EmcActivityItem.fromJson).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        foregroundColor: PulseTheme.textPrimary,
        toolbarHeight: 76,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: _GlassBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: const _GradientHeading('Activitatea mea'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _orange, strokeWidth: 2.6),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: _GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nu am putut încărca activitatea',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: PulseTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadActivity,
                  child: const Text('Încearcă din nou'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: _GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _SvgIcon(_emcIcon, color: _orange, size: 42),
                SizedBox(height: 14),
                Text(
                  'Nu există activitate EMC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Punctele EMC acordate vor apărea aici imediat ce există loguri în contul tău.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: PulseTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ActivityCard(item: _items[index]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final _EmcActivityItem item;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SourceIcon(sourceType: item.sourceType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.points} ${item.points == 1 ? 'punct EMC adăugat' : 'puncte EMC adăugate'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PulseTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.sourceSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.awardedAtLabel,
                  style: const TextStyle(
                    color: PulseTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: _EmcActivityScreenState._accentGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${item.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                const _SvgIcon(
                  _EmcActivityScreenState._emcIcon,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.sourceType});

  final String sourceType;

  @override
  Widget build(BuildContext context) {
    final asset = switch (sourceType.toLowerCase()) {
      'course' => _EmcActivityScreenState._courseIcon,
      'event' => _EmcActivityScreenState._eventIcon,
      'publication' => _EmcActivityScreenState._publicationIcon,
      'publication_subscription' => _EmcActivityScreenState._publicationIcon,
      'manual' => _EmcActivityScreenState._manualIcon,
      _ => _EmcActivityScreenState._emcIcon,
    };

    return SizedBox(
      width: 32,
      child: _SvgIcon(asset, color: _EmcActivityScreenState._pink, size: 24),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _EmcActivityScreenState._surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 24,
            offset: const Offset(0, 14),
            spreadRadius: -14,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Înapoi',
      child: Material(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: _SvgIcon(
                _EmcActivityScreenState._backIcon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientHeading extends StatelessWidget {
  const _GradientHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          _EmcActivityScreenState._accentGradient.createShader(bounds),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon(this.asset, {required this.color, required this.size});

  final String asset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _EmcActivityItem {
  const _EmcActivityItem({
    required this.id,
    required this.sourceType,
    required this.sourceTitle,
    required this.sourceLabel,
    required this.points,
    required this.awardedAt,
  });

  final int id;
  final String sourceType;
  final String sourceTitle;
  final String sourceLabel;
  final int points;
  final DateTime? awardedAt;

  String get sourceSubtitle {
    if (sourceTitle.trim().isEmpty || sourceTitle == 'Activitate EMC') {
      return sourceLabel;
    }
    return 'Pentru ${sourceLabel.toLowerCase()} „$sourceTitle”';
  }

  String get awardedAtLabel {
    final date = awardedAt;
    if (date == null) return 'Dată necompletată';
    const months = [
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _fallbackSourceLabel(String sourceType) {
    return switch (sourceType.toLowerCase()) {
      'course' => 'Curs',
      'event' => 'Eveniment',
      'publication' => 'Revistă',
      'publication_subscription' => 'Abonament revistă',
      'manual' => 'Activitate EMC',
      _ => 'Activitate EMC',
    };
  }

  factory _EmcActivityItem.fromJson(Map<String, dynamic> json) {
    final sourceType = (json['source_type'] ?? 'emc').toString();
    final sourceTitle = (json['source_title'] ?? '').toString().trim();
    final sourceLabel = (json['source_label'] ?? '').toString().trim();
    final awardedAtText = json['awarded_at']?.toString();
    return _EmcActivityItem(
      id: _readInt(json['id']),
      sourceType: sourceType,
      sourceTitle: sourceTitle.isEmpty ? 'Activitate EMC' : sourceTitle,
      sourceLabel: sourceLabel.isEmpty
          ? _fallbackSourceLabel(sourceType)
          : sourceLabel,
      points: _readInt(json['points']),
      awardedAt: awardedAtText == null
          ? null
          : DateTime.tryParse(awardedAtText),
    );
  }
}

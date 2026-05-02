import 'package:flutter/material.dart';
import '../models/ad_item.dart';
import '../theme/pulse_theme.dart';

class AdvertisementCard extends StatefulWidget {
  final AdItem ad;
  final VoidCallback? onTap;

  const AdvertisementCard({super.key, required this.ad, this.onTap});

  @override
  State<AdvertisementCard> createState() => _AdvertisementCardState();
}

class _AdvertisementCardState extends State<AdvertisementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.012).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_animation == 'soft_pulse') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AdvertisementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animation == 'soft_pulse' && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (_animation != 'soft_pulse' && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _config => widget.ad.mergedConfig;

  String get _templateCode => widget.ad.templateCode ?? '';

  String get _templateVariant => widget.ad.templateVariant ?? '';

  String get _animation =>
      _stringConfig('animation', fallback: 'none') ?? 'none';

  Color get _accentColor => _colorFromHex(
    _stringConfig('accent_color', fallback: '#2563EB') ?? '#2563EB',
    PulseTheme.primary,
  );

  bool get _showBadge => _boolConfig('show_badge', fallback: true);

  bool get _showSponsorLogo => _boolConfig('show_sponsor_logo', fallback: true);

  String get _badgeText {
    final configured = _stringConfig('badge_text');
    if (configured != null && configured.isNotEmpty) return configured;
    if (_templateCode == 'event_promo') return 'Eveniment';
    if (_templateCode == 'course_promo') return 'Curs EMC';
    if (_templateCode == 'publication_promo') return 'Revistă';
    if (_templateCode == 'sponsor_banner') return 'Sponsor';
    return 'Promovat';
  }

  String? get _imageUrl => widget.ad.preferredImageUrl;

  bool get _hasImage => _imageUrl != null;

  bool get _isGradient =>
      _templateCode == 'gradient_card' || _templateVariant == 'gradient';

  bool get _isHero =>
      _templateCode == 'hero_banner' ||
      _templateVariant == 'hero' ||
      _templateCode == 'event_promo' ||
      _templateVariant == 'event_promo';

  bool get _isSponsor => _templateCode == 'sponsor_banner';

  bool get _isCompact =>
      !_isHero && !_isGradient ||
      _templateCode == 'compact_card' ||
      _templateVariant == 'compact';

  String? _stringConfig(String key, {String? fallback}) {
    final value = _config[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolConfig(String key, {required bool fallback}) {
    final value = _config[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation == 'soft_pulse' ? _pulseAnimation.value : 1,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _buildCard(),
          ),
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      label: 'Reclamă promovată: ${widget.ad.title}',
      child: card,
    );
  }

  Widget _buildCard() {
    if (_isGradient) return _tapWrapper(_buildGradientCard());
    if (_isHero) return _tapWrapper(_buildHeroCard());
    if (_isSponsor) return _tapWrapper(_buildSponsorCard());
    if (_isCompact) return _tapWrapper(_buildCompactCard());
    return _tapWrapper(_buildCompactCard());
  }

  Widget _tapWrapper(Widget child) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: child,
      ),
    );
  }

  double get _cornerRadius {
    final value = _config['corner_radius'];
    if (value is num) return value.toDouble().clamp(16.0, 28.0);
    return 22;
  }

  Widget _buildHeroCard() {
    return Container(
      height: 210,
      decoration: _outerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageBackground(),
            if (_stringConfig('image_overlay', fallback: 'dark_gradient') !=
                'none')
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.34),
                      Colors.black.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: _buildTextBlock(onDark: _hasImage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      decoration: _outerDecoration(),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            height: 108,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _hasImage ? _networkImage(_imageUrl!) : _fallbackVisual(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: _buildTextBlock()),
        ],
      ),
    );
  }

  Widget _buildSponsorCard() {
    return Container(
      decoration: _outerDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildTextBlock()),
          const SizedBox(width: 14),
          SizedBox(
            width: 96,
            height: 96,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _hasImage ? _networkImage(_imageUrl!) : _fallbackVisual(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cornerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accentColor, Color.lerp(_accentColor, Colors.black, 0.28)!],
        ),
        boxShadow: PulseTheme.coloredShadow(_accentColor),
      ),
      padding: const EdgeInsets.all(20),
      child: _buildTextBlock(onDark: true),
    );
  }

  Widget _buildTextBlock({bool onDark = false}) {
    final titleColor = onDark ? Colors.white : PulseTheme.textPrimary;
    final bodyColor = onDark
        ? Colors.white.withValues(alpha: 0.84)
        : PulseTheme.textSecondary;
    final description = widget.ad.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showBadge) _Badge(label: _badgeText, color: _accentColor),
            if (_showBadge) const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.ad.sponsorName ?? 'Promovat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_showSponsorLogo && widget.ad.sponsorLogoUrl != null) ...[
              const SizedBox(width: 8),
              _SponsorLogo(url: widget.ad.sponsorLogoUrl!),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          widget.ad.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: _isHero || _isGradient ? 22 : 17,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            description,
            maxLines: _isHero ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: bodyColor, fontSize: 13.5, height: 1.35),
          ),
        ],
        if (widget.ad.ctaLabel?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _Cta(label: widget.ad.ctaLabel!, color: _accentColor, onDark: onDark),
        ],
      ],
    );
  }

  BoxDecoration _outerDecoration() {
    return BoxDecoration(
      color: PulseTheme.surface,
      borderRadius: BorderRadius.circular(_cornerRadius),
      border: Border.all(color: PulseTheme.borderLight),
      boxShadow: PulseTheme.cardShadow,
    );
  }

  Widget _buildImageBackground() {
    if (_hasImage) return _networkImage(_imageUrl!);
    return _fallbackVisual();
  }

  Widget _networkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackVisual(),
    );
  }

  Widget _fallbackVisual() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accentColor.withValues(alpha: 0.16), PulseTheme.surface],
        ),
      ),
      child: Center(
        child: Icon(Icons.campaign_rounded, color: _accentColor, size: 34),
      ),
    );
  }

  Color _colorFromHex(String value, Color fallback) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) return fallback;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(0xFF000000 | parsed);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  final String label;
  final Color color;
  final bool onDark;

  const _Cta({required this.label, required this.color, required this.onDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.16) : color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.22) : color,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SponsorLogo extends StatelessWidget {
  final String url;

  const _SponsorLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

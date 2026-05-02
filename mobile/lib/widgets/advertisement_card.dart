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
  static const double _maxCardWidth = 760;

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

  bool get _showBadge {
    final designValue = _boolFromMap(widget.ad.designConfig, 'show_badge');
    if (designValue != null) return designValue;
    return _boolFromMap(widget.ad.templateDefaultConfig, 'show_badge') ?? false;
  }

  bool get _showSponsorLogo => _boolConfig('show_sponsor_logo', fallback: true);

  String? get _badgeText =>
      _stringFromMap(widget.ad.designConfig, 'badge_text') ??
      _stringFromMap(widget.ad.templateDefaultConfig, 'badge_text');

  bool get _shouldShowBadge => _showBadge && _badgeText != null;

  String get _textPosition =>
      _stringConfig('text_position', fallback: 'bottom_left') ?? 'bottom_left';

  String? get _sponsorName {
    final text = widget.ad.sponsorName?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? get _imageUrl => widget.ad.preferredImageUrl;

  bool get _hasImage => _imageUrl != null;

  bool get _isGradient =>
      _templateCode == 'gradient_card' || _templateVariant == 'gradient';

  bool get _isMegaHero =>
      _templateCode == 'mega_hero_banner' || _templateVariant == 'mega_hero';

  bool get _isHero =>
      _templateCode == 'hero_banner' ||
      _templateVariant == 'hero' ||
      _templateCode == 'event_promo' ||
      _templateVariant == 'event_promo';

  bool get _isSponsor => _templateCode == 'sponsor_banner';

  bool get _isCompact =>
      !_isMegaHero && !_isHero && !_isGradient ||
      _templateCode == 'compact_card' ||
      _templateVariant == 'compact';

  bool get _isCoursePromo => _templateCode == 'course_promo';

  bool get _isPublicationPromo => _templateCode == 'publication_promo';

  Alignment get _textBlockAlignment {
    return switch (_textPosition) {
      'top_center' => Alignment.topCenter,
      'top_right' => Alignment.topRight,
      'center_left' => Alignment.centerLeft,
      'center' => Alignment.center,
      'center_right' => Alignment.centerRight,
      'bottom_center' => Alignment.bottomCenter,
      'bottom_right' => Alignment.bottomRight,
      'top_left' => Alignment.topLeft,
      _ => Alignment.bottomLeft,
    };
  }

  CrossAxisAlignment get _textCrossAxisAlignment {
    if (_textPosition.endsWith('_center') || _textPosition == 'center') {
      return CrossAxisAlignment.center;
    }
    if (_textPosition.endsWith('_right')) return CrossAxisAlignment.end;
    return CrossAxisAlignment.start;
  }

  MainAxisAlignment get _metaMainAxisAlignment {
    if (_textPosition.endsWith('_center') || _textPosition == 'center') {
      return MainAxisAlignment.center;
    }
    if (_textPosition.endsWith('_right')) return MainAxisAlignment.end;
    return MainAxisAlignment.start;
  }

  TextAlign get _textAlign {
    if (_textPosition.endsWith('_center') || _textPosition == 'center') {
      return TextAlign.center;
    }
    if (_textPosition.endsWith('_right')) return TextAlign.right;
    return TextAlign.left;
  }

  String? _stringConfig(String key, {String? fallback}) {
    final value = _config[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolConfig(String key, {required bool fallback}) {
    final value = _config[key];
    return _boolFromValue(value) ?? fallback;
  }

  bool? _boolFromMap(Map<String, dynamic> config, String key) {
    if (!config.containsKey(key)) return null;
    return _boolFromValue(config[key]);
  }

  bool? _boolFromValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  String? _stringFromMap(Map<String, dynamic> config, String key) {
    if (!config.containsKey(key)) return null;
    final value = config[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxCardWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 520;
                return _buildCard(isWide: isWide);
              },
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      label: 'Reclamă: ${widget.ad.title}',
      child: card,
    );
  }

  Widget _buildCard({required bool isWide}) {
    if (_isMegaHero) return _tapWrapper(_buildMegaHeroCard(isWide: isWide));
    if (_isGradient) return _tapWrapper(_buildGradientCard(isWide: isWide));
    if (_isHero) return _tapWrapper(_buildHeroCard(isWide: isWide));
    if (_isSponsor) return _tapWrapper(_buildSponsorCard(isWide: isWide));
    if (_isCompact) return _tapWrapper(_buildCompactCard(isWide: isWide));
    return _tapWrapper(_buildCompactCard(isWide: isWide));
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

  Widget _buildMegaHeroCard({required bool isWide}) {
    return Container(
      height: _megaHeroHeight(isWide: isWide),
      decoration: _outerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageBackground(),
            ?_buildImageOverlay(),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 30 : 22,
                  isWide ? 30 : 24,
                  isWide ? 30 : 22,
                  isWide ? 30 : 24,
                ),
                child: Align(
                  alignment: _textBlockAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _textBlockMaxWidth(isWide: isWide),
                    ),
                    child: _buildTextBlock(
                      onDark: _hasImage,
                      titleFontSize: isWide ? 28 : 24,
                      descriptionMaxLines: 3,
                      titleMaxLines: 3,
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

  Widget _buildHeroCard({required bool isWide}) {
    return Container(
      height: isWide ? 204 : 188,
      decoration: _outerDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageBackground(),
            ?_buildImageOverlay(),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 22 : 18,
                  isWide ? 20 : 18,
                  isWide ? 22 : 18,
                  isWide ? 20 : 18,
                ),
                child: Align(
                  alignment: _textBlockAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _textBlockMaxWidth(isWide: isWide),
                    ),
                    child: _buildTextBlock(
                      onDark: _hasImage,
                      titleFontSize: isWide ? 21.5 : 20,
                      descriptionMaxLines: 2,
                      titleMaxLines: 2,
                      ctaDense: true,
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

  Widget _buildCompactCard({required bool isWide}) {
    final mediaSize = isWide ? 96.0 : 88.0;

    return Container(
      decoration: _outerDecoration(),
      padding: EdgeInsets.all(isWide ? 14 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: mediaSize,
            height: mediaSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _hasImage ? _networkImage(_imageUrl!) : _fallbackVisual(),
            ),
          ),
          SizedBox(width: isWide ? 14 : 12),
          Expanded(
            child: Align(
              alignment: _textBlockAlignment,
              child: _buildTextBlock(
                titleFontSize: 16.5,
                descriptionMaxLines: _compactDescriptionLines,
                titleMaxLines: 2,
                ctaDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard({required bool isWide}) {
    final mediaSize = isWide ? 84.0 : 76.0;

    return Container(
      decoration: _outerDecoration(),
      padding: EdgeInsets.all(isWide ? 16 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: _textBlockAlignment,
              child: _buildTextBlock(
                titleFontSize: 16.5,
                descriptionMaxLines: 2,
                titleMaxLines: 2,
                ctaDense: true,
              ),
            ),
          ),
          SizedBox(width: isWide ? 14 : 12),
          SizedBox(
            width: mediaSize,
            height: mediaSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _hasImage ? _networkImage(_imageUrl!) : _fallbackVisual(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard({required bool isWide}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cornerRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_accentColor, Colors.white, 0.08)!,
            _accentColor,
            Color.lerp(_accentColor, Colors.black, 0.34)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
        boxShadow: [
          ...PulseTheme.coloredShadow(_accentColor),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cornerRadius),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -22,
              child: _GradientMark(color: Colors.white.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: EdgeInsets.all(isWide ? 20 : 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: isWide ? 128 : 116),
                child: Align(
                  alignment: _textBlockAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _textBlockMaxWidth(isWide: isWide),
                    ),
                    child: _buildTextBlock(
                      onDark: true,
                      titleFontSize: isWide ? 21 : 19.5,
                      descriptionMaxLines: 2,
                      titleMaxLines: 2,
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

  int get _compactDescriptionLines {
    if (_isCoursePromo || _isPublicationPromo) return 2;
    return 2;
  }

  double _megaHeroHeight({required bool isWide}) {
    final height = _stringConfig('height', fallback: 'large') ?? 'large';
    return switch (height.toLowerCase()) {
      'small' || 'medium' => isWide ? 360 : 300,
      'xl' || 'extra_large' => isWide ? 420 : 340,
      _ => isWide ? 388 : 320,
    };
  }

  double _textBlockMaxWidth({required bool isWide}) {
    if (_isMegaHero) {
      if (_textPosition.endsWith('_center') || _textPosition == 'center') {
        return isWide ? 620 : 430;
      }
      return isWide ? 560 : 380;
    }
    if (_textPosition.endsWith('_center') || _textPosition == 'center') {
      return isWide ? 560 : 420;
    }
    return isWide ? 500 : 360;
  }

  Widget _buildTextBlock({
    bool onDark = false,
    double? titleFontSize,
    int titleMaxLines = 2,
    int descriptionMaxLines = 2,
    bool ctaDense = false,
  }) {
    final titleColor = onDark ? Colors.white : PulseTheme.textPrimary;
    final bodyColor = onDark
        ? Colors.white.withValues(alpha: 0.84)
        : PulseTheme.textSecondary;
    final description = widget.ad.description?.trim();
    final metaRow = _buildMetaRow(bodyColor);
    final ctaLabel = widget.ad.ctaLabel?.trim();

    return Column(
      crossAxisAlignment: _textCrossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (metaRow != null) ...[metaRow, const SizedBox(height: 8)],
        Text(
          widget.ad.title,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: _textAlign,
          style: TextStyle(
            color: titleColor,
            fontSize:
                titleFontSize ??
                (_isMegaHero || _isHero || _isGradient ? 21 : 16.5),
            fontWeight: FontWeight.w800,
            height: 1.13,
            letterSpacing: 0,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: descriptionMaxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: _textAlign,
            style: TextStyle(
              color: bodyColor,
              fontSize: _isMegaHero || _isHero || _isGradient ? 13.2 : 12.8,
              fontWeight: FontWeight.w500,
              height: 1.32,
            ),
          ),
        ],
        if (ctaLabel != null && ctaLabel.isNotEmpty) ...[
          SizedBox(height: ctaDense ? 9 : 11),
          _Cta(
            label: ctaLabel,
            color: _accentColor,
            onDark: onDark,
            dense: ctaDense,
          ),
        ],
      ],
    );
  }

  Widget? _buildMetaRow(Color bodyColor) {
    final sponsorLogoUrl = widget.ad.sponsorLogoUrl?.trim();
    final children = <Widget>[];

    void addSpacingIfNeeded() {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
    }

    final badgeText = _badgeText;
    if (_shouldShowBadge && badgeText != null) {
      children.add(_Badge(label: badgeText, color: _accentColor));
    }

    if (_sponsorName != null) {
      addSpacingIfNeeded();
      children.add(
        Flexible(
          child: Text(
            _sponsorName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: _textAlign,
            style: TextStyle(
              color: bodyColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_showSponsorLogo &&
        sponsorLogoUrl != null &&
        sponsorLogoUrl.isNotEmpty) {
      addSpacingIfNeeded();
      children.add(_SponsorLogo(url: sponsorLogoUrl));
    }

    if (children.isEmpty) return null;

    return Row(
      mainAxisAlignment: _metaMainAxisAlignment,
      mainAxisSize: MainAxisSize.max,
      children: children,
    );
  }

  Widget? _buildImageOverlay() {
    if (!_hasImage) return null;

    final overlay =
        _stringConfig('image_overlay', fallback: 'dark_gradient') ??
        'dark_gradient';
    return switch (overlay.toLowerCase()) {
      'none' => null,
      'dark' => DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42)),
      ),
      'light' => DecoratedBox(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.36)),
      ),
      'light_gradient' => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.24),
              Colors.white.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
      'gradient' || 'dark_gradient' => DecoratedBox(
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
      _ => null,
    };
  }

  BoxDecoration _outerDecoration() {
    return BoxDecoration(
      color: PulseTheme.surface,
      borderRadius: BorderRadius.circular(_cornerRadius),
      border: Border.all(color: PulseTheme.border.withValues(alpha: 0.72)),
      boxShadow: [
        BoxShadow(
          color: _accentColor.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
        ...PulseTheme.cardShadow,
      ],
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
          colors: [
            _accentColor.withValues(alpha: 0.16),
            Color.lerp(_accentColor, PulseTheme.surface, 0.88)!,
            PulseTheme.surface,
          ],
          stops: const [0.0, 0.58, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -10,
            bottom: -12,
            child: Icon(
              Icons.local_hospital_rounded,
              color: _accentColor.withValues(alpha: 0.08),
              size: 64,
            ),
          ),
          Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor.withValues(alpha: 0.12)),
              ),
              child: Icon(
                Icons.campaign_rounded,
                color: _accentColor,
                size: 24,
              ),
            ),
          ),
        ],
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
  final bool dense;

  const _Cta({
    required this.label,
    required this.color,
    required this.onDark,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.17) : color,
        borderRadius: BorderRadius.circular(dense ? 12 : 14),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.24) : color,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: dense ? 12 : 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _GradientMark extends StatelessWidget {
  final Color color;

  const _GradientMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.medical_services_rounded, color: color, size: 118);
  }
}

class _SponsorLogo extends StatelessWidget {
  final String url;

  const _SponsorLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140, maxHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: Colors.transparent,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

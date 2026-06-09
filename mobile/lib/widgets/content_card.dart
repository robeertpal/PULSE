import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import '../models/content_item.dart';
import '../screens/content_detail_screen.dart';
import '../screens/publication_issues_screen.dart';
import 'emc_badge.dart';
import 'favorite_button.dart';

class ContentCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String tag;
  final Color categoryColor;
  final String iconAsset;
  final double? progress;
  final String? emcPoints;
  final String? imageUrl;
  final String? dateLabel;
  final String? locationLabel;
  final String? providerLabel;
  final String? contentType;
  final String? contentTitle;
  final String? contentShortDescription;
  final String? contentBody;
  final String? contentHeroImageUrl;
  final String? contentThumbnailUrl;
  final DateTime? contentPublishedAt;
  final int? publicationId;
  final String? publicationDescription;
  final String? publicationLogoUrl;
  final String? publicationEmcCreditsText;
  final String? publicationCreditationText;
  final String? publicationIndexingText;
  final String? publicationSubscriptionUrl;
  final List<PublicationAuthor> publicationAuthors;
  final int? id; // For debug logging
  final bool isSaved;
  final ValueChanged<int>? onSaveToggle;
  final VoidCallback? onDetailClosed;
  final String? infoText;
  final double? cardWidth;
  final EdgeInsetsGeometry margin;
  final bool darkMode;

  const ContentCard({
    super.key,
    this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.categoryColor,
    required this.iconAsset,
    this.progress,
    this.emcPoints,
    this.imageUrl,
    this.dateLabel,
    this.locationLabel,
    this.providerLabel,
    this.contentType,
    this.contentTitle,
    this.contentShortDescription,
    this.contentBody,
    this.contentHeroImageUrl,
    this.contentThumbnailUrl,
    this.contentPublishedAt,
    this.publicationId,
    this.publicationDescription,
    this.publicationLogoUrl,
    this.publicationEmcCreditsText,
    this.publicationCreditationText,
    this.publicationIndexingText,
    this.publicationSubscriptionUrl,
    this.publicationAuthors = const [],
    this.isSaved = false,
    this.onSaveToggle,
    this.onDetailClosed,
    this.infoText,
    this.cardWidth = 240,
    this.margin = const EdgeInsets.only(right: 16),
    this.darkMode = false,
    this.onTap,
  });

  final VoidCallback? onTap;

  factory ContentCard.fromModel(
    ContentItem model, {
    double? progress,
    bool isSaved = false,
    ValueChanged<int>? onSaveToggle,
    VoidCallback? onDetailClosed,
    String? infoText,
    double? cardWidth = 240,
    EdgeInsetsGeometry margin = const EdgeInsets.only(right: 16),
    bool darkMode = false,
  }) {
    Color categoryColor = PulseTheme.primary;
    String iconAsset = 'assets/icons/newspaper.svg';

    if (model.contentType == 'article') {
      categoryColor = PulseTheme
          .courseContent; // In design articles are news-like but here courseContent
      iconAsset = 'assets/icons/newspaper.svg';
    } else if (model.contentType == 'news') {
      categoryColor = PulseTheme.newsContent;
      iconAsset = 'assets/icons/newspaper.svg';
    } else if (model.contentType == 'course') {
      categoryColor = PulseTheme.courseContent;
      iconAsset = 'assets/icons/graduation.svg';
    } else if (model.contentType == 'event') {
      categoryColor = PulseTheme.eventContent;
      iconAsset = 'assets/icons/events.svg';
    } else if (model.contentType == 'publication') {
      categoryColor = PulseTheme.magazineContent;
      iconAsset = 'assets/icons/books.svg';
    }

    // â”€â”€ Image Selection Priority â”€â”€
    // 1. Remote Thumbnail > 2. Remote Hero > 3. Local Thumbnail > 4. Local Hero
    String? chosenImageUrl;
    bool isRemote(String? s) =>
        s != null && (s.startsWith('http://') || s.startsWith('https://'));

    if (isRemote(model.thumbnailUrl)) {
      chosenImageUrl = model.thumbnailUrl;
    } else if (isRemote(model.heroImageUrl)) {
      chosenImageUrl = model.heroImageUrl;
    } else if (isRemote(model.publicationLogoUrl)) {
      chosenImageUrl = model.publicationLogoUrl;
    } else if (model.thumbnailUrl != null && model.thumbnailUrl!.isNotEmpty) {
      chosenImageUrl = model.thumbnailUrl;
    } else if (model.heroImageUrl != null && model.heroImageUrl!.isNotEmpty) {
      chosenImageUrl = model.heroImageUrl;
    } else if (model.publicationLogoUrl != null &&
        model.publicationLogoUrl!.isNotEmpty) {
      chosenImageUrl = model.publicationLogoUrl;
    }

    String? formatDate(DateTime? date) {
      if (date == null) return null;
      const months = [
        'ian',
        'feb',
        'mar',
        'apr',
        'mai',
        'iun',
        'iul',
        'aug',
        'sep',
        'oct',
        'nov',
        'dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    final String? eventLocation = model.venueName?.trim().isNotEmpty == true
        ? model.venueName
        : model.cityName;

    final subtitle =
        model.shortDescription ??
        model.publicationDescription ??
        model.specializationName ??
        model.categoryName ??
        model.authorName ??
        '';

    return ContentCard(
      id: model.id,
      title: model.publicationName ?? model.title,
      subtitle: subtitle,
      tag: _typeLabelForContentCard(model.contentType),
      categoryColor: categoryColor,
      iconAsset: iconAsset,
      progress: progress,
      emcPoints: _emcPointsForModel(model),
      imageUrl: chosenImageUrl,
      dateLabel: formatDate(model.startDate ?? model.publishedAt),
      locationLabel: eventLocation,
      providerLabel: model.provider,
      contentType: model.contentType,
      contentTitle: model.title,
      contentShortDescription: model.shortDescription,
      contentBody: model.body,
      contentHeroImageUrl: model.heroImageUrl,
      contentThumbnailUrl: model.thumbnailUrl,
      contentPublishedAt: model.publishedAt,
      publicationId: model.publicationId,
      publicationDescription: model.publicationDescription,
      publicationLogoUrl: model.publicationLogoUrl,
      publicationEmcCreditsText: model.publicationEmcCreditsText,
      publicationCreditationText: model.publicationCreditationText,
      publicationIndexingText: model.publicationIndexingText,
      publicationSubscriptionUrl:
          model.publicationSubscriptionUrl ?? model.contentUrl,
      publicationAuthors: model.publicationAuthors,
      isSaved: isSaved,
      onSaveToggle: onSaveToggle,
      onDetailClosed: onDetailClosed,
      infoText: infoText ?? _infoTextForContentType(model.contentType),
      cardWidth: cardWidth,
      margin: margin,
      darkMode: darkMode,
    );
  }

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Widget _buildIconPlaceholder() {
    final decoration = widget.darkMode
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.categoryColor.withValues(alpha: 0.26),
                PulseTheme.primary.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.07),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: widget.categoryColor.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
            ],
          )
        : BoxDecoration(
            color: widget.categoryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          );

    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: decoration,
        child: Center(
          child: SvgPicture.asset(
            widget.iconAsset,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
              widget.darkMode
                  ? Colors.white.withValues(alpha: 0.88)
                  : widget.categoryColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final String? rawUrl = widget.imageUrl?.trim();

    if (rawUrl == null || rawUrl.isEmpty) {
      return _buildIconPlaceholder();
    }

    // 1. Remote Image (Network)
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      debugPrint('[ContentCard ID:${widget.id}] Loading REMOTE image: $rawUrl');
      return Image.network(
        rawUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '[ContentCard ID:${widget.id}] ERROR loading remote image: $rawUrl',
          );
          return _buildIconPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildIconPlaceholder();
        },
      );
    }

    if (!rawUrl.startsWith('assets/') && !rawUrl.startsWith('images/')) {
      return _buildIconPlaceholder();
    }

    // 2. Local Asset
    String assetPath;
    if (rawUrl.startsWith('assets/')) {
      // Use exactly as is - NO double prefixing
      assetPath = rawUrl;
    } else if (rawUrl.startsWith('images/')) {
      assetPath = 'assets/$rawUrl';
    } else {
      assetPath = 'assets/images/$rawUrl';
    }

    debugPrint(
      '[ContentCard ID:${widget.id}] Loading LOCAL asset: $assetPath (Original: $rawUrl)',
    );
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[ContentCard ID:${widget.id}] ASSET NOT FOUND: $assetPath');
        return _buildIconPlaceholder();
      },
    );
  }

  Widget _buildSaveButton() {
    if (widget.id == null || widget.onSaveToggle == null) {
      return const SizedBox.shrink();
    }

    return FavoriteButton(
      isSaved: widget.isSaved,
      onTap: () => widget.onSaveToggle!(widget.id!),
    );
  }

  Widget _buildInfoButton() {
    final text = widget.infoText?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showInfoSheet(text),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: widget.darkMode
              ? const Color(0xFF090A10).withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.darkMode
                ? PulseTheme.primaryLight.withValues(alpha: 0.28)
                : widget.categoryColor.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.darkMode ? 0.28 : 0.08,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: widget.darkMode ? Colors.white : widget.categoryColor,
        ),
      ),
    );
  }

  void _showInfoSheet(String text) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF15131B).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: PulseTheme.primaryLight.withValues(alpha: 0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: PulseTheme.primary.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                    spreadRadius: -16,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: PulseTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'De ce apare acest material',
                          style: TextStyle(
                            color: PulseTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      color: PulseTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardBody() {
    final cardColor = widget.darkMode
        ? const Color(0xFF17131B).withValues(alpha: 0.78)
        : PulseTheme.surface;
    final borderColor = widget.darkMode
        ? Colors.white.withValues(alpha: 0.09)
        : PulseTheme.border.withValues(alpha: 0.6);
    final titleColor = widget.darkMode ? Colors.white : PulseTheme.textPrimary;
    final subtitleColor = widget.darkMode
        ? PulseTheme.textSecondary
        : PulseTheme.textSecondary;
    final imageHeight = widget.darkMode ? 96.0 : 120.0;
    final cardRadius = widget.darkMode ? 20.0 : 24.0;
    final contentPadding = widget.darkMode
        ? const EdgeInsets.fromLTRB(14, 12, 14, 13)
        : const EdgeInsets.all(16.0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.cardWidth,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: widget.darkMode
                  ? PulseTheme.primary.withValues(alpha: 0.16)
                  : widget.categoryColor.withValues(alpha: 0.08),
              blurRadius: widget.darkMode ? 24 : 20,
              offset: Offset(0, widget.darkMode ? 10 : 8),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.darkMode ? 0.36 : 0.03,
              ),
              blurRadius: widget.darkMode ? 24 : 10,
              offset: Offset(0, widget.darkMode ? 8 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Image Area with Gradient â”€â”€
              Container(
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.categoryColor.withValues(
                        alpha: widget.darkMode ? 0.22 : 0.12,
                      ),
                      PulseTheme.primaryLight.withValues(
                        alpha: widget.darkMode ? 0.10 : 0.04,
                      ),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // â”€â”€ Image or Placeholder Icon â”€â”€
                    Positioned.fill(child: _buildImageContent()),
                    if (widget.darkMode)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.30),
                              ],
                              stops: const [0.0, 0.48, 1.0],
                            ),
                          ),
                        ),
                      ),
                    // EMC Points badge (consistent with featured cards)
                    if (widget.emcPoints != null)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: EmcBadge(points: widget.emcPoints!),
                      ),
                    Positioned(left: 10, top: 10, child: _buildSaveButton()),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: _buildInfoButton(),
                    ),
                  ],
                ),
              ),
              // â”€â”€ Text Content â”€â”€
              Expanded(
                child: Padding(
                  padding: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: widget.darkMode
                              ? PulseTheme.primaryGradient
                              : null,
                          color: widget.darkMode
                              ? null
                              : widget.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: widget.darkMode
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                )
                              : null,
                        ),
                        child: Text(
                          widget.tag.toUpperCase(),
                          style: TextStyle(
                            color: widget.darkMode
                                ? Colors.white
                                : widget.categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        maxLines: widget.darkMode ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: widget.darkMode ? 12.5 : 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          height: 1.28,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (widget.dateLabel != null) ...[
                            _MetaPill(
                              label: widget.dateLabel!,
                              color: widget.categoryColor,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (widget.locationLabel != null)
                            Flexible(
                              fit: FlexFit.loose,
                              child: _MetaPill(
                                label: widget.locationLabel!,
                                color: widget.categoryColor,
                              ),
                            )
                          else if (widget.providerLabel != null)
                            Flexible(
                              fit: FlexFit.loose,
                              child: _MetaPill(
                                label: widget.providerLabel!,
                                color: widget.categoryColor,
                              ),
                            ),
                        ],
                      ),
                      // Optional progress bar
                      if (widget.progress != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.progress!,
                            minHeight: 4,
                            backgroundColor: widget.categoryColor.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.categoryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetailScreen() async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (widget.id == null) return;

    if (widget.contentType == 'publication' && widget.publicationId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PublicationIssuesScreen(
            publicationId: widget.publicationId!,
            contentItemId: widget.id,
            publicationName: widget.title,
            contentTitle: widget.contentTitle,
            contentShortDescription: widget.contentShortDescription,
            contentBody: widget.contentBody,
            contentHeroImageUrl: widget.contentHeroImageUrl,
            contentThumbnailUrl: widget.contentThumbnailUrl,
            contentPublishedAt: widget.contentPublishedAt,
            publicationDescription: widget.publicationDescription,
            publicationLogoUrl: widget.publicationLogoUrl,
            emcCreditsText: widget.publicationEmcCreditsText,
            creditationText: widget.publicationCreditationText,
            indexingText: widget.publicationIndexingText,
            subscriptionUrl: widget.publicationSubscriptionUrl,
            authors: widget.publicationAuthors,
          ),
        ),
      );
      widget.onDetailClosed?.call();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(
          contentItemId: widget.id!,
          initiallySaved: widget.isSaved,
        ),
      ),
    );
    widget.onDetailClosed?.call();
  }

  Widget _buildTappableCard() {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      onTap: _openDetailScreen,
      child: _buildCardBody(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTappableCard();
  }
}

String? _emcPointsForModel(ContentItem model) {
  if (!_supportsEmcBadge(model.contentType)) return null;
  final numericCredits = model.emcCredits;
  if (numericCredits != null && numericCredits > 0) {
    return '+$numericCredits';
  }

  if (model.contentType == 'publication') {
    final parsedCredits = _parsePositiveEmcCredits(
      model.publicationEmcCreditsText,
    );
    if (parsedCredits != null) return '+$parsedCredits';
  }

  return null;
}

bool _supportsEmcBadge(String type) {
  return type == 'event' || type == 'course' || type == 'publication';
}

String _typeLabelForContentCard(String type) {
  switch (type) {
    case 'publication':
      return 'Revistă';
    case 'news':
      return 'Știre';
    case 'event':
      return 'Eveniment';
    case 'course':
      return 'Curs';
    case 'article':
      return 'Articol';
    default:
      return type;
  }
}

String _infoTextForContentType(String type) {
  switch (type) {
    case 'course':
      return 'Material afi\u0219at pentru explorarea cursurilor disponibile \u0219i a con\u021binutului educa\u021bional relevant.';
    case 'event':
      return 'Material afi\u0219at pentru a descoperi evenimente medicale publicate \u00een platform\u0103.';
    case 'publication':
      return 'Revist\u0103 afi\u0219at\u0103 pentru acces rapid la publica\u021bii \u0219i edi\u021bii medicale disponibile.';
    case 'news':
    case 'article':
      return 'Material afi\u0219at pentru a descoperi nout\u0103\u021bi \u0219i articole medicale publicate.';
    default:
      return 'Material afi\u0219at pentru a explora con\u021binut medical relevant \u00een PULSE.';
  }
}

int? _parsePositiveEmcCredits(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text);
  if (match == null) return null;
  final parsed = num.tryParse(match.group(0)!.replaceAll(',', '.'));
  if (parsed == null || parsed <= 0) return null;
  return parsed.toInt();
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

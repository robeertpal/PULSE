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
    final backgroundColor = widget.darkMode
        ? Colors.white.withValues(alpha: 0.08)
        : widget.categoryColor.withValues(alpha: 0.12);

    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: widget.darkMode
              ? Border.all(color: Colors.white.withValues(alpha: 0.10))
              : null,
        ),
        child: Center(
          child: SvgPicture.asset(
            widget.iconAsset,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
              widget.categoryColor,
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

  Widget _buildCardBody() {
    final cardColor = widget.darkMode
        ? const Color(0xFF101A33).withValues(alpha: 0.70)
        : PulseTheme.surface;
    final borderColor = widget.darkMode
        ? Colors.white.withValues(alpha: 0.10)
        : PulseTheme.border.withValues(alpha: 0.6);
    final titleColor = widget.darkMode ? Colors.white : PulseTheme.textPrimary;
    final subtitleColor = widget.darkMode
        ? const Color(0xFFB9C5E4)
        : PulseTheme.textSecondary;
    final imageHeight = widget.darkMode ? 104.0 : 120.0;
    final cardRadius = widget.darkMode ? 22.0 : 24.0;
    final contentPadding = widget.darkMode
        ? const EdgeInsets.fromLTRB(14, 13, 14, 14)
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
                  ? widget.categoryColor.withValues(alpha: 0.20)
                  : widget.categoryColor.withValues(alpha: 0.08),
              blurRadius: widget.darkMode ? 26 : 20,
              offset: Offset(0, widget.darkMode ? 10 : 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.darkMode ? 0.32 : 0.03),
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
                        alpha: widget.darkMode ? 0.26 : 0.12,
                      ),
                      widget.categoryColor.withValues(
                        alpha: widget.darkMode ? 0.08 : 0.04,
                      ),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // â”€â”€ Image or Placeholder Icon â”€â”€
                    Positioned.fill(child: _buildImageContent()),
                    // EMC Points badge (consistent with featured cards)
                    if (widget.emcPoints != null)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: EmcBadge(points: widget.emcPoints!),
                      ),
                    Positioned(left: 10, top: 10, child: _buildSaveButton()),
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
                          color: widget.categoryColor.withValues(
                            alpha: widget.darkMode ? 0.18 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: widget.darkMode
                              ? Border.all(
                                  color: widget.categoryColor.withValues(
                                    alpha: 0.28,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          widget.tag.toUpperCase(),
                          style: TextStyle(
                            color: widget.categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
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

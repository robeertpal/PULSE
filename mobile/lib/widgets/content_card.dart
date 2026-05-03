import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/pulse_theme.dart';
import '../models/content_item.dart';
import 'emc_badge.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final int? id; // For debug logging
  final bool isSaved;
  final ValueChanged<int>? onSaveToggle;
  final double? cardWidth;
  final EdgeInsetsGeometry margin;

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
    this.isSaved = false,
    this.onSaveToggle,
    this.cardWidth = 240,
    this.margin = const EdgeInsets.only(right: 16),
    this.onTap,
  });

  final VoidCallback? onTap;

  factory ContentCard.fromModel(
    ContentItem model, {
    double? progress,
    bool isSaved = false,
    ValueChanged<int>? onSaveToggle,
    double? cardWidth = 240,
    EdgeInsetsGeometry margin = const EdgeInsets.only(right: 16),
  }) {
    Color categoryColor = PulseTheme.primary;
    String iconAsset = 'assets/icons/newspaper.svg';

    if (model.contentType == 'article') {
      categoryColor = PulseTheme.courseContent; // In design articles are news-like but here courseContent
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
    } else if (model.publicationLogoUrl != null && model.publicationLogoUrl!.isNotEmpty) {
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

    final String? eventLocation =
        model.venueName?.trim().isNotEmpty == true
            ? model.venueName
            : model.cityName;

    final subtitle = model.shortDescription ??
        model.publicationDescription ??
        model.specializationName ??
        model.categoryName ??
        model.authorName ??
        '';

    return ContentCard(
      id: model.id,
      title: model.publicationName ?? model.title,
      subtitle: subtitle,
      tag: model.tag ?? model.contentType,
      categoryColor: categoryColor,
      iconAsset: iconAsset,
      progress: progress,
      emcPoints: model.emcCredits != null ? '+${model.emcCredits}' : null,
      imageUrl: chosenImageUrl,
      dateLabel: formatDate(model.startDate ?? model.publishedAt),
      locationLabel: eventLocation,
      providerLabel: model.provider,
      isSaved: isSaved,
      onSaveToggle: onSaveToggle,
      cardWidth: cardWidth,
      margin: margin,
      onTap: isRemote(model.contentUrl) ? () async {
        final Uri url = Uri.parse(model.contentUrl!);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          debugPrint('Could not launch ${model.contentUrl}');
        }
      } : null,
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
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: widget.categoryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
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
          debugPrint('[ContentCard ID:${widget.id}] ERROR loading remote image: $rawUrl');
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

    debugPrint('[ContentCard ID:${widget.id}] Loading LOCAL asset: $assetPath (Original: $rawUrl)');
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSaveToggle!(widget.id!),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: PulseTheme.animFast,
          curve: PulseTheme.animCurve,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: widget.isSaved
                ? widget.categoryColor.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSaved
                  ? widget.categoryColor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Icon(
            widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: widget.isSaved ? Colors.white : PulseTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) => _tapController.reverse(),
      onTapCancel: () => _tapController.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.cardWidth,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: PulseTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PulseTheme.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: widget.categoryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Image Area with Gradient â”€â”€
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.categoryColor.withValues(alpha: 0.12),
                        widget.categoryColor.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circle
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.categoryColor.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // â”€â”€ Image or Placeholder Icon â”€â”€
                      Positioned.fill(
                        child: _buildImageContent(),
                      ),
                      // EMC Points badge (consistent with featured cards)
                      if (widget.emcPoints != null)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: EmcBadge(points: widget.emcPoints!),
                        ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _buildSaveButton(),
                      ),
                    ],
                  ),
                ),
                // â”€â”€ Text Content â”€â”€
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: PulseTheme.textPrimary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PulseTheme.textSecondary,
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
                              backgroundColor: widget.categoryColor.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(widget.categoryColor),
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
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({
    required this.label,
    required this.color,
  });

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
